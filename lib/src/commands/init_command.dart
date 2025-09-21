import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:zeno/src/utils/path_utils.dart';

/// Command to initialize a new Zeno configuration file.
class InitCommand extends Command<int> {
  /// Creates a new [InitCommand] with the provided [logger].
  InitCommand({required Logger logger}) : _logger = logger;

  static const _configFileName = 'zeno.yml';

  final Logger _logger;

  @override
  String get description => 'Initialize a new Zeno configuration file';

  @override
  String get name => 'init';

  @override
  Future<int> run() async {
    final configFile = File(_configFileName);

    if (await PathUtils.shouldSkipInitialization(configFile, _logger)) {
      return ExitCode.success.code;
    }

    try {
      await PathUtils.createConfigurationFile(
        configFile,
        _logger,
        _configFileName,
      );
      _displaySuccessMessage();
      return ExitCode.success.code;
    } catch (error) {
      _logger.err('Failed to create configuration file: $error');
      return ExitCode.software.code;
    }
  }

  void _displaySuccessMessage() {
    _logger
      ..info('Edit the configuration file to specify:')
      ..info('  • build.cmd: Your build command')
      ..info('  • build.bin: Your output binary path')
      ..info('')
      ..info('Run "zeno" to start hot reloading');
  }
}
