import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/theme/app_colors.dart';
import 'package:scamshield/core/widgets/motion.dart';
import 'package:scamshield/core/widgets/stitched.dart';

/// The main action, stitched like a kantha quilt so it is the first thing the eye finds.
class CheckHeroCard extends StatelessWidget {
  const CheckHeroCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(28);

    Widget icon = Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(color: AppColors.paper, shape: BoxShape.circle),
      child: const Icon(Icons.mark_email_unread_rounded, size: 42, color: AppColors.neel),
    );
    if (!context.reduceMotion) {
      icon = icon
          .animate()
          .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 800.ms, curve: Curves.elasticOut);
    }

    return Semantics(
      button: true,
      label: '${l.checkMessage}. ${l.checkMessageHint}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.neel,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Stitched(
            radius: 28,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(height: 16),
                  Text(l.checkMessage, style: text.displaySmall?.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(l.checkMessageHint, style: text.bodyLarge?.copyWith(color: const Color(0xFFC9D0EC))),
                  const SizedBox(height: 20),
                  Container(
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(18)),
                    child: Text(l.startCheck, style: text.labelLarge?.copyWith(color: AppColors.neel)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}