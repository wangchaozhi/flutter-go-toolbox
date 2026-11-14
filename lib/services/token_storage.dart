import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _kToken = 'token';
  static const _kRememberedUsername = 'remembered_username';
  static const _kRememberedPassword = 'remembered_password';
  static const _kRememberPassword = 'remember_password';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // WebCrypto is unavailable on HTTP origins. Keep the existing HTTP deployment
  // usable across reloads; HTTPS and native clients use secure storage.
  static bool get usesBrowserStorage =>
      kIsWeb &&
      Uri.base.scheme != 'https' &&
      Uri.base.host != 'localhost' &&
      Uri.base.host != '127.0.0.1';

  static String? _cachedToken;

  static Future<String?> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (usesBrowserStorage) return prefs.getString(key);
    final value = await _secureStorage.read(key: key);
    if (value != null) {
      await prefs.remove(key);
      return value;
    }
    final legacy = prefs.getString(key);
    if (legacy != null) {
      await _secureStorage.write(key: key, value: legacy);
      await prefs.remove(key);
    }
    return legacy;
  }

  static Future<void> _write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    if (usesBrowserStorage) {
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
      await prefs.remove(key);
    }
  }

  static Future<void> _delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    if (!usesBrowserStorage) await _secureStorage.delete(key: key);
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      _cachedToken = await _read(_kToken);
    } catch (error) {
      debugPrint('读取登录状态失败: $error');
    }
    return _cachedToken;
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    try {
      await _write(_kToken, token);
    } catch (error) {
      debugPrint('保存登录状态失败: $error');
    }
  }

  static Future<void> clearToken() async {
    _cachedToken = null;
    await _delete(_kToken);
  }

  static Future<void> saveRememberedCredentials(
    String username,
    String password,
  ) async {
    await _write(_kRememberedPassword, password);
    await saveRememberedUsername(username);
  }

  static Future<void> saveRememberedUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRememberedUsername, username);
    await prefs.setBool(_kRememberPassword, true);
  }

  static Future<String?> getRememberedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kRememberPassword) ?? false)) return null;
    return prefs.getString(_kRememberedUsername);
  }

  static Future<String?> getRememberedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kRememberPassword) ?? false)) return null;
    return _read(_kRememberedPassword);
  }

  static Future<void> clearRememberedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRememberPassword, false);
    await prefs.remove(_kRememberedUsername);
    await _delete(_kRememberedPassword);
  }
}
