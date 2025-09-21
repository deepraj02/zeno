import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:zeno/src/config/zeno_config.dart';
import 'package:zeno/src/engine/build_runner.dart';
import 'package:zeno/src/engine/file_watcher.dart';
import 'package:zeno/src/engine/process_manager.dart';

/// Core engine for the Zeno hot reload system.
///
/// Responsible for coordinating file watching, building, and process management
/// to enable hot reloading functionality for applications.
class ZenoEngine {
  /// Creates a new ZenoEngine instance.
  ///
  /// [config] provides configuration settings for the engine.
  /// [logger] is used for logging events and errors.
  ZenoEngine({
    required this.config,
    required this.logger,
  }) {
    _fileWatcher = ZenoFileWatcher(config: config, logger: logger);
    _processManager = ZenoProcessManager(config: config, logger: logger);
    _buildRunner = ZenoBuildRunner(config: config, logger: logger);
  }

  /// Configuration settings for the Zeno engine.
  final ZenoConfig config;

  /// Logger used for outputting status messages and errors.
  final Logger logger;

  /// Watches file system for changes to trigger reloads.
  late final ZenoFileWatcher _fileWatcher;

  /// Manages the application process lifecycle.
  late final ZenoProcessManager _processManager;

  /// Handles building the application code.
  late final ZenoBuildRunner _buildRunner;

  /// Indicates if the engine is currently running.
  bool _isRunning = false;

  /// Indicates if a reload operation is in progress.
  bool _isReloading = false;

  /// Subscription to file system events.
  StreamSubscription<FileSystemEvent>? _watcherSubscription;

  /// Timer used to debounce file change events.
  Timer? _debounceTimer;

  /// Set of files that have changed but not yet triggered a reload.
  final Set<String> _pendingChanges = <String>{};

  /// Starts the Zeno engine.
  ///
  /// This initializes the temporary directory, performs the initial build,
  /// starts the application, and begins watching for file changes.
  /// If the engine is already running, this method does nothing.
  ///
  /// Returns a Future that completes when the engine has started.
  Future<void> start() async {
    if (_isRunning) return;

    logger.info('🚀 Welcome to Zeno Land! Starting your Application');

    _isRunning = true;

    // Ensure tmp directory exists
    await _ensureTmpDirectory();

    // Initial build and run
    await _initialBuildAndRun();

    // Start watching files
    await _startWatching();

    logger.info('Watching for file changes...');
  }

  /// Stops the Zeno engine.
  ///
  /// Cancels all active timers and subscriptions, stops file watching,
  /// terminates the application process, and cleans up temporary files
  /// if configured to do so.
  /// If the engine is not running, this method does nothing.
  ///
  /// Returns a Future that completes when the engine has fully stopped.
  Future<void> stop() async {
    if (!_isRunning) return;

    logger.info('Stopping Zeno...');
    _isRunning = false;

    // Cancel debounce timer
    _debounceTimer?.cancel();

    // Stop watching
    await _watcherSubscription?.cancel();
    await _fileWatcher.stop();

    // Stop process manager
    await _processManager.stop();

    if (config.misc.cleanOnExit) {
      await _cleanupTmpDirectory();
    }

    logger.info('👋 Goodbye!');
  }

  /// Performs the initial build and launches the application.
  ///
  /// Executes pre-commands, builds the initial binary, executes post-commands,
  /// and starts the application process.
  Future<void> _initialBuildAndRun() async {
    try {
      // Run pre-commands
      await _runPreCommands();

      // Initial build to main binary
      final buildResult = await _buildRunner.buildInitial();
      if (!buildResult.success) {
        logger.err('Initial build failed: ${buildResult.error}');
        return;
      }

      logger.success('Initial build successful');

      // Run post-commands
      await _runPostCommands();

      // Start the application
      await _processManager.startInitial();
    } catch (e) {
      logger.err('Error during initial build/run: $e');
    }
  }

  /// Starts watching the file system for changes.
  ///
  /// Sets up a subscription to file system events that triggers hot reloads.
  Future<void> _startWatching() async {
    final stream = await _fileWatcher.watch(config.root);
    _watcherSubscription = stream.listen(_onFileChanged);
  }

  /// Handles file system change events.
  ///
  /// Records the changed file and schedules a hot reload.
  /// This prevents multiple rapid rebuilds when several files change at once.
  ///
  /// [event] The file system event that triggered this callback.
  Future<void> _onFileChanged(FileSystemEvent event) async {
    if (!_isRunning || _isReloading) return;

    final relativePath = _getRelativePath(event.path);
    logger.detail('File changed: $relativePath');

    // Add to pending changes
    _pendingChanges.add(relativePath);

    // Cancel existing timer
    _debounceTimer?.cancel();

    // Start new debounce timer
    _debounceTimer = Timer(config.buildDelay, () async {
      if (_pendingChanges.isNotEmpty && !_isReloading) {
        final changes = _pendingChanges.toList();
        _pendingChanges.clear();

        if (config.screen.clearOnRebuild) {
          _clearScreen();
        }

        logger.info('🔄 Hot reloading due to changes in ${changes.join(', ')}');
        await _gracefulHotReload();
      }
    });
  }

  /// Performs a hot reload of the application.
  ///
  /// This builds a new version of the application, runs pre and post commands,
  /// and gracefully restarts the process. If a reload is already in progress,
  /// this operation is skipped.
  Future<void> _gracefulHotReload() async {
    if (_isReloading) {
      logger.detail('Reload already in progress, skipping...');
      return;
    }

    _isReloading = true;
    final startTime = DateTime.now();

    try {
      // Run pre-commands
      await _runPreCommands();

      // Build new version to temporary location
      final buildResult = await _buildRunner.rebuild();
      if (!buildResult.success) {
        logger.err('Build failed: ${buildResult.error}');
        if (config.build.stopOnError) return;
      } else {
        logger.success('Build successful');

        // Run post-commands
        await _runPostCommands();

        // Perform graceful restart
        final success = await _processManager.gracefulRestart();

        if (success) {
          final duration = DateTime.now().difference(startTime);
          logger.success(
            'Hot reload completed in ${duration.inMilliseconds}ms!',
          );
        } else {
          logger.err('Failed to restart application');
        }
      }
    } catch (e) {
      logger.err('Error during hot reload: $e');
    } finally {
      _isReloading = false;
    }
  }

  Future<void> _runPreCommands() async {
    for (final cmd in config.build.preCmd) {
      logger.info('Running pre-command: $cmd');
      await _runCommand(cmd);
    }
  }

  Future<void> _runPostCommands() async {
    for (final cmd in config.build.postCmd) {
      logger.info('Running post-command: $cmd');
      await _runCommand(cmd);
    }
  }

  Future<void> _runCommand(String command) async {
    final parts = command.split(' ');
    final result = await Process.run(
      parts.first,
      parts.skip(1).toList(),
      workingDirectory: config.root,
    );

    if (result.exitCode != 0) {
      logger
        ..err('Command failed: $command')
        ..err('Error: ${result.stderr}');
    }
  }

  Future<void> _ensureTmpDirectory() async {
    final tmpDir = Directory(config.tmpPath);
    if (!tmpDir.existsSync()) {
      await tmpDir.create(recursive: true);
    }
  }

  Future<void> _cleanupTmpDirectory() async {
    final tmpDir = Directory(config.tmpPath);
    if (tmpDir.existsSync()) {
      await tmpDir.delete(recursive: true);
    }
  }

  /// Converts an absolute file path to a path relative to the project root.
  ///
  /// [absolutePath] The absolute path to convert.
  /// Returns the relative path as a string.
  String _getRelativePath(String absolutePath) {
    final root = Directory(config.root).absolute.path;
    if (absolutePath.startsWith(root)) {
      return absolutePath.substring(root.length + 1);
    }
    return absolutePath;
  }

  void _clearScreen() {
    if (config.screen.keepScroll) {
      stdout.write('\x1B[2J'); // Clear screen, keep scroll
    } else {
      stdout.write('\x1B[2J\x1B[H'); // Clear screen and reset cursor
    }
  }
}
