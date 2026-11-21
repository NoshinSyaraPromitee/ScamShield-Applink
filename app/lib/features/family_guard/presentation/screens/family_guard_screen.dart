import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/settings/settings_controller.dart';
import 'package:scamshield/core/theme/app_colors.dart';
import 'package:scamshield/core/widgets/app_page.dart';
import 'package:scamshield/core/widgets/big_button.dart';
import 'package:scamshield/core/widgets/error_view.dart';
import 'package:scamshield/core/widgets/motion.dart';
import 'package:scamshield/core/widgets/numbered_step.dart';
import 'package:scamshield/core/widgets/shimmers.dart';
import 'package:scamshield/core/widgets/stitched.dart';
import 'package:scamshield/features/family_guard/domain/entities/guardian_link.dart';
import 'package:scamshield/features/family_guard/presentation/controllers/guardian_controller.dart';

class FamilyGuardScreen extends HookConsumerWidget {
  const FamilyGuardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(guardianControllerProvider);

    return AppPage(
      title: l.familyTitle,
      speakText: l.familyIntro,
      body: switch (status) {
        AsyncData(:final value) when value.paired => _Protected(link: value),
        AsyncData() => const _PairForm(),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(guardianControllerProvider)),
        _ => const ListShimmer(count: 2, itemHeight: 160),
      },
    );
  }
}

class _PairForm extends HookConsumerWidget {
  const _PairForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final lang = ref.watch(settingsControllerProvider).languageCode;
    final code = useTextEditingController();
    final busy = useState(false);
    final error = useState<String?>(null);

    Future<void> pair() async {
      if (!RegExp(r'^\d{4}$').hasMatch(code.text)) {
        error.value = l.pairCodeError;
        return;
      }
      error.value = null;
      busy.value = true;
      final failure = await ref.read(guardianControllerProvider.notifier).pair(code.text);
      if (!context.mounted) return;
      busy.value = false;
      if (failure != null) error.value = failureMessage(l, failure);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const _FamilyPicture(),
        const SizedBox(height: 20),
        Text(l.familyIntro, style: text.bodyLarge),
        const SizedBox(height: 20),
        Stitched(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            decoration: BoxDecoration(color: AppColors.neelSoft, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                NumberedStep(number: 1, text: l.pairStep1, languageCode: lang),
                NumberedStep(number: 2, text: l.pairStep2, languageCode: lang),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(l.pairCodeLabel, style: text.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: code,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
          style: text.displaySmall?.copyWith(letterSpacing: 18),
          onChanged: (_) => error.value = null,
          decoration: InputDecoration(hintText: '••••', errorText: error.value),
        ),
        const SizedBox(height: 16),
        BigButton(label: l.pairButton, icon: Icons.link_rounded, busy: busy.value, onPressed: pair),
        const SizedBox(height: 20),
        const _PrivacyNote(),
      ],
    );
  }
}

class _Protected extends StatelessWidget {
  const _Protected({required this.link});

  final GuardianLink link;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final material = MaterialLocalizations.of(context);
    final last = link.lastAlertAt;
    final lastText = last == null
        ? l.noAlerts
        : l.lastAlert('${material.formatShortDate(last)}, ${material.formatTimeOfDay(TimeOfDay.fromDateTime(last))}');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.safe, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.safeSoft,
                    child: Icon(Icons.elderly_rounded, size: 40, color: AppColors.safe),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(link.name ?? '', style: text.headlineMedium),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: AppColors.safe),
                            const SizedBox(width: 6),
                            Text(l.protectedLabel, style: text.titleMedium?.copyWith(color: AppColors.safe)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 36, thickness: 1.5),
              Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.neel),
                  const SizedBox(width: 12),
                  Expanded(child: Text(lastText, style: text.bodyLarge)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _PrivacyNote(),
      ],
    );
  }
}

class _FamilyPicture extends StatelessWidget {
  const _FamilyPicture();

  @override
  Widget build(BuildContext context) {
    Widget heart = const Icon(Icons.favorite_rounded, color: AppColors.danger, size: 40);
    if (!context.reduceMotion) {
      heart = heart.animate().scale(begin: const Offset(0.4, 0.4), end: const Offset(1, 1), duration: 700.ms, curve: Curves.elasticOut);
    }
    Widget person(IconData icon) => CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.neelSoft,
          child: Icon(icon, size: 46, color: AppColors.neel),
        );
    Widget thread() => Expanded(
          child: SizedBox(height: 6, child: CustomPaint(painter: _ThreadPainter())),
        );

    return Row(
      children: [
        person(Icons.elderly_rounded),
        thread(),
        heart,
        thread(),
        person(Icons.person_rounded),
      ],
    );
  }
}

/// A dashed kantha thread between parent and child.
class _ThreadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.stitch
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    var x = 6.0;
    final y = size.height / 2;
    while (x < size.width - 6) {
      canvas.drawLine(Offset(x, y), Offset((x + 9).clamp(0, size.width - 6), y), paint);
      x += 16;
    }
  }

  @override
  bool shouldRepaint(_ThreadPainter oldDelegate) => false;
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_rounded, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(child: Text(context.l10n.privacyNote, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}