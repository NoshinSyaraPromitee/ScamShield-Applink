import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/settings/settings_controller.dart';
import 'package:scamshield/core/theme/app_colors.dart';
import 'package:scamshield/core/widgets/app_page.dart';
import 'package:scamshield/core/widgets/big_tile.dart';
import 'package:scamshield/core/widgets/error_view.dart';
import 'package:scamshield/core/widgets/motion.dart';
import 'package:scamshield/core/widgets/numbered_step.dart';
import 'package:scamshield/core/widgets/shimmers.dart';
import 'package:scamshield/features/emergency/domain/entities/helpline.dart';
import 'package:scamshield/features/emergency/presentation/controllers/helplines_provider.dart';
import 'package:scamshield/features/emergency/presentation/widgets/situation.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends HookConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final selected = useState<Situation?>(null);
    final helplines = ref.watch(helplinesProvider);
    final lang = ref.watch(settingsControllerProvider).languageCode;
    final reduce = context.reduceMotion;
    final situation = selected.value;

    final speakText = situation == null
        ? '${l.emergencyCalm} ${l.emergencyWhat}'
        : [l.stepsTitle, ...situation.steps(l)].join(' ');

    return AppPage(
      title: l.emergencyTitle,
      speakText: speakText,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.neel, borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(child: Text(l.emergencyCalm, style: text.bodyLarge?.copyWith(color: Colors.white))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l.emergencyWhat, style: text.headlineMedium),
          const SizedBox(height: 12),
          for (final s in Situation.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BigTile(
                icon: s.icon,
                title: s.label(l),
                selected: situation == s,
                onTap: () => selected.value = s,
              ),
            ),
          if (situation != null) ...[
            const SizedBox(height: 12),
            Text(l.stepsTitle, style: text.titleLarge),
            const SizedBox(height: 12),
            for (final (i, step) in situation.steps(l).indexed)
              reduce
                  ? NumberedStep(number: i + 1, text: step, languageCode: lang)
                  : NumberedStep(key: ValueKey('$situation-$i'), number: i + 1, text: step, languageCode: lang)
                      .animate(delay: (i * 300).ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.15, end: 0),
          ],
          const SizedBox(height: 28),
          Text(l.helplinesTitle, style: text.titleLarge),
          const SizedBox(height: 12),
          switch (helplines) {
            AsyncData(:final value) => Column(
                children: [for (final h in value) _HelplineTile(helpline: h, languageCode: lang)],
              ),
            AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(helplinesProvider)),
            _ => const ListShimmer(count: 3, itemHeight: 84, padding: EdgeInsets.zero),
          },
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.photo_camera_rounded, color: AppColors.muted),
              const SizedBox(width: 10),
              Expanded(child: Text(l.keepEvidence, style: text.bodyMedium)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelplineTile extends StatelessWidget {
  const _HelplineTile({required this.helpline, required this.languageCode});

  final Helpline helpline;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(helpline.name(languageCode), style: text.titleMedium),
                Text(localDigits(helpline.number, languageCode), style: text.bodyLarge?.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.safe, minimumSize: const Size(120, 60)),
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: helpline.number)),
            icon: const Icon(Icons.phone_rounded, size: 26),
            label: Text(l.call),
          ),
        ],
      ),
    );
  }
}