import 'dart:io';

// Remove unused import
import 'package:flutter/cupertino.dart'; // Import CupertinoIcons
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:poze/services/process_service.dart';
import '../models/process_model.dart';

class ProcessListItem extends StatelessWidget {
  final ProcessModel process;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onKill;
  final VoidCallback? onInfo;
  final bool selected;
  final ValueChanged<bool?>? onSelectedChanged; // Added callback

  const ProcessListItem({
    super.key,
    required this.process,
    required this.onPause,
    required this.onResume,
    required this.onKill,
    this.onInfo,
    this.selected = false,
    this.onSelectedChanged, // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color:
            selected
                ? MacosTheme.of(context).primaryColor.withValues(
                  alpha: 0.2,
                ) // Use theme primary color for selection
                : MacosTheme.of(context).canvasColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: MacosTheme.of(context).dividerColor.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildSelectionCheckbox(context),
          const SizedBox(width: 8),
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
          if (!_isProtectedProcess) _buildPauseResumeButton(),
          const SizedBox(width: 8),
          _buildActionDropdown(context),
        ],
      ),
    );
  }

  Widget _buildPauseResumeButton() {
    return MacosIconButton(
      icon: Icon(
        process.isPaused
            ? CupertinoIcons.play_arrow_solid
            : CupertinoIcons.pause_solid,
        color:
            process.isPaused
                ? MacosColors.systemGreenColor
                : MacosColors.systemOrangeColor,
        size: 16,
      ),
      onPressed: process.isPaused ? onResume : onPause,
    );
  }

  Widget _buildSelectionCheckbox(BuildContext context) {
    return MacosCheckbox(
      value: selected,
      onChanged: onSelectedChanged, // Use the callback
      activeColor: MacosColors.controlAccentColor,
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      // materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                // Return a container similar to the fallback on error
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

  Widget _buildActionDropdown(BuildContext context) {
    // Define actions for the pulldown menu
    final List<MacosPulldownMenuEntry> menuItems = [
      if (!_isProtectedProcess)
        MacosPulldownMenuItem(
          title: const Row(
            children: [
              Icon(CupertinoIcons.delete, size: 16),
              SizedBox(width: 8),
              Text('Kill'),
            ],
          ),
          onTap: onKill,
        ),
      MacosPulldownMenuItem(
        title: const Row(
          children: [
            Icon(CupertinoIcons.info, size: 16),
            SizedBox(width: 8),
            Text('Info'),
          ],
        ),
        onTap:
            onInfo ??
            () {
              showMacosAlertDialog(
                context: context,
                builder:
                    (_) => MacosAlertDialog(
                      appIcon:
                          _buildLeadingIconForDialog(), // Use helper for icon
                      title: Text('Process Info: ${process.name}'),
                      message: Text(
                        'PID: ${process.pid}\nCPU: ${process.cpuUsage.toStringAsFixed(1)}%\nCommand: ${process.command}',
                        textAlign: TextAlign.center,
                        style: MacosTheme.of(context).typography.body,
                      ),
                      primaryButton: PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ),
              );
            },
      ),
    ];

    // Use MacosPulldownButton for actions
    return MacosPulldownButton(
      icon: CupertinoIcons.ellipsis_vertical,
      items: menuItems,
    );
  }

  // Helper to build the icon for the dialog, similar to list item but smaller
  Widget _buildLeadingIconForDialog() {
    return FutureBuilder<String?>(
      future: ProcessService.getAppIconPath(process.name),
      builder: (context, snapshot) {
        final iconPath = snapshot.data;
        if (iconPath != null && iconPath.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(iconPath),
              width: 32, // Slightly smaller for dialog
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getProcessColor(),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.apps, color: Colors.white, size: 18),
                );
              },
            ),
          );
        }
        // Fallback icon
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _getProcessColor(),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.apps, color: Colors.white, size: 18),
        );
      },
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

// _ActionMenuItem class is no longer needed as we use MacosPulldownMenuItem directly
