import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/global_config.dart';
import '../storage/app_prefs.dart';

class ApiClient {
  ApiClient({
    required AppPrefs prefs,
    http.Client? client,
  })  : _prefs = prefs,
        _client = client ?? http.Client();

  final AppPrefs _prefs;
  final http.Client _client;

  Future<Map<String, dynamic>> get(
    String path, {
    bool authRequired = true,
  }) async {
    final uri = Uri.parse('${AppConfig.apiDosen}$path');
    final response = await _client
        .get(
          uri,
          headers: await _headers(authRequired: authRequired),
        )
        .timeout(const Duration(seconds: 20));
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    bool authRequired = true,
  }) async {
    final uri = Uri.parse('${AppConfig.apiDosen}$path');
    final response = await _client
        .post(
          uri,
          headers: await _headers(authRequired: authRequired),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _decodeResponse(response);
  }

  Future<void> clearSession() async {
    await _prefs.remove(AppStorageKeys.tokenDosen);
    await _prefs.remove(AppStorageKeys.loginDosen);
    await _prefs.remove(AppStorageKeys.profileDosenJson);
  }

  Future<Map<String, String>> _headers({required bool authRequired}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authRequired) {
      final token = _prefs.getString(AppStorageKeys.tokenDosen);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.trim();
    Map<String, dynamic> jsonBody = <String, dynamic>{};

    if (body.isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        jsonBody = decoded;
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonBody;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _resolveMessage(response.statusCode, jsonBody),
    );
  }

  String _resolveMessage(int statusCode, Map<String, dynamic> jsonBody) {
    final dynamic message = jsonBody['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    switch (statusCode) {
      case 400:
        return 'Validasi data gagal.';
      case 401:
      case 403:
        return 'Sesi tidak valid. Silakan login kembali.';
      case 404:
        return 'Data tidak ditemukan.';
      case 500:
        return 'Terjadi kesalahan pada server.';
      default:
        return 'Terjadi kesalahan.';
    }
  }
}

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
