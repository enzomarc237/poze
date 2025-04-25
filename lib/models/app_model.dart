/// Model representing an installed application, parsed from osquery.
class AppModel {
  final String name;
  final String bundleIdentifier;
  final String path;
  final String version;

  AppModel({
    required this.name,
    required this.bundleIdentifier,
    required this.path,
    required this.version,
  });

  /// Creates an [AppModel] from an osquery JSON row.
  factory AppModel.fromOsquery(Map<String, dynamic> m) {
    return AppModel(
      name: m['name']?.toString() ?? '',
      bundleIdentifier: m['bundle_identifier']?.toString() ?? '',
      path: m['path']?.toString() ?? '',
      version: m['version']?.toString() ?? '',
    );
  }

  AppModel copyWith({
    String? name,
    String? bundleIdentifier,
    String? path,
    String? version,
  }) {
    return AppModel(
      name: name ?? this.name,
      bundleIdentifier: bundleIdentifier ?? this.bundleIdentifier,
      path: path ?? this.path,
      version: version ?? this.version,
    );
  }

  @override
  String toString() {
    return 'AppModel(name: $name, bundleId: $bundleIdentifier, path: $path, version: $version)';
  }
}
