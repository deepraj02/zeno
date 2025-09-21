import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

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
    const output = 'Init Running';
    _logger.info(output);
    return ExitCode.success.code;
  }
}
