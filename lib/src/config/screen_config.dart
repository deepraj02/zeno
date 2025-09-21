class ScreenConfig {
  const ScreenConfig({
    required this.clearOnRebuild,
    required this.keepScroll,
  });

  /// Creates a [ScreenConfig] from a YAML map.
  factory ScreenConfig.fromYaml(Map<String, dynamic> yaml) {
    return ScreenConfig(
      clearOnRebuild: yaml['clear_on_rebuild'] as bool? ?? false,
      keepScroll: yaml['keep_scroll'] as bool? ?? true,
    );
  }

  /// Whether to clear screen on rebuild.
  final bool clearOnRebuild;

  /// Whether to keep scroll position.
  final bool keepScroll;

  /// Converts screen configuration to YAML map.
  Map<String, dynamic> toYaml() {
    return <String, dynamic>{
      'clear_on_rebuild': clearOnRebuild,
      'keep_scroll': keepScroll,
    };
  }
}
