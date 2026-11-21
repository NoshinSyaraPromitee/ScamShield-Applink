import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scamshield/core/theme/app_colors.dart';

enum TileTone { neutral, safe, danger }

/// A large tappable row: 64px icon, title, short hint.
class BigTile extends StatelessWidget {
  const BigTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.tone = TileTone.neutral,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final TileTone tone;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (accent, soft) = switch (tone) {
      TileTone.neutral => (AppColors.neel, AppColors.neelSoft),
      TileTone.safe => (AppColors.safe, AppColors.safeSoft),
      TileTone.danger => (AppColors.danger, AppColors.dangerSoft),
    };
    final borderColor = (tone == TileTone.neutral && !selected) ? AppColors.line : accent;
    final radius = BorderRadius.circular(24);

    return Semantics(
      button: true,
      selected: selected,
      label: subtitle == null ? title : '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: selected ? soft : AppColors.paper,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 104),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: borderColor, width: 2)),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(20)),
                  child: Icon(icon, size: 36, color: accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: text.titleMedium?.copyWith(color: tone == TileTone.danger ? AppColors.dangerDeep : AppColors.ink),
                      ),
                      if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: text.bodySmall)],
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                  size: 32,
                  color: selected ? accent : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}