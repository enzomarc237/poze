class SystemStats {
  final double totalCpuUsage;
  final int totalProcesses;
  final String systemVersion;
  final DateTime timestamp;

  SystemStats({
    required this.totalCpuUsage,
    required this.totalProcesses,
    required this.systemVersion,
    required this.timestamp,
  });

  factory SystemStats.initial() {
    return SystemStats(
      totalCpuUsage: 0.0,
      totalProcesses: 0,
      systemVersion: 'macOS',
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'SystemStats(totalCpuUsage: $totalCpuUsage%, totalProcesses: $totalProcesses, systemVersion: $systemVersion, timestamp: $timestamp)';
  }
}
