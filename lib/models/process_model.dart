class ProcessModel {
  final String pid;
  final String name;
  final String command;
  final double cpuUsage;
  final bool isPaused;
  final String? iconPath; // Path to the app icon (optional, can be null)
  final int? memoryKb;
  final int? threads;
  final List<String>? openFiles;

  ProcessModel({
    required this.pid,
    required this.name,
    required this.command,
    required this.cpuUsage,
    this.isPaused = false,
    this.iconPath,
    this.memoryKb,
    this.threads,
    this.openFiles,
  });

  factory ProcessModel.fromAppleScript({
    required String pid,
    required String name,
    required double cpuUsage,
  }) {
    return ProcessModel(
      pid: pid,
      name: name,
      command: name,
      cpuUsage: cpuUsage,
      iconPath: null,
    );
  }

  /// Creates a [ProcessModel] from an osquery JSON row.
  factory ProcessModel.fromOsquery(Map<String, dynamic> m) {
    final pid = m['pid']?.toString() ?? '';
    final name = m['name']?.toString() ?? '';
    final command = m['path']?.toString() ?? '';
    final cpuUsage = (m['cpu_time'] is num)
        ? (m['cpu_time'] as num).toDouble()
        : 0.0;
    return ProcessModel(
      pid: pid,
      name: name,
      command: command,
      cpuUsage: cpuUsage,
    );
  }

  @override
  String toString() {
    return 'ProcessModel(pid: $pid, name: $name, cpuUsage: $cpuUsage, isPaused: $isPaused, iconPath: $iconPath)';
  }

  ProcessModel copyWith({
    String? pid,
    String? name,
    String? command,
    double? cpuUsage,
    bool? isPaused,
    String? iconPath,
    int? memoryKb,
    int? threads,
    List<String>? openFiles,
  }) {
    return ProcessModel(
      pid: pid ?? this.pid,
      name: name ?? this.name,
      command: command ?? this.command,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      isPaused: isPaused ?? this.isPaused,
      iconPath: iconPath ?? this.iconPath,
      memoryKb: memoryKb ?? this.memoryKb,
      threads: threads ?? this.threads,
      openFiles: openFiles ?? this.openFiles,
    );
  }
}
