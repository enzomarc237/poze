class ProcessModel {
  final String pid;
  final String name;
  final String command;
  final double cpuUsage;
  final bool isPaused;
  final String? iconPath; // Path to the app icon

  ProcessModel({
    required this.pid,
    required this.name,
    required this.command,
    required this.cpuUsage,
    this.isPaused = false,
    this.iconPath,
  });

  // Cette méthode n'est plus utilisée car nous n'utilisons plus ps aux
  // mais conservée pour référence ou utilisation future
  factory ProcessModel.fromPsOutput(String line) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 11) {
      throw Exception('Format de sortie ps invalide: $line');
    }

    final pid = parts[1];
    final cpu = double.tryParse(parts[2]) ?? 0.0;

    // Le nom de la commande est généralement le dernier élément
    final commandFull = parts.sublist(10).join(' ');
    final commandParts = commandFull.split('/');
    final name =
        commandParts.isNotEmpty
            ? commandParts.last.split(' ').first
            : commandFull;

    return ProcessModel(
      pid: pid,
      name: name,
      command: commandFull,
      cpuUsage: cpu,
    );
  }

  // Nouvelle factory pour créer une instance à partir des données AppleScript
  factory ProcessModel.fromAppleScript({
    required String pid,
    required String name,
    required double cpuUsage,
  }) {
    return ProcessModel(
      pid: pid,
      name: name,
      command: name, // Pour les applications GUI, on utilise simplement le nom
      cpuUsage: cpuUsage,
      iconPath: null, // Initially set to null, will be fetched later
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
  }) {
    return ProcessModel(
      pid: pid ?? this.pid,
      name: name ?? this.name,
      command: command ?? this.command,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      isPaused: isPaused ?? this.isPaused,
      iconPath: iconPath ?? this.iconPath,
    );
  }
}
