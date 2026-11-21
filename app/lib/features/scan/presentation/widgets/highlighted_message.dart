import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scamshield/core/theme/app_colors.dart';
import 'package:scamshield/core/widgets/motion.dart';

/// Shows the user's own message and marks each suspicious part one after another,
/// so they learn exactly which words gave the scam away.
class HighlightedMessage extends HookWidget {
  const HighlightedMessage({super.key, required this.message, required this.highlights, required this.color});

  final String message;
  final List<String> highlights;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ranges = useMemoized(() => _findRanges(message, highlights), [message, highlights]);
    final reduce = context.reduceMotion;
    final controller = useAnimationController(duration: Duration(milliseconds: reduce ? 1 : 700 + ranges.length * 450));

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) controller.forward(from: 0);
      });
      return null;
    }, [message]);

    final t = useAnimation(controller);
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (var i = 0; i < ranges.length; i++) {
      final range = ranges[i];
      if (range.start > cursor) spans.add(TextSpan(text: message.substring(cursor, range.start)));
      final start = 0.15 + (i / ranges.length) * 0.65;
      final local = ((t - start) / 0.2).clamp(0.0, 1.0);
      spans.add(
        TextSpan(
          text: message.substring(range.start, range.end),
          style: TextStyle(
            backgroundColor: color.withValues(alpha: 0.22 * local),
            fontWeight: local > 0.5 ? FontWeight.w700 : null,
            decoration: local > 0.5 ? TextDecoration.underline : TextDecoration.none,
            decorationColor: color,
            decorationThickness: 2.5,
          ),
        ),
      );
      cursor = range.end;
    }
    if (cursor < message.length) spans.add(TextSpan(text: message.substring(cursor)));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line, width: 2),
      ),
      child: Text.rich(TextSpan(style: Theme.of(context).textTheme.bodyLarge, children: spans)),
    );
  }
}

List<TextRange> _findRanges(String text, List<String> words) {
  final lower = text.toLowerCase();
  final ranges = <TextRange>[];
  for (final word in words) {
    if (word.isEmpty) continue;
    final index = lower.indexOf(word.toLowerCase());
    if (index < 0) continue;
    final range = TextRange(start: index, end: index + word.length);
    final overlaps = ranges.any((r) => range.start < r.end && r.start < range.end);
    if (!overlaps) ranges.add(range);
  }
  ranges.sort((a, b) => a.start.compareTo(b.start));
  return ranges;
}