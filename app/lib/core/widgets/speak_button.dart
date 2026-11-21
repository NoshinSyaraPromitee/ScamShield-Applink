import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/settings/settings_controller.dart';
import 'package:scamshield/core/theme/app_colors.dart';
import 'package:scamshield/core/voice/speaker.dart';
import 'package:scamshield/core/widgets/motion.dart';

/// Big "listen" button. Rings pulse while it is speaking; tap again to stop.
class SpeakButton extends HookConsumerWidget {
  const SpeakButton({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final speaker = ref.watch(speakerProvider);
    final speaking = useValueListenable(speaker.speaking);
    if (!settings.voiceOn) return const SizedBox.shrink();

    final l = context.l10n;
    return Semantics(
      button: true,
      label: speaking ? l.stopListening : l.listen,
      excludeSemantics: true,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (speaking && !context.reduceMotion)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.neel.withValues(alpha: 0.2)),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.3, 1.3), duration: 1100.ms)
                    .fadeOut(duration: 1100.ms),
              ),
            IconButton.filled(
              iconSize: 30,
              tooltip: speaking ? l.stopListening : l.listen,
              style: IconButton.styleFrom(backgroundColor: AppColors.neel, minimumSize: const Size(56, 56)),
              onPressed: () {
                HapticFeedback.selectionClick();
                if (speaking) {
                  speaker.stop();
                } else {
                  speaker.say(text, languageCode: settings.languageCode);
                }
              },
              icon: Icon(speaking ? Icons.stop_rounded : Icons.volume_up_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}