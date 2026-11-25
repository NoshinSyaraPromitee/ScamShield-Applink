import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/emergency_tree.dart';

/// Loads the fixed emergency tree bundled with the app.
/// Works offline: no network, no AI-generated advice.
class EmergencyTreeRepository {
  static const _asset = 'assets/data/emergency_tree.json';
  EmergencyTree? _cache;

  Future<EmergencyTree> load() async {
    if (_cache != null) return _cache!;
    final raw = (await rootBundle.loadString(_asset)).replaceFirst('\uFEFF', '');
    return _cache = EmergencyTree.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}