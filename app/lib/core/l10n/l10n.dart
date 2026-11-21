import 'package:flutter/widgets.dart';
import 'package:scamshield/core/l10n/gen/app_localizations.dart';

export 'package:scamshield/core/l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Shows numbers in Bangla digits when the app is in Bangla.
String localDigits(String input, String languageCode) {
  if (languageCode != 'bn') return input;
  const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return input.replaceAllMapped(RegExp(r'\d'), (m) => digits[int.parse(m[0]!)]);
}