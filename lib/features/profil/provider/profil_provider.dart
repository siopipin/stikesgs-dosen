import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../model/profil_response.dart';
import '../service/profil_service.dart';

class ProfilProvider extends ChangeNotifier {
  ProfilProvider(this._service);

  final ProfilService _service;
  final ImagePicker _imagePicker = ImagePicker();

  ProfilResponse? _profil;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _initialized = false;

  ProfilResponse? get profil => _profil;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> ensureLoaded() async {
    if (_initialized) return;
    _initialized = true;
    await loadProfil();
  }

  Future<void> loadProfil() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profil = await _service.getProfil();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Profil belum dapat dimuat.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfil({
    required String email,
    required String handphone,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.updateProfil(
        email: email,
        handphone: handphone,
      );

      _profil = _profil?.copyWith(
            email: updated.email,
            handphone: updated.handphone,
          ) ??
          updated;
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Gagal memperbarui profil.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updatePassword({
    required String passwordLama,
    required String passwordBaru,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updatePassword(
        passwordLama: passwordLama,
        passwordBaru: passwordBaru,
      );
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Gagal memperbarui password.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> pickAndUploadPhoto() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return false;

    final extension = file.path.toLowerCase();
    final isValidFormat =
        extension.endsWith('.jpg') || extension.endsWith('.jpeg') || extension.endsWith('.png');
    if (!isValidFormat) {
      _errorMessage = 'Format foto harus JPG/JPEG/PNG.';
      notifyListeners();
      return false;
    }

    final length = await File(file.path).length();
    final maxSize = 2 * 1024 * 1024;
    if (length > maxSize) {
      _errorMessage = 'Ukuran foto maksimal 2MB.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateFoto(filePath: file.path);
      await loadProfil();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Gagal mengunggah foto profil.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
