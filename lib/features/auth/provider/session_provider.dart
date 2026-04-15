import 'package:flutter/material.dart';
import 'dart:convert';

import '../../../core/constants/global_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/app_prefs.dart';
import '../model/me_response.dart';
import '../service/auth_service.dart';

class SessionProvider extends ChangeNotifier {
  SessionProvider({
    required AppPrefs prefs,
    required AuthService authService,
    required ApiClient apiClient,
  }) : _prefs = prefs,
       _authService = authService,
       _apiClient = apiClient;

  final AppPrefs _prefs;
  final AuthService _authService;
  final ApiClient _apiClient;

  bool _isInitializing = true;
  bool _isSubmitting = false;
  bool _isAuthenticated = false;
  MeResponse? _profile;
  String? _errorMessage;
  bool _initializedOnce = false;

  bool get isInitializing => _isInitializing;
  bool get isSubmitting => _isSubmitting;
  bool get isAuthenticated => _isAuthenticated;
  MeResponse? get profile => _profile;
  String? get errorMessage => _errorMessage;

  Future<void> initializeSession() async {
    if (_initializedOnce) return;
    _initializedOnce = true;

    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    final token = _prefs.getString(AppStorageKeys.tokenDosen);
    if (token == null || token.isEmpty) {
      _isAuthenticated = false;
      _isInitializing = false;
      notifyListeners();
      return;
    }

    try {
      final me = await _authService.getMe();
      _profile = me;
      _isAuthenticated = true;
    } on ApiException catch (error) {
      final shouldClearSession =
          error.statusCode == 401 ||
          error.statusCode == 403 ||
          error.statusCode == 500;

      if (shouldClearSession) {
        await _apiClient.clearSession();
      }

      _isAuthenticated = false;
      _profile = null;
      _errorMessage = error.message;
    } catch (_) {
      _isAuthenticated = false;
      _profile = null;
      _errorMessage = 'Tidak dapat memvalidasi sesi. Silakan login kembali.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithCredentials({
    required String nidn,
    required String password,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginResponse = await _authService.login(
        nidn: nidn,
        password: password,
      );

      if (loginResponse.token.isEmpty) {
        _isAuthenticated = false;
        _errorMessage = 'Token login tidak valid.';
        return false;
      }

      await _prefs.setString(AppStorageKeys.tokenDosen, loginResponse.token);
      await _prefs.setString(AppStorageKeys.loginDosen, loginResponse.login);

      _profile = MeResponse(
        login: loginResponse.login,
        nidn: loginResponse.nidn,
        nama: loginResponse.nama,
        gelar: '',
        handphone: '',
        email: '',
        foto: loginResponse.foto,
        prodi: '',
      );
      await _prefs.setString(
        AppStorageKeys.profileDosenJson,
        jsonEncode({
          'login': _profile?.login ?? '',
          'nidn': _profile?.nidn ?? '',
          'nama': _profile?.nama ?? '',
          'gelar': _profile?.gelar ?? '',
          'handphone': _profile?.handphone ?? '',
          'email': _profile?.email ?? '',
          'foto': _profile?.foto ?? '',
          'prodi': _profile?.prodi ?? '',
        }),
      );

      _isAuthenticated = true;
      return true;
    } on ApiException catch (error) {
      _isAuthenticated = false;
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _isAuthenticated = false;
      _errorMessage = 'Tidak dapat login. Periksa koneksi lalu coba lagi.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
