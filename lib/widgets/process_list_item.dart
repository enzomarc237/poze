import 'dart:io';

import 'package:flutter/cupertino.dart'; // Import CupertinoIcons
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:poze/services/process_service.dart';
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
                  style: MacosTheme.of(
                    context,
                  ).typography.title2.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.memory,
                      size: 14,
                      color: MacosColors.systemGrayColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PID: ${process.pid}',
                      style: MacosTheme.of(context).typography.caption1,
                    ),
                  ],
                ),
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
    return FutureBuilder<String?>(
      future: ProcessService.getAppIconPath(process.name),
      builder: (context, snapshot) {
        final iconPath = snapshot.data;
        if (iconPath != null && iconPath.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(iconPath),
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.apps, color: Colors.white, size: 20);
              },
            ),
          );
        }
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _getProcessColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.apps, color: Colors.white, size: 20),
        );
      },
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

  bool get _isProtectedProcess {
    final protectedNames = [
      'Finder',
      'Activity Monitor',
      'WindowServer',
      'loginwindow',
      'SystemUIServer',
      'Dock',
      'launchd',
      'coreaudiod',
      'UserEventAgent',
      'ControlCenter',
      'NotificationCenter',
      'Spotlight',
      'poze', // Your own app, adjust if needed
    ];
    final lowerName = process.name.toLowerCase();
    // Also protect current app by checking executable name
    final selfName = Platform.resolvedExecutable.split('/').last.toLowerCase();
    return protectedNames.any((n) => lowerName == n.toLowerCase()) ||
        lowerName == selfName;
  }

  Widget _buildActionButton(BuildContext context) {
    if (_isProtectedProcess) {
      return const SizedBox.shrink(); // Hide button for protected processes
    }
    final bool isDarkMode =
        MacosTheme.of(context).brightness == Brightness.dark;
    final Color playColor = MacosColors.systemGreenColor;
    final Color pauseColor = MacosColors.systemOrangeColor;
    // Use a contrasting icon color based on theme brightness
    final Color iconColor = isDarkMode ? MacosColors.black : MacosColors.white;

    return PushButton(
      controlSize: ControlSize.small,
      onPressed: process.isPaused ? onResume : onPause,
      color:
          process.isPaused ? playColor : pauseColor, // Change background color
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ), // Adjust padding if needed
      child:
          process.isPaused
              ? Icon(
                CupertinoIcons.play_arrow_solid,
                size: 14,
                color: iconColor,
              ) // Use Cupertino icon
              : Icon(
                CupertinoIcons.pause_solid,
                size: 14,
                color: iconColor,
              ), // Use Cupertino icon
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
