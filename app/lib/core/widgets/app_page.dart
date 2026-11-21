import 'package:flutter/material.dart';
import 'package:scamshield/core/widgets/speak_button.dart';

/// Standard page: big back arrow, title, and a listen button that reads [speakText].
class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.title, required this.body, this.speakText});

  final String title;
  final Widget body;
  final String? speakText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (speakText != null)
            Padding(padding: const EdgeInsets.only(right: 12), child: SpeakButton(text: speakText!)),
        ],
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}