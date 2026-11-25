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
import 'package:scamshield/features/emergency/presentation/controllers/helplines_provider.dart';
import 'package:scamshield/features/emergency_tree/domain/emergency_tree.dart';
import 'package:scamshield/features/emergency_tree/presentation/emergency_tree_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// "I've been scammed": walks the fixed, offline emergency tree
/// (assets/data/emergency_tree.json) one question at a time.
class EmergencyScreen extends HookConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final lang = ref.watch(settingsControllerProvider).languageCode;
    final bn = lang == 'bn';
    final reduce = context.reduceMotion;

    final treeAsync = ref.watch(emergencyTreeProvider);
    final helplines = ref.watch(helplinesProvider);
    final path = useState<List<String>>(const []);

    final EmergencyTree? tree = switch (treeAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final stack = path.value.isEmpty && tree != null ? [tree.root] : path.value;
    final TreeNode? node = tree?.node(stack.last);

    void go(String id) => path.value = [...stack, id];
    void back() => path.value = stack.sublist(0, stack.length - 1);
    void restart() => path.value = const [];

    final speakText = node == null
        ? l.emergencyCalm
        : node.end
            ? [l.stepsTitle, ...node.steps(bn)].join(' ')
            : '${l.emergencyCalm} ${node.question(bn)}';

    return PopScope(
      canPop: stack.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: AppPage(
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
            const SizedBox(height: 20),
            if (stack.length > 1)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: back,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(bn ? 'Pechone jan' : 'Back'),
                ),
              ),
            if (tree == null || node == null)
              treeAsync.hasError
                  ? ErrorView(error: treeAsync.error!, onRetry: () => ref.invalidate(emergencyTreeProvider))
                  : const ListShimmer(count: 4, itemHeight: 84, padding: EdgeInsets.zero)
            else if (!node.end) ...[
              Text(node.question(bn), style: text.headlineMedium),
              const SizedBox(height: 12),
              for (final o in node.options)
                Padding(
                  key: ValueKey('${node.id}-${o.key}'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BigTile(
                    icon: _iconFor(o.next),
                    title: o.label(bn),
                    selected: false,
                    onTap: () => go(o.next),
                  ),
                ),
            ] else ...[
              Text(l.stepsTitle, style: text.headlineMedium),
              const SizedBox(height: 12),
              for (final (i, step) in node.steps(bn).indexed)
                reduce
                    ? NumberedStep(number: i + 1, text: step, languageCode: lang)
                    : NumberedStep(key: ValueKey('${node.id}-$i'), number: i + 1, text: step, languageCode: lang)
                        .animate(delay: (i * 300).ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.15, end: 0),
              const SizedBox(height: 24),
              Text(l.helplinesTitle, style: text.titleLarge),
              const SizedBox(height: 12),
              for (final h in tree.hotlinesFor(node))
                _HelplineTile(name: h.name(bn), number: h.number, hours: h.hours, languageCode: lang),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: restart,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(bn ? 'Abar shuru korun' : 'Start again'),
              ),
            ],
            if (node != null && !node.end) ...[
              const SizedBox(height: 28),
              Text(l.helplinesTitle, style: text.titleLarge),
              const SizedBox(height: 12),
              switch (helplines) {
                AsyncData(:final value) => Column(
                    children: [
                      for (final h in value) _HelplineTile(name: h.name(lang), number: h.number, languageCode: lang),
                    ],
                  ),
                AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(helplinesProvider)),
                _ => const ListShimmer(count: 3, itemHeight: 84, padding: EdgeInsets.zero),
              },
            ],
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
      ),
    );
  }

  static IconData _iconFor(String next) => switch (next) {
        'otp' => Icons.password_rounded,
        'otp_mfs' => Icons.account_balance_wallet_rounded,
        'otp_bank' => Icons.credit_card_rounded,
        'money' => Icons.payments_rounded,
        'call' => Icons.phone_in_talk_rounded,
        'link' => Icons.link_rounded,
        'hacked' => Icons.lock_open_rounded,
        'threat' => Icons.report_rounded,
        _ => Icons.help_outline_rounded,
      };
}

class _HelplineTile extends StatelessWidget {
  const _HelplineTile({required this.name, required this.number, required this.languageCode, this.hours});

  final String name;
  final String number;
  final String? hours;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final dial = number.replaceAll(RegExp(r'[^0-9+]'), '');
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
                Text(name, style: text.titleMedium),
                Text(
                  localDigits(number, languageCode),
                  style: text.bodyLarge?.copyWith(color: AppColors.muted),
                ),
                if (hours != null)
                  Text(
                    hours!,
                    style: text.bodySmall?.copyWith(color: AppColors.muted),
                  ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.safe,
              minimumSize: const Size(120, 60),
            ),
            onPressed: dial.isEmpty
                ? null
                : () => launchUrl(Uri(scheme: 'tel', path: dial)),
            icon: const Icon(Icons.phone_rounded, size: 26),
            label: Text(l.call),
          ),
        ],
      ),
    );
  }
}
