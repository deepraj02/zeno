import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:zeno/src/config/zeno_config.dart';
import 'package:zeno/src/engine/zeno_engine.dart';

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
    final configPath = argResults?['config'] as String?;
    final verbose = argResults?['verbose'] as bool? ?? false;

    if (verbose) {
      _logger.level = Level.verbose;
    }

    try {
      final config = await ZenoConfig.load(configPath);
      final engine = ZenoEngine(config: config, logger: _logger);

      late StreamSubscription<ProcessSignal> sigintSub;
      late StreamSubscription<ProcessSignal> sigtermSub;

      final completer = Completer<int>();

      sigintSub = ProcessSignal.sigint.watch().listen((_) async {
        _logger.info('Received SIGINT, shutting down...');
        await engine.stop();
        await sigintSub.cancel();
        await sigtermSub.cancel();
        completer.complete(ExitCode.success.code);
      });

      sigtermSub = ProcessSignal.sigterm.watch().listen((_) async {
        _logger.info('\n⏹️ Received SIGTERM, shutting down...');
        await engine.stop();
        await sigintSub.cancel();
        await sigtermSub.cancel();
        completer.complete(ExitCode.success.code);
      });

      await engine.start();

      return await completer.future;
    } catch (e) {
      _logger.err('Failed to start Zeno: $e');
      return ExitCode.software.code;
    }
  }
}
