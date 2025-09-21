class MiscConfig {
  const MiscConfig({required this.cleanOnExit});

  /// Creates a [MiscConfig] from a YAML map.
  factory MiscConfig.fromYaml(Map<String, dynamic> yaml) {
    return MiscConfig(
      cleanOnExit: yaml['clean_on_exit'] as bool? ?? false,
    );
  }

  /// Whether to clean temporary files on exit.
  final bool cleanOnExit;

  /// Converts miscellaneous configuration to YAML map.
  Map<String, dynamic> toYaml() {
    return <String, dynamic>{
      'clean_on_exit': cleanOnExit,
    };
  }
}
