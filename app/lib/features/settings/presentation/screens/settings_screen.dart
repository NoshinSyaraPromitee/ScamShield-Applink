import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/settings/settings_controller.dart';
import 'package:scamshield/core/theme/app_colors.dart';
import 'package:scamshield/core/voice/speaker.dart';
import 'package:scamshield/core/widgets/app_page.dart';
import 'package:scamshield/core/widgets/big_button.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);
    final speaker = ref.watch(speakerProvider);

    return AppPage(
      title: l.settingsTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(l.language, style: text.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LanguageChoice(
                  label: 'বাংলা',
                  selected: settings.languageCode == 'bn',
                  onTap: () => notifier.setLanguage('bn'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LanguageChoice(
                  label: 'English',
                  selected: settings.languageCode == 'en',
                  onTap: () => notifier.setLanguage('en'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SettingSwitch(
            icon: Icons.format_size_rounded,
            title: l.largeText,
            value: settings.largeText,
            onChanged: notifier.setLargeText,
          ),
          const SizedBox(height: 12),
          _SettingSwitch(
            icon: Icons.record_voice_over_rounded,
            title: l.voice,
            subtitle: l.voiceHint,
            value: settings.voiceOn,
            onChanged: notifier.setVoiceOn,
          ),
          const SizedBox(height: 20),
          BigButton(
            label: l.testVoice,
            icon: Icons.volume_up_rounded,
            outlined: true,
            onPressed: () => speaker.say(l.homeGreeting, languageCode: settings.languageCode),
          ),
        ],
      ),
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.neelSoft : AppColors.paper,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: selected ? AppColors.neel : AppColors.line, width: selected ? 3 : 2),
            ),
            child: Text(label, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(20),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        secondary: Icon(icon, size: 34, color: AppColors.neel),
        title: Text(title, style: text.titleMedium),
        subtitle: subtitle == null ? null : Text(subtitle!, style: text.bodySmall),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}