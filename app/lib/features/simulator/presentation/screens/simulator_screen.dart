import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/router/routes.dart';
import 'package:scamshield/core/settings/settings_controller.dart';
import 'package:scamshield/core/theme/app_colors.dart';
import 'package:scamshield/core/voice/speaker.dart';
import 'package:scamshield/core/widgets/app_page.dart';
import 'package:scamshield/core/widgets/big_button.dart';
import 'package:scamshield/core/widgets/error_view.dart';
import 'package:scamshield/core/widgets/motion.dart';
import 'package:scamshield/core/widgets/shimmers.dart';
import 'package:scamshield/features/simulator/domain/entities/lesson.dart';
import 'package:scamshield/features/simulator/presentation/controllers/lessons_provider.dart';
import 'package:scamshield/features/simulator/presentation/widgets/sms_bubble.dart';

class SimulatorScreen extends HookConsumerWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lessons = ref.watch(lessonsProvider);

    return AppPage(
      title: l.simTitle,
      speakText: l.simIntro,
      body: switch (lessons) {
        AsyncData(:final value) when value.isNotEmpty => _Quiz(lessons: value),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(lessonsProvider)),
        AsyncData() => ErrorView(error: Exception(), onRetry: () => ref.invalidate(lessonsProvider)),
        _ => const ListShimmer(count: 3, itemHeight: 140),
      },
    );
  }
}

class _Quiz extends HookConsumerWidget {
  const _Quiz({required this.lessons});

  final List<Lesson> lessons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(settingsControllerProvider);
    final speaker = ref.watch(speakerProvider);
    final index = useState(0);
    final saidScam = useState<bool?>(null);
    final score = useState(0);

    if (index.value >= lessons.length) {
      return _Summary(
        score: score.value,
        total: lessons.length,
        onRestart: () {
          index.value = 0;
          score.value = 0;
          saidScam.value = null;
        },
      );
    }

    final lesson = lessons[index.value];
    final signs = lesson.signs(settings.languageCode);
    final answered = saidScam.value != null;
    final correct = answered && saidScam.value == lesson.isScam;

    void answer(bool scam) {
      saidScam.value = scam;
      final ok = scam == lesson.isScam;
      if (ok) {
        score.value++;
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
      if (settings.voiceOn) {
        speaker.say(
          [ok ? l.simCorrect : l.simWrong, lesson.isScam ? l.simItWasScam : l.simItWasReal, ...signs].join(' '),
          languageCode: settings.languageCode,
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(l.simProgress(index.value + 1, lessons.length), style: text.titleMedium),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (index.value + 1) / lessons.length,
            minHeight: 12,
            backgroundColor: AppColors.line,
            color: AppColors.neel,
          ),
        ),
        const SizedBox(height: 20),
        SmsBubble(sender: lesson.sender, body: lesson.body),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(animation), child: child),
          ),
          child: !answered
              ? Column(
                  key: ValueKey('question-${index.value}'),
                  children: [
                    BigButton(
                      label: l.simReal,
                      icon: Icons.verified_rounded,
                      tone: ButtonTone.safe,
                      outlined: true,
                      onPressed: () => answer(false),
                    ),
                    const SizedBox(height: 14),
                    BigButton(
                      label: l.simScam,
                      icon: Icons.gpp_bad_rounded,
                      tone: ButtonTone.danger,
                      outlined: true,
                      onPressed: () => answer(true),
                    ),
                  ],
                )
              : _Feedback(
                  key: ValueKey('answer-${index.value}'),
                  correct: correct,
                  isScam: lesson.isScam,
                  signs: signs,
                  onNext: () {
                    speaker.stop();
                    saidScam.value = null;
                    index.value++;
                  },
                ),
        ),
      ],
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({super.key, required this.correct, required this.isScam, required this.signs, required this.onNext});

  final bool correct;
  final bool isScam;
  final List<String> signs;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final color = correct ? AppColors.safe : AppColors.cautionDeep;
    final soft = correct ? AppColors.safeSoft : AppColors.cautionSoft;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle_rounded : Icons.info_rounded, size: 44, color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(correct ? l.simCorrect : l.simWrong, style: text.headlineMedium?.copyWith(color: color))),
            ],
          ),
          const SizedBox(height: 8),
          Text(isScam ? l.simItWasScam : l.simItWasReal, style: text.titleMedium),
          const SizedBox(height: 16),
          Text(l.simSigns, style: text.titleMedium),
          const SizedBox(height: 8),
          for (final sign in signs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 12, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(sign, style: text.bodyLarge)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          BigButton(label: l.simNext, icon: Icons.arrow_forward_rounded, onPressed: onNext),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.score, required this.total, required this.onRestart});

  final int score;
  final int total;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.emoji_events_rounded, size: 110, color: AppColors.neel),
        const SizedBox(height: 16),
        Text(l.simDoneTitle(score, total), textAlign: TextAlign.center, style: text.headlineMedium),
        const SizedBox(height: 12),
        Text(l.simDoneBody, textAlign: TextAlign.center, style: text.bodyLarge),
        const SizedBox(height: 32),
        BigButton(label: l.simAgain, icon: Icons.replay_rounded, onPressed: onRestart),
        const SizedBox(height: 12),
        BigButton(label: l.goHome, icon: Icons.home_rounded, outlined: true, onPressed: () => context.go(Routes.home)),
      ],
    );
  }
}