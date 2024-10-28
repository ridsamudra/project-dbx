// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/browser_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _baseUrl = 'http://127.0.0.1:8000/api';

  static const String _sessionKey = 'session_data';

  final BrowserClient _client = BrowserClient()..withCredentials = true;

  AuthService();

  Future<bool> login(String idUser, String password) async {
    final url = Uri.parse('$_baseUrl/users/login/');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id_user': idUser,
          'password': password,
        }),
      );
      // ignore: avoid_print
      print('Login response status: ${response.statusCode}');
      // print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        // print('Response body: $responseBody');

        // Pastikan ada session_data di response body
        final sessionData = responseBody['session_data'];
        if (sessionData != null) {
          await _saveSessionData(sessionData);
          // ignore: avoid_print
          print('Session data tersimpan!');
          return true;
        } else {
          // print('No session data found in response body');
        }
      }
      // ignore: avoid_print
      print('Login gagal: ${response.statusCode}');
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Login error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionDataJson = prefs.getString(_sessionKey);
    if (sessionDataJson != null) {
      return jsonDecode(sessionDataJson);
    }
    return null;
  }

  Future<void> _saveSessionData(Map<String, dynamic> sessionData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(sessionData));
    // ignore: avoid_print
    // print('Session data saved: $sessionData');
  }

  Future<void> _clearSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    // ignore: avoid_print
    print('Session data dihapus!');
  }

  Future<bool> logout() async {
    final url = Uri.parse('$_baseUrl/users/logout/');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // print('Logout response status: ${response.statusCode}');
      // print('Logout response body: ${response.body}');

      if (response.statusCode == 200) {
        await _clearSessionData();
        // ignore: avoid_print
        print('Logged out berhasil!');
        return true;
      } else {
        // ignore: avoid_print
        print('Logout gagal: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error during logout: $e');
      return false;
    }
  }
}
