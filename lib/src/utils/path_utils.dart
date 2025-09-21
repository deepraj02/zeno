import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path_lib;

class PathUtils {
  static String makeRelative(String absolutePath, String basePath) {
    return path_lib.relative(absolutePath, from: basePath);
  }

  static String resolvePath(String path, String basePath) {
    if (path_lib.isAbsolute(path)) {
      return path;
    }
    return path_lib.join(basePath, path);
  }

  static Future<bool> directoryExists(String path) async {
    return Directory(path).existsSync();
  }

  static Future<bool> fileExists(String path) async {
    return File(path).existsSync();
  }

  static Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  static Future<void> copyFile(
    String sourcePath,
    String destinationPath,
  ) async {
    await File(sourcePath).copy(destinationPath);
  }

  static Future<void> deleteFile(String path) async {
    await File(path).delete();
  }

  static String addSuffixToFileName(String filePath, String suffix) {
    final dir = path_lib.dirname(filePath);
    final fileName = path_lib.basenameWithoutExtension(filePath);
    final extension = path_lib.extension(filePath);
    return path_lib.join(dir, '$fileName$suffix$extension');
  }

  static Future<bool> shouldSkipInitialization(
    File configFile,
    Logger logger,
  ) async {
    if (!configFile.existsSync()) {
      return false;
    }

    logger.warn('Configuration file already exists: ${configFile.path}');
    final shouldOverwrite = logger.confirm('Do you want to overwrite it?');

    if (!shouldOverwrite) {
      logger.info('Keeping existing configuration');
      return true;
    }

    return false;
  }

  static Future<void> createConfigurationFile(
    File configFile,
    Logger logger,
    String fileName,
  ) async {
    final content = _generateDefaultConfiguration();
    await configFile.writeAsString(content);
    logger.success('Created $fileName');
  }

  static String _generateDefaultConfiguration() {
    return r'''
# Zeno Configuration File
# Hot reload utility for Dart applications
# Documentation: https://github.com/deepraj02/zeno

# Project settings
root: .
tmp_dir: tmp

# Build configuration
build:
  # Build command - outputs to *_new for graceful restart
  cmd: "dart compile exe lib/main.dart -o ./tmp/main.exe"
  
  # Main binary path (the currently running version)
  bin: ./tmp/main.exe
  
  # Application arguments
  args: []
  
  # Build error log file
  log: build-errors.log
  
  # File watching configuration
  include_ext:
    - dart
  
  exclude_dir:
    - build
    - .dart_tool
    - tmp
    - test
  
  exclude_regex:
    - "_test\\.dart$"
  
  # Build lifecycle hooks
  pre_cmd: []
  post_cmd: []
  
  # Timing configuration (milliseconds)
  delay: 1500
  kill_delay: 1500
  
  # Build behavior
  stop_on_error: false
  exclude_unchanged: true
  follow_symlink: false
  
  # File watching method
  poll: false
  poll_interval: 500

# Logging settings
log:
  add_time: false
  main_only: false
  silent: false

# Development proxy (for live reload in web apps)
proxy:
  enabled: false
  proxy_port: 8090
  app_port: 8080

# Terminal display
screen:
  clear_on_rebuild: false
  keep_scroll: true

# Cleanup settings
misc:
  clean_on_exit: true

# Quick Start:
# 1. Update build.cmd with your application's entry point
# 2. Update build.bin with your desired binary location
# 4. Run 'zeno' to start development with hot reload
''';
  }
}
