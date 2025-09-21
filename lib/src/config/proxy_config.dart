class ProxyConfig {
  const ProxyConfig({
    required this.enabled,
    required this.proxyPort,
    required this.appPort,
  });

  /// Creates a [ProxyConfig] from a YAML map.
  factory ProxyConfig.fromYaml(Map<String, dynamic> yaml) {
    return ProxyConfig(
      enabled: yaml['enabled'] as bool? ?? false,
      proxyPort: yaml['proxy_port'] as int? ?? _defaultProxyPort,
      appPort: yaml['app_port'] as int? ?? _defaultAppPort,
    );
  }

  static const _defaultProxyPort = 8090;
  static const _defaultAppPort = 8080;

  /// Whether proxy is enabled.
  final bool enabled;

  /// Port for the proxy server.
  final int proxyPort;

  /// Port for the application server.
  final int appPort;

  /// Converts proxy configuration to YAML map.
  Map<String, dynamic> toYaml() {
    return <String, dynamic>{
      'enabled': enabled,
      'proxy_port': proxyPort,
      'app_port': appPort,
    };
  }
}
