import 'package:flutter/material.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/theme/app_colors.dart';
import 'package:scamshield/core/widgets/motion.dart';
import 'package:scamshield/features/scan/domain/entities/scan_result.dart';

/// Safe / careful / danger bar with a marker that slides to the result.
class RiskMeter extends StatelessWidget {
  const RiskMeter({super.key, required this.risk, required this.score});

  final RiskLevel risk;
  final double score;

  double get _position => switch (risk) {
        RiskLevel.none => 0.1,
        RiskLevel.low => 0.2,
        RiskLevel.medium => 0.5,
        RiskLevel.high => (0.72 + 0.28 * score).clamp(0.72, 1.0),
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 40,
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 13,
                    bottom: 13,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const Row(
                        children: [
                          Expanded(child: ColoredBox(color: AppColors.safe)),
                          Expanded(child: ColoredBox(color: AppColors.caution)),
                          Expanded(child: ColoredBox(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _position),
                    duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Positioned(
                      left: value * (width - 36),
                      top: 2,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: Text(l.meterSafe, style: small)),
            Expanded(child: Text(l.meterCaution, textAlign: TextAlign.center, style: small)),
            Expanded(child: Text(l.meterDanger, textAlign: TextAlign.end, style: small)),
          ],
        ),
      ],
    );
  }
}