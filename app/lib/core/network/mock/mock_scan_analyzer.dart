/// A small copy of the backend rules so the demo works offline.
abstract final class MockScanAnalyzer {
  static const _officialDomains = ['gov.bd', 'bkash.com', 'nagad.com.bd', 'dutchbanglabank.com'];
  static const _trustedSenders = ['01320042207', '01320042227']; // DMP traffic-case SMS numbers
  static final _link = RegExp(
    r'(https?://)?([a-z0-9-]+\.)+(xyz|top|click|info|link|site|online|live|com|net|org|bd)(/\S*)?',
    caseSensitive: false,
  );
  static final _brand = RegExp(r'bkash|nagad|rocket|bank|dmp|traffic|police|বিকাশ|নগদ|ব্যাংক|পুলিশ', caseSensitive: false);

  static const _rules = <String, List<String>>{
    'urgency': ['urgent', 'immediately', 'within 24', 'today', 'blocked', 'suspend', 'legal action', 'জরুরি', 'ব্লক', 'আজই', '২৪ ঘণ্টা', 'বন্ধ হয়ে'],
    'asks_secret': ['pin', 'otp', 'password', 'পিন', 'ওটিপি', 'পাসওয়ার্ড'],
    'too_good': ['won', 'cashback', 'prize', 'lottery', 'bonus', 'gift', 'ক্যাশব্যাক', 'পুরস্কার', 'লটারি', 'উপহার'],
    'pay_fast': ['% off', 'discount', 'pay now', 'fine', 'ছাড়', 'জরিমানা'],
  };

  static Map<String, dynamic> analyze(String message, String? sender) {
    final reasons = <String>[];
    final highlights = <String>{};

    void flag(String code, String text) {
      if (!reasons.contains(code)) reasons.add(code);
      highlights.add(text);
    }

    for (final match in _link.allMatches(message)) {
      final url = match.group(0)!;
      final official = _officialDomains.any((d) => url.toLowerCase().contains(d));
      if (!official) flag('unofficial_link', url);
    }

    _rules.forEach((code, words) {
      for (final word in words) {
        final found = _find(message, word);
        if (found != null) flag(code, found);
      }
    });

    final digits = (sender ?? '').replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('88') ? digits.substring(2) : digits;
    final trusted = _trustedSenders.contains(local);
    if (!trusted && RegExp(r'^01\d{9}$').hasMatch(local) && _brand.hasMatch(message)) {
      if (!reasons.contains('personal_number')) reasons.add('personal_number');
    }

    final score = reasons
        .fold<double>(0, (sum, r) => sum + (r == 'asks_secret' || r == 'unofficial_link' ? 0.35 : 0.2))
        .clamp(0.0, 1.0);

    final String risk;
    if (trusted && !reasons.contains('unofficial_link')) {
      risk = 'low';
    } else if (score >= 0.55) {
      risk = 'high';
    } else if (score >= 0.2) {
      risk = 'medium';
    } else {
      risk = 'none';
    }

    return <String, dynamic>{
      'risk': risk,
      'score': score,
      'reasons': reasons,
      'highlights': highlights.toList(),
    };
  }

  static String? _find(String text, String word) {
    final ascii = RegExp(r'^[\x00-\x7F]+$').hasMatch(word);
    if (ascii) {
      final match = RegExp('(?<![A-Za-z])${RegExp.escape(word)}(?![A-Za-z])', caseSensitive: false).firstMatch(text);
      return match?.group(0);
    }
    final i = text.indexOf(word);
    return i < 0 ? null : text.substring(i, i + word.length);
  }
}