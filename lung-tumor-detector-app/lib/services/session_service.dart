import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple local session — replaces Firebase Auth for now.
/// NOTE: Firebase is not configured in this app (no google-services.json),
/// so login/register simply saves the name + email on the device.
/// Real Firebase Auth can replace this later without changing the screens.
class SessionService {
  static const _nameKey = 'session_name';
  static const _emailKey = 'session_email';
  static const _apiUrlKey = 'api_base_url';
  static const _ageKey = 'medical_age';
  static const _smokingKey = 'medical_smoking';
  static const _exposureKey = 'medical_exposure';

  /// Default backend URL. On the web (Chrome on the same PC) the backend
  /// is reached at 127.0.0.1; 10.0.2.2 is the Android emulator's alias for
  /// the host PC's localhost. On a real phone this must be the PC's LAN IP,
  /// e.g. http://192.168.1.5:8000 (changeable in Profile).
  static String get defaultApiUrl =>
      kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';

  static Future<void> saveLogin(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
  }

  static Future<bool> get isLoggedIn async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) != null;
  }

  static Future<String> get name async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? '';
  }

  static Future<String> get email async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? '';
  }

  static Future<void> saveNameEmail(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
  }

  // ── API base URL ──────────────────────────────────────────────────────────

  static Future<String> get apiBaseUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiUrlKey) ?? defaultApiUrl;
  }

  static Future<void> saveApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, url.trim());
  }

  // ── Medical profile (stored on device only, like the web app) ────────────

  static Future<String> get age async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ageKey) ?? '';
  }

  static Future<String> get smoking async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_smokingKey) ?? 'non_smoker';
  }

  static Future<String> get exposure async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_exposureKey) ?? 'not_exposed';
  }

  static Future<void> saveMedicalProfile(
      String age, String smoking, String exposure) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ageKey, age);
    await prefs.setString(_smokingKey, smoking);
    await prefs.setString(_exposureKey, exposure);
  }
}
