import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/router/routes.dart';
import 'package:scamshield/core/theme/app_colors.dart';
import 'package:scamshield/core/widgets/big_tile.dart';
import 'package:scamshield/core/widgets/shield_mark.dart';
import 'package:scamshield/core/widgets/speak_button.dart';
import 'package:scamshield/features/home/presentation/widgets/check_hero_card.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                const ShieldMark(),
                const SizedBox(width: 12),
                Expanded(child: Text(l.appTitle, style: text.titleLarge)),
                SpeakButton(text: '${l.homeGreeting} ${l.homeSubtitle}'),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  iconSize: 30,
                  tooltip: l.settings,
                  style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
                  onPressed: () => context.push(Routes.settings),
                  icon: const Icon(Icons.settings_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l.homeGreeting, style: text.headlineMedium),
            const SizedBox(height: 8),
            Text(l.homeSubtitle, style: text.bodyLarge?.copyWith(color: AppColors.muted)),
            const SizedBox(height: 24),
            CheckHeroCard(onTap: () => context.push(Routes.scan)),
            const SizedBox(height: 16),
            BigTile(
              icon: Icons.school_rounded,
              title: l.practice,
              subtitle: l.practiceHint,
              onTap: () => context.push(Routes.simulator),
            ),
            const SizedBox(height: 12),
            BigTile(
              icon: Icons.family_restroom_rounded,
              title: l.familyGuard,
              subtitle: l.familyGuardHint,
              tone: TileTone.safe,
              onTap: () => context.push(Routes.family),
            ),
            const SizedBox(height: 12),
            BigTile(
              icon: Icons.sos_rounded,
              title: l.scammed,
              subtitle: l.scammedHint,
              tone: TileTone.danger,
              onTap: () => context.push(Routes.emergency),
            ),
          ],
        ),
      ),
    );
  }
}