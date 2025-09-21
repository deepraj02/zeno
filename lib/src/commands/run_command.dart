import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

class RunCommand extends Command<int> {
  RunCommand({required Logger logger}) : _logger = logger {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Configuration file path',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose logging',
        negatable: false,
      );
  }

  @override
  String get description => 'Start hot reloading for your Dart application';

  @override
  String get name => 'run';

  final Logger _logger;

  @override
  Future<int> run() async {
    const output = 'Zeno Running';
    _logger.info(output);
    return ExitCode.success.code;
  }
}
