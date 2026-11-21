import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scamshield/core/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';

enum ButtonTone { primary, danger, safe }

/// Full-width, 68px-tall button. While [busy], the label shimmers instead of a spinner.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = ButtonTone.primary,
    this.outlined = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonTone tone;
  final bool outlined;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      ButtonTone.primary => AppColors.neel,
      ButtonTone.danger => AppColors.danger,
      ButtonTone.safe => AppColors.safe,
    };
    final foreground = outlined ? color : Colors.white;

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 28, color: foreground), const SizedBox(width: 12)],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ),
      ],
    );
    if (busy) {
      content = Shimmer.fromColors(baseColor: foreground, highlightColor: foreground.withValues(alpha: 0.35), child: content);
    }

    void tap() {
      if (busy) return;
      HapticFeedback.selectionClick();
      onPressed?.call();
    }

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
    const padding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        child: outlined
            ? OutlinedButton(
                onPressed: onPressed == null ? null : tap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  backgroundColor: AppColors.paper,
                  side: BorderSide(color: color, width: 2),
                  minimumSize: const Size.fromHeight(68),
                  padding: padding,
                  shape: shape,
                ),
                child: content,
              )
            : FilledButton(
                onPressed: onPressed == null ? null : tap,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(68),
                  padding: padding,
                  shape: shape,
                ),
                child: content,
              ),
      ),
    );
  }
}