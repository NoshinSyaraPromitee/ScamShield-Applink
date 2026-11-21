import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scamshield/core/l10n/l10n.dart';
import 'package:scamshield/core/router/routes.dart';
import 'package:scamshield/core/widgets/app_page.dart';
import 'package:scamshield/core/widgets/big_button.dart';
import 'package:scamshield/features/scan/presentation/controllers/scan_controller.dart';

class ScanScreen extends HookConsumerWidget {
  const ScanScreen({super.key, this.initialText});

  /// Filled in when the user shares a message into ScamShield.
  final String? initialText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final message = useTextEditingController(text: initialText);
    final sender = useTextEditingController();
    final error = useState<String?>(null);

    Future<void> paste() async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final pasted = data?.text;
      if (pasted == null || pasted.isEmpty) return;
      message.text = pasted;
      error.value = null;
      HapticFeedback.lightImpact();
    }

    void submit() {
      if (message.text.trim().length < 4) {
        error.value = l.emptyMessageError;
        return;
      }
      FocusScope.of(context).unfocus();
      ref.read(scanControllerProvider.notifier).check(message: message.text, sender: sender.text);
      context.push(Routes.result);
    }

    return AppPage(
      title: l.checkMessage,
      speakText: l.scanInstructions,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(l.messageLabel, style: text.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: message,
            minLines: 5,
            maxLines: 10,
            style: text.bodyLarge,
            onChanged: (_) => error.value = null,
            decoration: InputDecoration(hintText: l.messageHint, errorText: error.value),
          ),
          const SizedBox(height: 12),
          BigButton(label: l.pasteButton, icon: Icons.content_paste_rounded, outlined: true, onPressed: paste),
          const SizedBox(height: 28),
          Text(l.senderLabel, style: text.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: sender,
            style: text.bodyLarge,
            decoration: InputDecoration(hintText: l.senderHint),
          ),
          const SizedBox(height: 6),
          Text(l.senderWhy, style: text.bodySmall),
          const SizedBox(height: 32),
          BigButton(label: l.checkNow, icon: Icons.shield_rounded, onPressed: submit),
        ],
      ),
    );
  }
}