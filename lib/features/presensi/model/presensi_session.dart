import 'presensi_attendance_item.dart';

class PresensiSession {
  PresensiSession({
    required this.presensiId,
    required this.jadwalId,
    required this.dosenId,
    required this.qrSessionToken,
    required this.status,
    required this.startedAt,
    required this.raw,
    this.pertemuanKe,
  });

  final int presensiId;
  final int jadwalId;
  final String dosenId;
  final String qrSessionToken;
  final String status;
  final DateTime? startedAt;
  final Map<String, dynamic> raw;
  /// Nomor pertemuan dari backend (jika ada).
  final int? pertemuanKe;

  bool get canEditAttendance => status.toUpperCase() == 'OPEN';

  /// Cocok dengan pertemuan yang dipilih; jika backend tidak mengirim nomor pertemuan, anggap sama dengan sesi aktif tunggal.
  bool matchesPertemuan(int selectedPertemuan) {
    final p = pertemuanKe;
    if (p == null || p < 1) return true;
    return p == selectedPertemuan;
  }

  factory PresensiSession.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return PresensiSession(
      presensiId: _toInt(data['presensi_id']),
      jadwalId: _toInt(data['jadwal_id']),
      dosenId: (data['dosen_id'] ?? '').toString(),
      qrSessionToken: (data['qr_session_token'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      startedAt: _toDateTime(
        data['started_at'] ?? data['created_at'] ?? data['waktu_mulai'],
      ),
      pertemuanKe: _optionalPertemuan(
        data['pertemuan'] ?? data['Pertemuan'] ?? data['no_pertemuan'],
      ),
      raw: data,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static int? _optionalPertemuan(dynamic value) {
    final n = _toInt(value);
    return n > 0 ? n : null;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

/// Dua sudut pandang dari GET `presensi/aktif`: sesi terbuka (QR) vs konteks pertemuan untuk kehadiran.
class PresensiAktifContext {
  const PresensiAktifContext({
    this.openSession,
    this.meetingSession,
    this.isPresensiSudahDilakukan = false,
    this.totalMahasiswa = 0,
    this.meetingStudents = const <PresensiAttendanceItem>[],
  });

  /// Sesi berstatus OPEN untuk jadwal ini (token QR / tutup manual).
  final PresensiSession? openSession;

  /// Presensi untuk pertemuan yang dipilih (bisa sudah ditutup), dipakai untuk GET kehadiran.
  final PresensiSession? meetingSession;

  /// Flag backend: pertemuan ini sudah pernah dilakukan presensi.
  final bool isPresensiSudahDilakukan;

  /// Total mahasiswa untuk pertemuan terpilih.
  final int totalMahasiswa;

  /// List mahasiswa dari endpoint `presensi/aktif` (tiap pertemuan terpilih).
  final List<PresensiAttendanceItem> meetingStudents;
}
