import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path_lib;
import 'package:watcher/watcher.dart';
import 'package:zeno/src/config/zeno_config.dart';

/// A file system watcher that monitors changes in the project directory.
///
/// Provides intelligent file filtering based on configuration and emits
/// events for files that should trigger rebuilds. Supports both native
/// file watching and polling modes for cross-platform compatibility.
class ZenoFileWatcher {
  /// Creates a new file watcher with the given configuration and logger.
  ZenoFileWatcher({
    required this.config,
    required this.logger,
  });

  /// The Zeno configuration used for file watching rules.
  final ZenoConfig config;

  /// Logger instance for outputting file watcher events.
  final Logger logger;
  final List<StreamSubscription<WatchEvent>> _subscriptions = [];

  Future<Stream<FileSystemEvent>> watch(String rootPath) async {
    final controller = StreamController<FileSystemEvent>.broadcast();

    await _watchDirectory(rootPath, controller);

    return controller.stream;
  }

  Future<void> _watchDirectory(
    String dirPath,
    StreamController<FileSystemEvent> controller,
  ) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;

    if (_isExcludedDirectory(dirPath)) {
      return;
    }

    final watcher = config.build.poll
        ? PollingDirectoryWatcher(dirPath)
        : DirectoryWatcher(dirPath);

    final subscription = watcher.events.listen((event) {
      if (_shouldWatchFile(event.path)) {
        controller.add(FileSystemEvent(event.path, event.type));
      }
    });

    _subscriptions.add(subscription);

    await for (final entity in dir.list()) {
      if (entity is Directory) {
        await _watchDirectory(entity.path, controller);
      }
    }
  }

  bool _shouldWatchFile(String filePath) {
    final fileName = path_lib.basename(filePath);
    final extension = path_lib.extension(filePath);
    final relativePath = path_lib.relative(filePath, from: config.root);

    if (config.build.includeExt.isNotEmpty) {
      if (!config.build.includeExt.contains(extension.replaceFirst('.', ''))) {
        return false;
      }
    }

    if (config.build.excludeFile.contains(fileName)) {
      return false;
    }

    if (config.build.includeFile.isNotEmpty) {
      if (!config.build.includeFile.contains(fileName)) {
        return false;
      }
    }

    for (final pattern in config.build.excludeRegex) {
      final regex = RegExp(pattern);
      if (regex.hasMatch(relativePath)) {
        return false;
      }
    }

    return true;
  }

  bool _isExcludedDirectory(String dirPath) {
    final relativePath = path_lib.relative(dirPath, from: config.root);

    if (relativePath == config.tmpDir) return true;

    for (final excludeDir in config.build.excludeDir) {
      if (relativePath.startsWith(excludeDir)) return true;
    }

    if (config.build.includeDir.isNotEmpty) {
      var isIncluded = false;
      for (final includeDir in config.build.includeDir) {
        if (relativePath.startsWith(includeDir)) {
          isIncluded = true;
          break;
        }
      }
      if (!isIncluded) return true;
    }

    return false;
  }

  /// Stops the file watcher and cleans up all subscriptions.
  ///
  /// Returns a [Future] that completes when all watchers have been stopped.
  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}

class FileSystemEvent {
  FileSystemEvent(this.path, this.type);
  final String path;
  final ChangeType type;
}
