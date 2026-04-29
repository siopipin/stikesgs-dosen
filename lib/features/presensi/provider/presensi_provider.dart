import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../dashboard/model/teaching_schedule_item.dart';
import '../model/presensi_attendance_item.dart';
import '../model/presensi_session.dart';
import '../service/presensi_service.dart';

class PresensiProvider extends ChangeNotifier {
  PresensiProvider(this._service);

  final PresensiService _service;

  bool _isLoading = false;
  bool _isActionLoading = false;
  bool _initialized = false;
  String? _errorMessage;
  List<TeachingScheduleItem> _schedules = <TeachingScheduleItem>[];
  TeachingScheduleItem? _selectedSchedule;
  PresensiSession? _openSession;
  PresensiSession? _meetingSession;
  List<PresensiAttendanceItem> _attendance = <PresensiAttendanceItem>[];
  bool _isPresensiSudahDilakukan = false;
  int _totalMahasiswa = 0;
  int _pertemuan = 1;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  List<TeachingScheduleItem> get schedules => _schedules;
  TeachingScheduleItem? get selectedSchedule => _selectedSchedule;

  /// Sesi OPEN (token QR / tutup manual).
  PresensiSession? get openSession => _openSession;

  /// Konteks presensi untuk jadwal + pertemuan terpilih (bisa CLOSED), untuk daftar kehadiran.
  PresensiSession? get meetingSession => _meetingSession;

  List<PresensiAttendanceItem> get attendance => _attendance;
  bool get isPresensiSudahDilakukan => _isPresensiSudahDilakukan;
  int get totalMahasiswa => _totalMahasiswa;
  int get pertemuan => _pertemuan;
  bool get canEditAttendance => _meetingSession?.canEditAttendance ?? false;
  bool get canStartSession =>
      _openSession == null &&
      _selectedSchedule != null &&
      !_isActionLoading &&
      !_isPresensiSudahDilakukan;

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
      _schedules = await _service.getTeachingSchedule();
      _selectedSchedule ??= _schedules.isNotEmpty ? _schedules.first : null;
      await _syncPresensiContext(showBlockingSpinner: true);
      await _loadAttendanceIfPossible();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Data presensi belum dapat dimuat.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectSchedule(TeachingScheduleItem schedule) async {
    _selectedSchedule = schedule;
    _openSession = null;
    _meetingSession = null;
    _attendance = <PresensiAttendanceItem>[];
    _isPresensiSudahDilakukan = false;
    _totalMahasiswa = 0;
    notifyListeners();
    await _syncPresensiContext(showBlockingSpinner: true);
    await _loadAttendanceIfPossible();
  }

  Future<void> setPertemuan(int value) async {
    if (value < 1) return;
    _pertemuan = value;
    notifyListeners();
    await _syncPresensiContext(showBlockingSpinner: false);
    await _loadAttendanceIfPossible();
  }

  Future<void> checkActiveSession() async {
    await _syncPresensiContext(showBlockingSpinner: true);
    await _loadAttendanceIfPossible();
  }

  Future<void> _syncPresensiContext({required bool showBlockingSpinner}) async {
    final schedule = _selectedSchedule;
    if (schedule == null) {
      _openSession = null;
      _meetingSession = null;
      _isPresensiSudahDilakukan = false;
      _totalMahasiswa = 0;
      _attendance = <PresensiAttendanceItem>[];
      notifyListeners();
      return;
    }

    if (showBlockingSpinner) {
      _isActionLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final ctx = await _service.fetchAktifContext(
        jadwalId: schedule.jadwalId,
        pertemuan: _pertemuan,
      );
      _openSession = ctx.openSession;
      _meetingSession = ctx.meetingSession;
      _isPresensiSudahDilakukan = ctx.isPresensiSudahDilakukan;
      _totalMahasiswa = ctx.totalMahasiswa;
      _attendance = ctx.meetingStudents;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Gagal memuat status presensi.';
    } finally {
      if (showBlockingSpinner) {
        _isActionLoading = false;
      }
      notifyListeners();
    }
  }

  /// `presensi/aktif` mengembalikan roster lengkap per pertemuan; `presensi/{id}/kehadiran`
  /// seringkali hanya baris yang sudah tercatat. Jangan mengganti roster dengan daftar parsial.
  Future<void> _loadAttendanceIfPossible() async {
    final id = _meetingSession?.presensiId;
    if (id == null || id == 0) {
      return;
    }
    if (_attendance.isNotEmpty) {
      await _mergeKehadiranFromServer(presensiId: id);
      return;
    }
    await loadAttendance();
  }

  /// Sinkron ulang dari `aktif`, lalu overlay detail dari endpoint kehadiran bila ada.
  Future<void> refreshAttendance() async {
    await _syncPresensiContext(showBlockingSpinner: false);
    await _loadAttendanceIfPossible();
  }

  Future<void> _mergeKehadiranFromServer({required int presensiId}) async {
    try {
      final rows = await _service.getAttendance(presensiId: presensiId);
      if (rows.isEmpty) return;

      final byStudent = <String, PresensiAttendanceItem>{};
      for (final r in rows) {
        final key = r.studentId.trim();
        if (key.isNotEmpty) {
          byStudent[key] = r;
        }
      }

      final merged = _attendance.map((item) {
        final key = item.studentId.trim();
        final k = key.isEmpty ? null : byStudent[key];
        if (k == null) return item;
        return item.copyWith(
          id: k.id.isNotEmpty ? k.id : item.id,
          statusCode: k.statusCode,
          raw: k.raw,
        );
      }).toList();

      final existingIds = merged.map((e) => e.studentId.trim()).toSet();
      for (final r in rows) {
        final sid = r.studentId.trim();
        if (sid.isNotEmpty && !existingIds.contains(sid)) {
          merged.add(r);
          existingIds.add(sid);
        }
      }

      _attendance = merged;
      notifyListeners();
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Gagal memuat data kehadiran.';
      notifyListeners();
    }
  }

  Future<bool> startSession() async {
    final schedule = _selectedSchedule;
    if (schedule == null) {
      _errorMessage = 'Pilih jadwal terlebih dahulu.';
      notifyListeners();
      return false;
    }
    if (_isPresensiSudahDilakukan) {
      _errorMessage = 'Pertemuan ini sudah dilakukan presensi, sesi baru tidak dapat dimulai.';
      notifyListeners();
      return false;
    }

    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final started = await _service.startSession(
        jadwalId: schedule.jadwalId,
        pertemuan: _pertemuan,
      );
      _meetingSession = started;
      _openSession = started;
      await _syncPresensiContext(showBlockingSpinner: false);
      await _loadAttendanceIfPossible();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Gagal memulai sesi presensi.';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> endSession() async {
    final current = _openSession;
    if (current == null) return false;

    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.endSession(presensiId: current.presensiId);
      final closed = current.copyWithStatus('CLOSED');
      _openSession = null;
      if (_meetingSession?.presensiId == current.presensiId) {
        _meetingSession = closed;
      }
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Gagal menutup sesi presensi.';
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAttendance() async {
    final id = _meetingSession?.presensiId;
    if (id == null || id == 0) return;

    try {
      _attendance = await _service.getAttendance(presensiId: id);
      notifyListeners();
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Gagal memuat data kehadiran.';
      notifyListeners();
    }
  }

  Future<bool> updateAttendance({
    required PresensiAttendanceItem item,
    required String statusCode,
  }) async {
    final currentSession = _meetingSession;
    if (currentSession == null || !currentSession.canEditAttendance) return false;

    final index = _attendance.indexWhere(
      (element) => element.studentId == item.studentId,
    );
    if (index == -1) return false;

    final normalizedStatus = statusCode.trim().toUpperCase();
    final oldValue = _attendance[index];
    _attendance[index] = oldValue.copyWith(statusCode: normalizedStatus);
    notifyListeners();

    try {
      await _service.updateAttendance(
        presensiId: currentSession.presensiId,
        item: item,
        statusCode: normalizedStatus,
      );
      return true;
    } on ApiException catch (error) {
      _attendance[index] = oldValue;
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _attendance[index] = oldValue;
      _errorMessage = 'Gagal memperbarui kehadiran.';
      notifyListeners();
      return false;
    }
  }
}

extension on PresensiSession {
  PresensiSession copyWithStatus(String status) {
    return PresensiSession(
      presensiId: presensiId,
      jadwalId: jadwalId,
      dosenId: dosenId,
      qrSessionToken: qrSessionToken,
      status: status,
      startedAt: startedAt,
      raw: raw,
      pertemuanKe: pertemuanKe,
    );
  }
}
