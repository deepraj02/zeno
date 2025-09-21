import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:zeno/src/config/zeno_config.dart';

/// Manages the building process for applications
///
/// Handles executing build commands for both initial and incremental builds,
/// capturing build results, and logging build failures.
class ZenoBuildRunner {
  /// Creates a new ZenoBuildRunner instance.
  ///
  /// [config] provides the configuration settings for building.
  /// [logger] is used for logging build events and errors.
  ZenoBuildRunner({
    required this.config,
    required this.logger,
  });

  /// Configuration settings for the Zeno system.
  final ZenoConfig config;

  /// Logger used for outputting build status and errors.
  final Logger logger;

  /// Performs the initial build of the application.
  ///
  /// Executes the build command to create the main application binary.
  ///
  /// Returns a [BuildResult] indicating success or failure, with error details
  /// in case of failure.
  Future<BuildResult> buildInitial() async {
    try {
      logger.info('building application...');

      final cmd = config.build.cmd;
      final result = await _runBuildCommand(cmd, 'Initial');

      if (result.exitCode == 0) {
        return BuildResult.success();
      } else {
        final error = result.stderr.toString();
        await _writeBuildLog('Initial build failed: $error');
        return BuildResult.failure(error);
      }
    } catch (e) {
      final error = 'Initial build command failed: $e';
      await _writeBuildLog(error);
      return BuildResult.failure(error);
    }
  }

  /// Builds a new version of the application for hot reloading.
  ///
  /// Rebuilds to create a new binary with a different name,
  /// allowing for hot swapping with the currently running version.
  ///
  /// Returns a [BuildResult] indicating success or failure, with error details
  /// in case of failure.
  Future<BuildResult> rebuild() async {
    try {
      logger.info('building application ...');

      // Modify command to build to _new location
      final cmd = _getNewBuildCommand();
      final result = await _runBuildCommand(cmd, 'New version');

      if (result.exitCode == 0) {
        return BuildResult.success();
      } else {
        final error = result.stderr.toString();
        await _writeBuildLog('New version build failed: $error');
        return BuildResult.failure(error);
      }
    } catch (e) {
      final error = 'New version build command failed: $e';
      await _writeBuildLog(error);
      return BuildResult.failure(error);
    }
  }

  /// Creates a modified build command for building a new version.
  ///
  /// Replaces the output binary path  with a path for the new version binary.
  ///
  /// Returns the modified build command string.
  String _getNewBuildCommand() {
    final originalCmd = config.build.cmd;
    final originalBin = config.build.bin;
    final newBin = _getNewBinPath();

    // Replace the output path in the command
    final newCmd = originalCmd.replaceAll(originalBin, newBin);

    return newCmd;
  }

  /// Determines the file path for the new binary version.
  ///
  /// For Windows executables (.exe), adds '_new' before the extension.
  /// For other platforms, appends '_new' to the binary name.
  ///
  /// Returns the path for the new binary.
  String _getNewBinPath() {
    final binPath = config.build.bin;
    if (binPath.endsWith('.exe')) {
      return binPath.replaceAll('.exe', '_new.exe');
    }
    return '${binPath}_new';
  }

  /// Executes the build command as a process.
  ///
  /// [cmd] The build command to execute.
  /// [buildType] A description of the build type for logging purposes.
  ///
  /// Returns the [ProcessResult] from executing the command.
  Future<ProcessResult> _runBuildCommand(String cmd, String buildType) async {
    final parts = cmd.trim().split(' ');
    final command = parts.first;
    final args = parts.skip(1).toList();

    return Process.run(
      command,
      args,
      workingDirectory: config.root,
    );
  }

  /// Writes build errors to a log file.
  ///
  /// [error] The error message to log.
  ///
  /// The log entry is appended to the configured log file.
  Future<void> _writeBuildLog(String error) async {
    try {
      final logFile = File(config.buildLogPath);
      await logFile.parent.create(recursive: true);
      await logFile.writeAsString(
        '${DateTime.now().toIso8601String()}: $error\n',
        mode: FileMode.append,
      );
    } catch (e) {
      logger.warn('⚠️ Failed to write build log: $e');
    }
  }
}

/// Represents the result of a build operation.
///
/// Contains information about whether the build succeeded and any error
/// messages in case of failure.
class BuildResult {
  /// Creates a successful build result with no error.
  BuildResult.success()
      : success = true,
        error = null;

  /// Creates a failed build result with the provided error message.
  ///
  /// [error] The error message describing why the build failed.
  BuildResult.failure(this.error) : success = false;

  /// Whether the build operation was successful.
  final bool success;

  /// Error message if the build failed, null if successful.
  final String? error;
}
