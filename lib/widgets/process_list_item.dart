import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import '../models/process_model.dart';

class ProcessListItem extends StatelessWidget {
  final ProcessModel process;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const ProcessListItem({
    super.key,
    required this.process,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: MacosTheme.of(context).dividerColor.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildLeadingIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  process.name,
                  style: MacosTheme.of(context).typography.title2.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.memory, size: 14, color: MacosColors.systemGrayColor),
                  const SizedBox(width: 4),
                  Text('PID: ${process.pid}', style: MacosTheme.of(context).typography.caption1),
                ]),
                Text(
                  process.command.length > 50
                      ? '${process.command.substring(0, 50)}...'
                      : process.command,
                  style: MacosTheme.of(context).typography.subheadline,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildCpuIndicator(context),
          const SizedBox(width: 16),
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _getProcessColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.app_registration, color: Colors.white, size: 20),
    );
  }

  Widget _buildCpuIndicator(BuildContext context) {
    final cpuText = '${process.cpuUsage.toStringAsFixed(1)}%';

    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            cpuText,
            style: MacosTheme.of(context).typography.body.copyWith(
              fontWeight: FontWeight.bold,
              color: _getCpuTextColor(context),
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: process.cpuUsage / 100,
            backgroundColor: MacosColors.systemGrayColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_getCpuColor()),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return PushButton(
      controlSize: ControlSize.small,
      onPressed: process.isPaused ? onResume : onPause,
      child:
          process.isPaused
              ? const Icon(Icons.play_arrow, size: 16)
              : const Icon(Icons.pause, size: 16),
    );
  }

  Color _getProcessColor() {
    if (process.isPaused) {
      return MacosColors.systemGrayColor;
    }

    if (process.cpuUsage > 50.0) {
      return MacosColors.systemRedColor;
    } else if (process.cpuUsage > 20.0) {
      return MacosColors.systemOrangeColor;
    } else {
      return MacosColors.systemBlueColor;
    }
  }

  Color _getCpuColor() {
    if (process.cpuUsage > 50.0) {
      return MacosColors.systemRedColor;
    } else if (process.cpuUsage > 20.0) {
      return MacosColors.systemOrangeColor;
    } else {
      return MacosColors.systemGreenColor;
    }
  }

  Color _getCpuTextColor(BuildContext context) {
    if (process.cpuUsage > 50.0) {
      return MacosColors.systemRedColor;
    } else if (process.cpuUsage > 20.0) {
      return MacosColors.systemOrangeColor;
    } else {
      return MacosTheme.of(context).brightness == Brightness.dark
          ? MacosColors.white
          : MacosColors.black;
    }
  }
}
