import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// A full-screen detail view for a process, replacing alert dialogs.
class ProcessDetailView extends StatelessWidget {
  final Map<String, dynamic> details;

  const ProcessDetailView({Key? key, required this.details}) : super(key: key);

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: MacosTheme.of(context)
                .typography
                .title3
                .copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: MacosTheme.of(context).typography.body,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(title: Text('Détails du processus')),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Text(
                    "${details['name']} (PID: ${details['pid']})",
                    style: MacosTheme.of(context).typography.title1,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      context, 'Chemin', details['path']?.toString() ?? 'N/A'),
                  _buildInfoRow(
                      context,
                      'CPU Time',
                      details['cpu_time']?.toString() ?? 'N/A'),
                  _buildInfoRow(
                      context,
                      'Memory %',
                      details['memory_percent'] != null
                          ? "${details['memory_percent']}%"
                          : "N/A"),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      context,
                      'Threads',
                      details['thread_count']?.toString() ?? 'N/A'),
                  _buildInfoRow(
                      context,
                      'Resident MB',
                      details['mem_rss'] != null
                          ? "${((details['mem_rss'] as num) / 1024).toStringAsFixed(1)} MB"
                          : "N/A"),
                  const SizedBox(height: 24),
                  Text(
                    'Fichiers ouverts',
                    style: MacosTheme.of(context)
                        .typography
                        .title2
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (details['open_files'] is List && (details['open_files'] as List).isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: MacosScrollbar(
                        child: ListView.builder(
                          itemCount: (details['open_files'] as List).length,
                          itemBuilder: (ctx, i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              (details['open_files'][i]).toString(),
                              style: MacosTheme.of(context)
                                  .typography
                                  .body,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Text('Aucun fichier ouvert'),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
