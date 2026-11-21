import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scamshield/core/di/injection.dart';

part 'speaker.g.dart';

/// Reads text aloud in Bangla or English, slowly and clearly.
class Speaker {
  Speaker(this._tts) {
    _tts.setStartHandler(() => speaking.value = true);
    _tts.setCompletionHandler(() => speaking.value = false);
    _tts.setCancelHandler(() => speaking.value = false);
    _tts.setErrorHandler((_) => speaking.value = false);
  }

  final FlutterTts _tts;
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  Future<void> say(String text, {required String languageCode}) async {
    await _tts.stop();
    await _tts.setLanguage(await _pickLanguage(languageCode));
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    speaking.value = false;
  }

  Future<String> _pickLanguage(String code) async {
    final candidates = code == 'bn' ? ['bn-BD', 'bn-IN', 'bn'] : ['en-US', 'en-GB', 'en'];
    for (final candidate in candidates) {
      try {
        final available = await _tts.isLanguageAvailable(candidate);
        if (available == true || available == 1) return candidate;
      } catch (_) {
        // Some platforms cannot answer; try the next one.
      }
    }
    return candidates.first;
  }
}

@Riverpod(keepAlive: true)
Speaker speaker(Ref ref) {
  final speaker = Speaker(getIt<FlutterTts>());
  ref.onDispose(speaker.stop);
  return speaker;
}