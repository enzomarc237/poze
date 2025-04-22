import 'dart:async';
import 'dart:isolate';

import '../models/process_model.dart';
import '../models/system_stats.dart';
import 'process_service.dart';
import 'system_service.dart';

/// Message types for communication between isolate and main thread
enum MessageType { fetchData, processData, systemData, error }

/// Message structure for isolate communication
class IsolateMessage {
  final MessageType type;
  final dynamic data;

  IsolateMessage(this.type, this.data);

  Map<String, dynamic> toMap() {
    return {'type': type.index, 'data': data};
  }

  static IsolateMessage fromMap(Map<String, dynamic> map) {
    return IsolateMessage(MessageType.values[map['type']], map['data']);
  }
}

/// Service that handles background data fetching using isolates
class BackgroundFetchService {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  final _processDataController =
      StreamController<List<ProcessModel>>.broadcast();
  final _systemDataController = StreamController<SystemStats>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  bool _isInitialized = false;

  /// Stream of process data updates
  Stream<List<ProcessModel>> get processDataStream =>
      _processDataController.stream;

  /// Stream of system stats updates
  Stream<SystemStats> get systemDataStream => _systemDataController.stream;

  /// Stream of error messages
  Stream<String> get errorStream => _errorController.stream;

  /// Initialize the background fetch service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntryPoint, _receivePort!.sendPort);

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        _isInitialized = true;
      } else if (message is Map<String, dynamic>) {
        _handleMessage(IsolateMessage.fromMap(message));
      }
    });
  }

  /// Handle messages from the isolate
  void _handleMessage(IsolateMessage message) {
    switch (message.type) {
      case MessageType.processData:
        final List<dynamic> rawProcesses = message.data;
        final processes =
            rawProcesses.map((p) {
              return ProcessModel(
                pid: p['pid'],
                name: p['name'],
                command: p['command'],
                cpuUsage: p['cpuUsage'],
                isPaused: p['isPaused'] ?? false,
                iconPath: p['iconPath'],
              );
            }).toList();
        _processDataController.add(processes);
        break;
      case MessageType.systemData:
        final Map<String, dynamic> rawStats = message.data;
        final systemStats = SystemStats(
          systemVersion: rawStats['systemVersion'],
          totalProcesses: rawStats['totalProcesses'],
          totalCpuUsage: rawStats['totalCpuUsage'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(rawStats['timestamp']),
        );
        _systemDataController.add(systemStats);
        break;
      case MessageType.error:
        _errorController.add(message.data);
        break;
      default:
        break;
    }
  }

  /// Request data fetch from the isolate
  void fetchData() {
    if (!_isInitialized || _sendPort == null) return;
    _sendPort!.send(IsolateMessage(MessageType.fetchData, null).toMap());
  }

  /// Dispose the service and clean up resources
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _processDataController.close();
    _systemDataController.close();
    _errorController.close();
    _isInitialized = false;
  }

  /// Entry point for the isolate
  static void _isolateEntryPoint(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    final processService = ProcessService();
    final systemService = SystemService();

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        final isolateMessage = IsolateMessage.fromMap(message);

        if (isolateMessage.type == MessageType.fetchData) {
          try {
            // Fetch process data
            final processes = await processService.getProcessesWithCpuUsage();
            final processList =
                processes.map((p) => {
                    'pid': p.pid,
                    'name': p.name,
                    'command': p.command,
                    'cpuUsage': p.cpuUsage,
                    'isPaused': p.isPaused,
                    'iconPath': p.iconPath,
                  }).toList();

            mainSendPort.send(
              IsolateMessage(MessageType.processData, processList).toMap(),
            );

            // Fetch system stats
            final systemStats = await systemService.getSystemStats();
            mainSendPort.send(
              IsolateMessage(MessageType.systemData, {
                'systemVersion': systemStats.systemVersion,
                'totalProcesses': systemStats.totalProcesses,
                'totalCpuUsage': systemStats.totalCpuUsage,
                'timestamp': systemStats.timestamp.millisecondsSinceEpoch,
              }).toMap(),
            );
          } catch (e) {
            mainSendPort.send(
              IsolateMessage(MessageType.error, e.toString()).toMap(),
            );
          }
        }
      }
    });
  }
} // Add the missing closing brace for the class here
