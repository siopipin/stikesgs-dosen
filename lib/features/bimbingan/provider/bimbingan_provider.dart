import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../model/bimbingan_student_item.dart';
import '../service/bimbingan_service.dart';

class BimbinganProvider extends ChangeNotifier {
  BimbinganProvider(this._service);

  final BimbinganService _service;

  bool _initialized = false;
  bool _isLoading = false;
  bool _isActionLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<BimbinganStudentItem> _students = <BimbinganStudentItem>[];
  BimbinganStudentItem? _selectedStudent;
  List<BimbinganLogItem> _logs = <BimbinganLogItem>[];

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<BimbinganStudentItem> get students => _students;
  BimbinganStudentItem? get selectedStudent => _selectedStudent;
  List<BimbinganLogItem> get logs => _logs;

  Future<void> ensureLoaded() async {
    if (_initialized) return;
    _initialized = true;
    await refreshAll();
  }

  Future<void> refreshAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _service.getStudents();
      final selectedId = _selectedStudent?.mhswId;
      if (selectedId != null && selectedId.isNotEmpty) {
        _selectedStudent = _students.where((e) => e.mhswId == selectedId).firstOrNull;
      }
      _selectedStudent ??= _students.isNotEmpty ? _students.first : null;
      await loadLogs();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Data bimbingan belum dapat dimuat.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectStudent(BimbinganStudentItem student) async {
    _selectedStudent = student;
    _logs = <BimbinganLogItem>[];
    notifyListeners();
    await loadLogs();
  }

  Future<void> loadLogs() async {
    final student = _selectedStudent;
    if (student == null || student.mhswId.isEmpty) {
      _logs = <BimbinganLogItem>[];
      notifyListeners();
      return;
    }

    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logs = await _service.getLogs(mhswId: student.mhswId);
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Log bimbingan gagal dimuat.';
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createLog(BimbinganLogDraft draft) async {
    final student = _selectedStudent;
    if (student == null || student.mhswId.isEmpty) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createLog(
        mhswId: student.mhswId,
        draft: draft,
      );
      await loadLogs();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Tambah log bimbingan gagal.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateLog({
    required BimbinganLogItem item,
    required BimbinganLogDraft draft,
  }) async {
    if (item.id == 0) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateLog(
        logId: item.id,
        draft: draft,
      );
      await loadLogs();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Ubah log bimbingan gagal.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteLog(BimbinganLogItem item) async {
    if (item.id == 0) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteLog(logId: item.id);
      _logs = _logs.where((e) => e.id != item.id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Hapus log bimbingan gagal.';
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
