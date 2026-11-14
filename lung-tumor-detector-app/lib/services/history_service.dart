import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_result.dart';

/// Scan history saved on the device, same shape as the web app
/// (localStorage key 'lungdetect_scan_history', max 50 entries).
class HistoryService {
  static const _key = 'lungdetect_scan_history';
  static const int maxEntries = 50;

  static Future<List<ScanResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    return ScanResult.decodeHistory(raw);
  }

  static Future<void> saveScan(ScanResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    final updated = [result, ...history].take(maxEntries).toList();
    await prefs.setString(_key, ScanResult.encodeHistory(updated));
  }

  static Future<void> deleteScan(int idMillis) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.removeWhere(
      (r) => r.date.millisecondsSinceEpoch == idMillis,
    );
    await prefs.setString(_key, ScanResult.encodeHistory(history));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
