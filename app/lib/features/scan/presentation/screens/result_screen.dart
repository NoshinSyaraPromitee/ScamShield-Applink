import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:scamshield/core/widgets/stitched.dart';
import 'package:scamshield/features/scan/domain/entities/scan_result.dart';
import 'package:scamshield/features/scan/presentation/controllers/scan_controller.dart';
import 'package:scamshield/features/scan/presentation/widgets/highlighted_message.dart';
import 'package:scamshield/features/scan/presentation/widgets/reason_tile.dart';
import 'package:scamshield/features/scan/presentation/widgets/risk_meter.dart';
import 'package:scamshield/features/scan/presentation/widgets/risk_stamp.dart';
import 'package:scamshield/features/scan/presentation/widgets/risk_style.dart';

String _spoken(AppLocalizations l, ScanResult r) => [
      r.risk.title(l),
      r.risk.body(l),
      ...r.reasonCodes.map((code) => reasonText(l, code)),
      r.risk.advice(l),
    ].join(' ');

class ResultScreen extends HookConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(scanControllerProvider);
    final speaker = ref.watch(speakerProvider);

    // Read the verdict aloud as soon as it arrives.
    ref.listen(scanControllerProvider, (previous, next) {
      final settings = ref.read(settingsControllerProvider);
      if (next case AsyncData(value: final result?)) {
        if (settings.voiceOn) speaker.say(_spoken(l, result), languageCode: settings.languageCode);
      }
    });
    useEffect(() => speaker.stop, const []);

    return AppPage(
      title: l.resultTitle,
      speakText: switch (state) {
        AsyncData(value: final result?) => _spoken(l, result),
        _ => null,
      },
      body: switch (state) {
        AsyncData(value: final result?) => _ResultBody(result: result),
        AsyncData() => _NothingYet(onBack: () => context.pop()),
        AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.read(scanControllerProvider.notifier).retry(),
          ),
        _ => const ResultShimmer(),
      },
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final style = RiskStyle.of(result.risk);
    final reduce = context.reduceMotion;
    final risky = result.risk == RiskLevel.high || result.risk == RiskLevel.medium;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(child: RiskStamp(risk: result.risk)),
        const SizedBox(height: 16),
        Text(result.risk.body(l), textAlign: TextAlign.center, style: text.titleLarge),
        const SizedBox(height: 20),
        RiskMeter(risk: result.risk, score: result.score),
        if (result.fromCache) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.offline_pin_rounded, color: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(child: Text(l.fromCache, style: text.bodySmall)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Text(l.yourMessage, style: text.titleMedium),
        const SizedBox(height: 8),
        HighlightedMessage(message: result.message, highlights: result.highlights, color: style.color),
        if (result.reasonCodes.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(l.whyFlagged, style: text.titleMedium),
          const SizedBox(height: 12),
          for (final (index, code) in result.reasonCodes.indexed)
            reduce
                ? ReasonTile(code: code, style: style)
                : ReasonTile(code: code, style: style)
                    .animate(delay: (700 + index * 450).ms)
                    .fadeIn(duration: 350.ms)
                    .slideX(begin: 0.08, end: 0),
        ],
        const SizedBox(height: 24),
        Stitched(
          color: style.color.withValues(alpha: 0.5),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: style.soft, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.adviceTitle, style: text.titleMedium?.copyWith(color: style.deep)),
                const SizedBox(height: 8),
                Text(result.risk.advice(l), style: text.bodyLarge),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (risky) ...[
          BigButton(
            label: l.callHelpline,
            icon: Icons.phone_rounded,
            tone: ButtonTone.danger,
            onPressed: () => context.push(Routes.emergency),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: l.tellFamily,
            icon: Icons.family_restroom_rounded,
            outlined: true,
            onPressed: () => context.push(Routes.family),
          ),
          const SizedBox(height: 12),
        ],
        BigButton(label: l.checkAnother, icon: Icons.refresh_rounded, outlined: true, onPressed: () => context.pop()),
        const SizedBox(height: 16),
        Text(l.notFinalProof, textAlign: TextAlign.center, style: text.bodySmall),
      ],
    );
  }
}

class _NothingYet extends StatelessWidget {
  const _NothingYet({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_unread_rounded, size: 72, color: AppColors.neel),
            const SizedBox(height: 16),
            Text(l.nothingChecked, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            BigButton(label: l.checkMessage, icon: Icons.shield_rounded, onPressed: onBack),
          ],
        ),
      ),
    );
  }
}