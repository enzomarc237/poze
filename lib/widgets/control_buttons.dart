import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class ProcessControlButtons extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const ProcessControlButtons({
    super.key,
    required this.isPaused,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPaused)
          PushButton(
            controlSize: ControlSize.small,
            onPressed: onResume,
            secondary: true,
            child: const Row(
              children: [
                Icon(Icons.play_arrow, size: 16),
                SizedBox(width: 4),
                Text('Reprendre'),
              ],
            ),
          )
        else
          PushButton(
            controlSize: ControlSize.small,
            onPressed: onPause,
            color: MacosColors.systemOrangeColor,
            child: const Row(
              children: [
                Icon(Icons.pause, size: 16),
                SizedBox(width: 4),
                Text('Mettre en pause'),
              ],
            ),
          ),
      ],
    );
  }
}

class KillButton extends StatelessWidget {
  final VoidCallback onKill;

  const KillButton({super.key, required this.onKill});

  @override
  Widget build(BuildContext context) {
    return PushButton(
      controlSize: ControlSize.small,
      onPressed: onKill,
      color: MacosColors.systemRedColor,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stop, size: 16),
          SizedBox(width: 4),
          Text('Arrêter'),
        ],
      ),
    );
  }
}
