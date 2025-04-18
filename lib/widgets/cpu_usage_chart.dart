import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class CpuUsageChart extends StatelessWidget {
  final double cpuUsage;
  final double width;
  final double height;

  const CpuUsageChart({
    super.key,
    required this.cpuUsage,
    this.width = 200,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MacosTheme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CPU: ${cpuUsage.toStringAsFixed(1)}%',
            style: MacosTheme.of(
              context,
            ).typography.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              size: Size(width - 32, height - 50),
              painter: _CpuUsagePainter(
                cpuUsage: cpuUsage,
                color: _getCpuColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCpuColor() {
    if (cpuUsage > 80.0) {
      return MacosColors.systemRedColor;
    } else if (cpuUsage > 50.0) {
      return MacosColors.systemOrangeColor;
    } else {
      return MacosColors.systemGreenColor;
    }
  }
}

class _CpuUsagePainter extends CustomPainter {
  final double cpuUsage;
  final Color color;

  _CpuUsagePainter({required this.cpuUsage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width;
    final barHeight = size.height;

    // Dessiner l'arrière-plan
    final bgPaint =
        Paint()
          ..color = MacosColors.systemGrayColor.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    final bgRect = Rect.fromLTWH(0, 0, barWidth, barHeight);
    canvas.drawRect(bgRect, bgPaint);

    // Dessiner la barre d'utilisation CPU
    final fillPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final fillWidth = (cpuUsage / 100.0) * barWidth;
    final fillRect = Rect.fromLTWH(0, 0, fillWidth, barHeight);
    canvas.drawRect(fillRect, fillPaint);

    // Dessiner les lignes de grille
    final gridPaint =
        Paint()
          ..color = MacosColors.systemGrayColor.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    for (int i = 1; i < 5; i++) {
      final x = (barWidth / 5) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, barHeight), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CpuUsagePainter oldDelegate) {
    return oldDelegate.cpuUsage != cpuUsage || oldDelegate.color != color;
  }
}
