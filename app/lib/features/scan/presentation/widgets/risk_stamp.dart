import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/widgets/motion.dart';
import 'package:scamshield/core/widgets/stitched.dart';
import 'package:scamshield/features/scan/domain/entities/scan_result.dart';
import 'package:scamshield/features/scan/presentation/widgets/risk_style.dart';

/// The verdict lands like a rubber stamp, with a thump you can feel.
class RiskStamp extends HookWidget {
  const RiskStamp({super.key, required this.risk, this.size = 190});

  final RiskLevel risk;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final style = RiskStyle.of(risk);
    final reduce = context.reduceMotion;
    final controller = useAnimationController(duration: Duration(milliseconds: reduce ? 1 : 650));
    final curve = useMemoized(() => CurvedAnimation(parent: controller, curve: Curves.easeInCubic), [controller]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        controller.forward(from: 0).whenComplete(() {
          if (risk == RiskLevel.high) {
            HapticFeedback.heavyImpact();
          } else {
            HapticFeedback.mediumImpact();
          }
        });
      });
      return null;
    }, [risk]);

    final t = useAnimation(curve);

    return Semantics(
      liveRegion: true,
      label: risk.title(l),
      excludeSemantics: true,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: -0.14 * t,
          child: Transform.scale(
            scale: 2.3 - 1.3 * t,
            child: SizedBox.square(
              dimension: size,
              child: CustomPaint(
                painter: _StampPainter(style.color),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(size * 0.17),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(style.icon, size: size * 0.26, color: style.color),
                        const SizedBox(height: 4),
                        FittedBox(
                          child: Text(
                            risk.title(l),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: style.color, fontWeight: FontWeight.w800, height: 1.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  _StampPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(center, radius - 4, Paint()..color = color.withValues(alpha: 0.06));
    canvas.drawCircle(
      center,
      radius - 4,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    StitchPainter(color: color, circle: true, inset: 16, strokeWidth: 2.4).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_StampPainter oldDelegate) => oldDelegate.color != color;
}