class PresensiAttendanceItem {
  PresensiAttendanceItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.statusCode,
    required this.raw,
  });

  final String id;
  final String studentId;
  final String studentName;
  /// H=Hadir, M=Mangkir, I=Izin, S=Sakit
  final String statusCode;
  final Map<String, dynamic> raw;

  factory PresensiAttendanceItem.fromJson(Map<String, dynamic> json) {
    final studentName = _firstNonEmpty([
      json['nama'],
      json['Nama'],
      json['nama_mhs'],
      json['NamaMhsw'],
    ]);
    final studentId = _firstNonEmpty([
      json['mhsw_id'],
      json['MhswID'],
      json['nim'],
      json['NIM'],
    ]);
    final id = _firstNonEmpty([
      json['PresensiMhswID'],
      json['presensi_mhsw_id'],
      json['krs_id'],
      json['KRSID'],
      json['krsid'],
      json['id'],
    ]);

    final statusValue = json['JenisPresensiID'] ??
        json['jenis_presensi_id'] ??
        json['jenisPresensiId'] ??
        json['status_huruf'] ??
        json['status_hadir'] ??
        json['StatusHadir'] ??
        json['status'] ??
        json['hadir'] ??
        'M';

    return PresensiAttendanceItem(
      id: id,
      studentId: studentId,
      studentName: studentName.isEmpty ? 'Mahasiswa' : studentName,
      statusCode: _toStatusCode(statusValue),
      raw: json,
    );
  }

  PresensiAttendanceItem copyWith({
    String? statusCode,
  }) {
    return PresensiAttendanceItem(
      id: id,
      studentId: studentId,
      studentName: studentName,
      statusCode: statusCode ?? this.statusCode,
      raw: raw,
    );
  }

  bool get isPresent => statusCode == 'H';

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _toStatusCode(dynamic value) {
    if (value is int) return value == 1 ? 'H' : 'M';
    if (value is String) {
      final normalized = value.trim().toUpperCase();
      if (normalized == 'H' ||
          normalized == 'M' ||
          normalized == 'I' ||
          normalized == 'S') {
        return normalized;
      }
      // Backward compatibility: backend lama pakai A (Absen).
      if (normalized == 'A' || normalized == 'ABSEN') {
        return 'M';
      }
      if (normalized == '1' || normalized == 'TRUE' || normalized == 'HADIR') {
        return 'H';
      }
    }
    if (value is bool) return value ? 'H' : 'M';
    return 'M';
  }
}
