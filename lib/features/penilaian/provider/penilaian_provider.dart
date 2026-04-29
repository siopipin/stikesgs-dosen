import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../model/penilaian_schedule_item.dart';
import '../model/penilaian_student_item.dart';
import '../service/penilaian_service.dart';

class PenilaianProvider extends ChangeNotifier {
  PenilaianProvider(this._service);

  final PenilaianService _service;

  bool _initialized = false;
  bool _isLoading = false;
  bool _isActionLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  String _tahunId = '';
  List<PenilaianScheduleItem> _schedules = <PenilaianScheduleItem>[];
  PenilaianScheduleItem? _selectedSchedule;
  List<PenilaianStudentItem> _students = <PenilaianStudentItem>[];

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get tahunId => _tahunId;
  List<PenilaianScheduleItem> get schedules => _schedules;
  PenilaianScheduleItem? get selectedSchedule => _selectedSchedule;
  List<PenilaianStudentItem> get students => _students;

  bool get canEditScores {
    final schedule = _selectedSchedule;
    if (schedule == null) return false;
    if (schedule.jenisDosenId.isEmpty) return true;
    return schedule.isCoordinator;
  }

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
      if (_tahunId.trim().isEmpty) {
        _tahunId = await _service.getDefaultTahunId();
      }
      await _loadSchedulesInternal();
      await loadStudents();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Data penilaian belum dapat dimuat.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTahunId(String value) {
    _tahunId = value.trim();
    notifyListeners();
  }

  Future<void> loadSchedules() async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _loadSchedulesInternal();
      await loadStudents();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Jadwal penilaian gagal dimuat.';
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSchedulesInternal() async {
    if (_tahunId.isEmpty) {
      _schedules = <PenilaianScheduleItem>[];
      _selectedSchedule = null;
      _students = <PenilaianStudentItem>[];
      return;
    }

    final currentSelectedId = _selectedSchedule?.jadwalId;
    _schedules = _uniqueByJadwalId(
      await _service.getSchedules(tahunId: _tahunId),
    );

    if (_schedules.isEmpty) {
      _selectedSchedule = null;
      _students = <PenilaianStudentItem>[];
      return;
    }

    if (currentSelectedId != null) {
      _selectedSchedule = _schedules.where((e) => e.jadwalId == currentSelectedId).firstOrNull;
    }
    _selectedSchedule ??= _schedules.first;
  }

  Future<void> selectSchedule(PenilaianScheduleItem item) async {
    _selectedSchedule = item;
    _students = <PenilaianStudentItem>[];
    notifyListeners();
    await loadStudents();
  }

  Future<void> loadStudents() async {
    final schedule = _selectedSchedule;
    if (schedule == null) {
      _students = <PenilaianStudentItem>[];
      notifyListeners();
      return;
    }

    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _service.getStudents(jadwalId: schedule.jadwalId);
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Data mahasiswa penilaian gagal dimuat.';
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveScores({
    required PenilaianStudentItem student,
    required NilaiDraft draft,
  }) async {
    if (!canEditScores) {
      _errorMessage = 'Input nilai hanya untuk dosen koordinator (DSN).';
      notifyListeners();
      return false;
    }

    final index = _students.indexWhere((e) => e.krsId == student.krsId);
    if (index == -1) return false;

    _isSaving = true;
    _errorMessage = null;

    final oldValue = _students[index];
    final merged = draft.resolvedAgainst(oldValue);
    _students[index] = oldValue.copyWith(
      tugas1: merged.tugas1,
      tugas2: merged.tugas2,
      tugas3: merged.tugas3,
      tugas4: merged.tugas4,
      tugas5: merged.tugas5,
      uts: merged.uts,
      uas: merged.uas,
    );
    notifyListeners();

    try {
      await _service.updateNilai(
        draft: draft,
        krsId: student.krsId,
        existing: student,
      );
      return true;
    } on ApiException catch (error) {
      _students[index] = oldValue;
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _students[index] = oldValue;
      _errorMessage = 'Simpan nilai gagal. Silakan coba lagi.';
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
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

List<PenilaianScheduleItem> _uniqueByJadwalId(
  List<PenilaianScheduleItem> source,
) {
  final seen = <int>{};
  final result = <PenilaianScheduleItem>[];
  for (final item in source) {
    if (item.jadwalId == 0) continue;
    if (seen.contains(item.jadwalId)) continue;
    seen.add(item.jadwalId);
    result.add(item);
  }
  return result;
}
