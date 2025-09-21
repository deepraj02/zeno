class LogConfig {
  const LogConfig({
    required this.addTime,
    required this.mainOnly,
    required this.silent,
  });

  /// Creates a [LogConfig] from a YAML map.
  factory LogConfig.fromYaml(Map<String, dynamic> yaml) {
    return LogConfig(
      addTime: yaml['add_time'] as bool? ?? false,
      mainOnly: yaml['main_only'] as bool? ?? false,
      silent: yaml['silent'] as bool? ?? false,
    );
  }

  /// Whether to add timestamps to log messages.
  final bool addTime;

  /// Whether to log only main process output.
  final bool mainOnly;

  /// Whether to suppress log output.
  final bool silent;

  /// Converts log configuration to YAML map.
  Map<String, dynamic> toYaml() {
    return <String, dynamic>{
      'add_time': addTime,
      'main_only': mainOnly,
      'silent': silent,
    };
  }
}
