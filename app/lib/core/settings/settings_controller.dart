import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scamshield/core/di/injection.dart';
import 'package:scamshield/core/settings/app_settings.dart';
import 'package:scamshield/core/storage/pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_controller.g.dart';

@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  SharedPreferences get _prefs => getIt<SharedPreferences>();

  @override
  AppSettings build() => AppSettings(
        languageCode: _prefs.getString(PrefKeys.locale) ?? 'bn',
        largeText: _prefs.getBool(PrefKeys.largeText) ?? true,
        voiceOn: _prefs.getBool(PrefKeys.voiceOn) ?? true,
      );

  Future<void> setLanguage(String code) async {
    state = state.copyWith(languageCode: code);
    await _prefs.setString(PrefKeys.locale, code);
  }

  Future<void> setLargeText(bool value) async {
    state = state.copyWith(largeText: value);
    await _prefs.setBool(PrefKeys.largeText, value);
  }

  Future<void> setVoiceOn(bool value) async {
    state = state.copyWith(voiceOn: value);
    await _prefs.setBool(PrefKeys.voiceOn, value);
  }
}