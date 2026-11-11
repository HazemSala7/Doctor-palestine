import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// People this device has blocked; their reviews and reels are hidden.
/// Patients have no account, so the list lives on the phone.
///
/// Keys: 'review:<author>' for a reviewer, 'doctor:<id>' for a doctor's reels,
/// 'reel:<id>' for a reel with no doctor.
class Blocks {
  Blocks._();

  static const _prefsKey = 'blocked_keys';
  static final ValueNotifier<Set<String>> blocked = ValueNotifier({});

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    blocked.value = (prefs.getStringList(_prefsKey) ?? const []).toSet();
  }

  static bool isBlocked(String key) => blocked.value.contains(key);

  static Future<void> block(String key) async {
    blocked.value = {...blocked.value, key};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, blocked.value.toList());
  }
}
