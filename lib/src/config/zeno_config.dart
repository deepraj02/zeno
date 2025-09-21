import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:zeno/src/config/config.dart';

/// Exception thrown when configuration operations fail.
class ConfigException implements Exception {
  const ConfigException(this.message);

  final String message;

  @override
  String toString() => 'ConfigException: $message';
}

/// Main configuration class for Zeno hot reload utility.
class ZenoConfig {
  const ZenoConfig({
    required this.root,
    required this.tmpDir,
    required this.build,
    required this.log,
    required this.proxy,
    required this.screen,
    required this.misc,
  });

  /// Creates a [ZenoConfig] from a YAML map.
  factory ZenoConfig.fromYaml(Map<String, dynamic> yaml) {
    return ZenoConfig(
      root: yaml['root'] as String? ?? '.',
      tmpDir: yaml['tmp_dir'] as String? ?? 'tmp',
      build: BuildConfig.fromYaml(
        _extractMap(yaml['build']) ?? <String, dynamic>{},
      ),
      log: LogConfig.fromYaml(
        _extractMap(yaml['log']) ?? <String, dynamic>{},
      ),
      proxy: ProxyConfig.fromYaml(
        _extractMap(yaml['proxy']) ?? <String, dynamic>{},
      ),
      screen: ScreenConfig.fromYaml(
        _extractMap(yaml['screen']) ?? <String, dynamic>{},
      ),
      misc: MiscConfig.fromYaml(
        _extractMap(yaml['misc']) ?? <String, dynamic>{},
      ),
    );
  }

  /// Loads configuration from file.
  static Future<ZenoConfig> load([String? configPath]) async {
    configPath ??= _findConfigFile();

    if (configPath == null) {
      throw const ConfigException(
        'No configuration file found. Run "zeno init" to create one.',
      );
    }

    try {
      final content = await File(configPath).readAsString();
      final yamlDoc = loadYaml(content);
      final yamlMap = Map<String, dynamic>.from(yamlDoc as YamlMap);

      return ZenoConfig.fromYaml(yamlMap);
    } catch (e) {
      throw ConfigException(
        'Failed to load configuration from $configPath: $e',
      );
    }
  }

  /// Project root directory.
  final String root;

  /// Temporary directory name.
  final String tmpDir;

  /// Build configuration.
  final BuildConfig build;

  /// Logging configuration.
  final LogConfig log;

  /// Proxy configuration.
  final ProxyConfig proxy;

  /// Screen configuration.
  final ScreenConfig screen;

  /// Miscellaneous configuration.
  final MiscConfig misc;

  /// Absolute path to the binary file.
  String get binPath =>
      path.isAbsolute(build.bin) ? build.bin : path.join(root, build.bin);

  /// Absolute path to the temporary directory.
  String get tmpPath => path.join(root, tmpDir);

  /// Absolute path to the build log file.
  String get buildLogPath => path.join(tmpPath, build.log);

  /// Build delay as a Duration.
  Duration get buildDelay => Duration(milliseconds: build.delay);

  /// Kill delay as a Duration.
  Duration get killDelay => Duration(milliseconds: build.killDelay);

  /// Converts configuration to YAML map.
  Map<String, dynamic> toYaml() {
    return <String, dynamic>{
      'root': root,
      'tmp_dir': tmpDir,
      'build': build.toYaml(),
      'log': log.toYaml(),
      'proxy': proxy.toYaml(),
      'screen': screen.toYaml(),
      'misc': misc.toYaml(),
    };
  }

  /// Finds configuration file in current directory.
  static String? _findConfigFile() {
    const configFiles = ['zeno.yml', '.zeno.yml'];

    for (final name in configFiles) {
      if (File(name).existsSync()) {
        return name;
      }
    }

    return null;
  }

  /// Safely extracts a map from YAML value.
  static Map<String, dynamic>? _extractMap(dynamic value) {
    return switch (value) {
      null => null,
      final Map<String, dynamic> map => map,
      final YamlMap yamlMap => Map<String, dynamic>.from(yamlMap),
      _ => null,
    };
  }
}
