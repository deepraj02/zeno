import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:zeno/src/config/zeno_config.dart';
import 'package:zeno/src/utils/path_utils.dart';

/// Manages the lifecycle of application processes for hot reloading.
///
/// Provides functionality to start, stop, and gracefully restart application

class ZenoProcessManager {
  /// Creates a new process manager with the given configuration and logger.
  ZenoProcessManager({
    required this.config,
    required this.logger,
  });

  /// The Zeno configuration used for process management.
  final ZenoConfig config;

  /// Logger instance for outputting process management events.
  final Logger logger;

  Process? _currentProcess;
  bool _isRunning = false;

  /// Whether a process is currently running.
  bool get isRunning => _isRunning;

  /// Starts the initial application process.
  ///
  /// If a process is already running, it will be stopped first.
  /// Returns a [Future] that completes when the process has started.
  Future<void> startInitial() async {
    if (_isRunning) {
      await stop();
    }
    await _startProcess();
  }

  /// Performs a graceful restart of the application.
  ///
  /// This method implements zero-downtime deployment by:
  /// 1. Checking for the new binary version
  /// 2. Gracefully stopping the current process
  /// 3. Swapping the binary files
  /// 4. Starting the new version
  ///
  /// Returns `true` if the restart was successful, `false` otherwise.
  Future<bool> gracefulRestart() async {
    if (!_isRunning || _currentProcess == null) {
      logger.err('No current process to restart');
      return false;
    }

    final newBinaryPath = _getNewBinaryPath();

    if (!await _validateNewBinary(newBinaryPath)) {
      return false;
    }

    try {
      logger.info('Performing graceful restart...');

      await _stopCurrentProcess();

      await _swapBinaries(newBinaryPath);
      await _startProcess();

      logger.success('Graceful restart completed successfully');
      return true;
    } catch (error) {
      logger.err('Failed to perform graceful restart: $error');
      await _attemptRecovery();
      return false;
    }
  }

  /// Stops the currently running application process.
  ///
  /// Attempts graceful shutdown first, then force kills if necessary.
  /// Returns a [Future] that completes when the process has stopped.
  Future<void> stop() async {
    if (!_isRunning || _currentProcess == null) {
      return;
    }

    logger.info('Stopping application...');

    try {
      await _terminateProcess(_currentProcess!);
      logger.detail('Process stopped successfully');
    } catch (error) {
      logger.err('Error stopping process: $error');
    } finally {
      _cleanup();
    }
  }

  /// Starts a new application process with the configured binary and arguments.
  Future<void> _startProcess() async {
    final binaryFile = File(config.binPath);

    if (!binaryFile.existsSync()) {
      throw ProcessException('Binary not found', config.binPath);
    }

    try {
      logger.info('Starting application...');

      _currentProcess = await Process.start(
        config.binPath,
        config.build.args,
        workingDirectory: config.root,
      );

      _isRunning = true;
      _setupProcessStreams();
      _setupExitHandler();
    } catch (error) {
      _isRunning = false;
      throw ProcessException('Failed to start application', error.toString());
    }
  }

  /// Sets up stdout and stderr forwarding for the process.
  void _setupProcessStreams() {
    if (_currentProcess == null) return;

    _currentProcess!.stdout.listen(
      (data) => stdout.add(data),
      onError: (error) => logger.warn('Stdout error: $error'),
    );

    _currentProcess!.stderr.listen(
      (data) => stderr.add(data),
      onError: (error) => logger.warn('Stderr error: $error'),
    );
  }

  /// Sets up exit code monitoring for the process.
  void _setupExitHandler() {
    if (_currentProcess == null) return;

    unawaited(
      _currentProcess!.exitCode.then((exitCode) {
        if (_currentProcess != null) {
          _isRunning = false;
          _logProcessExit(exitCode);
        }
      }),
    );
  }

  /// Logs process exit with appropriate message based on exit code.
  void _logProcessExit(int exitCode) {
    if (_isNormalExit(exitCode)) {
      logger.detail('Process exited normally');
    } else {
      logger.warn('Process exited with code: $exitCode');
    }
  }

  /// Determines if the exit code indicates normal termination.
  bool _isNormalExit(int exitCode) {
    return exitCode == 0 || exitCode == -15 || exitCode == -9;
  }

  /// Validates that the new binary exists and is ready for deployment.
  Future<bool> _validateNewBinary(String newBinaryPath) async {
    if (!await PathUtils.fileExists(newBinaryPath)) {
      logger.err('New version binary not found: $newBinaryPath');
      await _debugNewBinaryLocation(newBinaryPath);
      return false;
    }

    return true;
  }

  /// Provides debug information about the new binary location.
  Future<void> _debugNewBinaryLocation(String expectedPath) async {
    logger
      ..detail('Looking for file at: ${File(expectedPath).absolute.path}')
      ..detail('File exists: ${File(expectedPath).existsSync()}');

    await _listTemporaryDirectoryContents();
  }

  /// Lists contents of temporary directory for debugging purposes.
  Future<void> _listTemporaryDirectoryContents() async {
    final tmpDirectory = Directory(config.tmpPath);

    if (!await PathUtils.directoryExists(config.tmpPath)) {
      logger.detail('Temporary directory does not exist: ${config.tmpPath}');
      return;
    }

    logger.detail('Files in temporary directory:');
    try {
      await for (final entity in tmpDirectory.list()) {
        logger.detail('  - ${entity.path}');
      }
    } catch (error) {
      logger.warn('Failed to list temporary directory: $error');
    }
  }

  /// Gracefully stops the current process.
  Future<void> _stopCurrentProcess() async {
    final process = _currentProcess;
    if (process == null) return;

    logger.info('Gracefully stopping current version...');

    _currentProcess = null;
    _isRunning = false;

    await _terminateProcess(process);
    logger.detail('Previous version stopped gracefully');
  }

  /// Terminates a process with graceful shutdown timeout.
  Future<void> _terminateProcess(Process process) async {
    final completer = Completer<void>();
    var hasCompleted = false;

    final timeoutDuration = Duration(milliseconds: config.build.killDelay);
    final timer = Timer(timeoutDuration, () {
      if (!hasCompleted) {
        logger.warn('Graceful shutdown timeout, force killing...');
        process.kill(ProcessSignal.sigkill);
      }
    });

    process.kill();

    await process.exitCode.then((_) {
      if (!hasCompleted) {
        hasCompleted = true;
        timer.cancel();
        completer.complete();
      }
    });

    await completer.future;
  }

  /// Swaps the current binary with the new version.
  Future<void> _swapBinaries(String newBinaryPath) async {
    try {
      await _createBackup();
      await _replaceWithNewBinary(newBinaryPath);
      await _cleanupNewBinary(newBinaryPath);
      _scheduleBackupCleanup();

      logger.detail('Binary updated successfully');
    } catch (error) {
      logger.warn('Failed to replace binary: $error');
    }
  }

  /// Creates a backup of the current binary.
  Future<void> _createBackup() async {
    if (!await PathUtils.fileExists(config.binPath)) return;

    final backupPath = '${config.binPath}.backup';
    await PathUtils.copyFile(config.binPath, backupPath);
  }

  Future<void> _replaceWithNewBinary(String newBinaryPath) async {
    await PathUtils.copyFile(newBinaryPath, config.binPath);
  }

  Future<void> _cleanupNewBinary(String newBinaryPath) async {
    await PathUtils.deleteFile(newBinaryPath);
  }

  /// Schedules cleanup of the backup file after a delay.
  void _scheduleBackupCleanup() {
    const cleanupDelay = Duration(seconds: 30);
    Timer(cleanupDelay, () async {
      try {
        final backupFile = File('${config.binPath}.backup');
        if (backupFile.existsSync()) {
          await backupFile.delete();
        }
      } catch (_) {}
    });
  }

  Future<void> _attemptRecovery() async {
    if (_isRunning) return;

    logger.info('Attempting to restart with current version...');
    try {
      await _startProcess();
    } catch (error) {
      logger.err('Recovery failed: $error');
    }
  }

  /// Generates the path for the new binary based on current binary path.
  String _getNewBinaryPath() {
    return PathUtils.addSuffixToFileName(config.build.bin, '_new');
  }

  /// Cleans up internal state.
  void _cleanup() {
    _isRunning = false;
    _currentProcess = null;
  }
}

/// Exception thrown when process operations fail.
class ProcessException implements Exception {
  /// Creates a process exception with a message and optional details.
  const ProcessException(this.message, [this.details]);

  /// The main error message.
  final String message;

  /// Optional additional details about the error.
  final String? details;

  @override
  String toString() {
    return details != null
        ? 'ProcessException: $message - $details'
        : 'ProcessException: $message';
  }
}
