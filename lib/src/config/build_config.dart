class BuildConfig {
  const BuildConfig({
    required this.cmd,
    required this.bin,
    required this.log,
    required this.includeExt,
    required this.excludeDir,
    required this.includeDir,
    required this.excludeFile,
    required this.includeFile,
    required this.excludeRegex,
    required this.preCmd,
    required this.postCmd,
    required this.args,
    required this.delay,
    required this.killDelay,
    required this.stopOnError,
    required this.excludeUnchanged,
    required this.followSymlink,
    required this.poll,
    required this.pollInterval,
  });

  /// Creates a [BuildConfig] from a YAML map.
  factory BuildConfig.fromYaml(Map<String, dynamic> yaml) {
    return BuildConfig(
      cmd: yaml['cmd'] as String? ?? _defaultBuildCommand,
      bin: yaml['bin'] as String? ?? _defaultBinaryPath,
      log: yaml['log'] as String? ?? _defaultLogFile,
      includeExt: _parseStringList(yaml['include_ext']) ?? _defaultExtensions,
      excludeDir: _parseStringList(yaml['exclude_dir']) ?? <String>[],
      includeDir: _parseStringList(yaml['include_dir']) ?? <String>[],
      excludeFile: _parseStringList(yaml['exclude_file']) ?? <String>[],
      includeFile: _parseStringList(yaml['include_file']) ?? <String>[],
      excludeRegex: _parseStringList(yaml['exclude_regex']) ?? <String>[],
      preCmd: _parseStringList(yaml['pre_cmd']) ?? <String>[],
      postCmd: _parseStringList(yaml['post_cmd']) ?? <String>[],
      args: _parseStringList(yaml['args']) ?? <String>[],
      delay: yaml['delay'] as int? ?? _defaultDelay,
      killDelay: yaml['kill_delay'] as int? ?? _defaultKillDelay,
      stopOnError: yaml['stop_on_error'] as bool? ?? false,
      excludeUnchanged: yaml['exclude_unchanged'] as bool? ?? true,
      followSymlink: yaml['follow_symlink'] as bool? ?? false,
      poll: yaml['poll'] as bool? ?? false,
      pollInterval: yaml['poll_interval'] as int? ?? _defaultPollInterval,
    );
  }

  // Default values as constants
  static const _defaultBuildCommand =
      'dart compile exe lib/main.dart -o ./tmp/main_new.exe';
  static const _defaultBinaryPath = './tmp/main.exe';
  static const _defaultLogFile = 'build-errors.log';
  static const _defaultExtensions = ['dart'];
  static const _defaultDelay = 1500;
  static const _defaultKillDelay = 1500;
  static const _defaultPollInterval = 500;

  /// Build command to execute.
  final String cmd;

  /// Path to the binary file.
  final String bin;

  /// Build log file name.
  final String log;

  /// File extensions to include in watching.
  final List<String> includeExt;

  /// Directories to exclude from watching.
  final List<String> excludeDir;

  /// Directories to include in watching.
  final List<String> includeDir;

  /// Files to exclude from watching.
  final List<String> excludeFile;

  /// Files to include in watching.
  final List<String> includeFile;

  /// Regex patterns to exclude.
  final List<String> excludeRegex;

  /// Commands to run before build.
  final List<String> preCmd;

  /// Commands to run after build.
  final List<String> postCmd;

  /// Arguments to pass to the application.
  final List<String> args;

  /// Delay before rebuilding (milliseconds).
  final int delay;

  /// Delay before killing process (milliseconds).
  final int killDelay;

  /// Whether to stop on build errors.
  final bool stopOnError;

  /// Whether to exclude unchanged files.
  final bool excludeUnchanged;

  /// Whether to follow symbolic links.
  final bool followSymlink;

  /// Whether to use polling for file watching.
  final bool poll;

  /// Polling interval (milliseconds).
  final int pollInterval;

  /// Converts build configuration to YAML map.
  Map<String, dynamic> toYaml() {
    return <String, dynamic>{
      'cmd': cmd,
      'bin': bin,
      'log': log,
      'include_ext': includeExt,
      'exclude_dir': excludeDir,
      'include_dir': includeDir,
      'exclude_file': excludeFile,
      'include_file': includeFile,
      'exclude_regex': excludeRegex,
      'pre_cmd': preCmd,
      'post_cmd': postCmd,
      'args': args,
      'delay': delay,
      'kill_delay': killDelay,
      'stop_on_error': stopOnError,
      'exclude_unchanged': excludeUnchanged,
      'follow_symlink': followSymlink,
      'poll': poll,
      'poll_interval': pollInterval,
    };
  }

  /// Safely parses a list of strings from YAML value.
  static List<String>? _parseStringList(dynamic value) {
    return switch (value) {
      null => null,
      final List<String> list => list,
      final List<dynamic> list => list.map((e) => e.toString()).toList(),
      _ => null,
    };
  }
}
