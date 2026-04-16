class PresensiAttendanceItem {
  PresensiAttendanceItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.isPresent,
    required this.raw,
  });

  final String id;
  final String studentId;
  final String studentName;
  final bool isPresent;
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
      json['krs_id'],
      json['KRSID'],
      json['krsid'],
      json['id'],
    ]);

    final statusValue = json['status_hadir'] ??
        json['StatusHadir'] ??
        json['status'] ??
        json['hadir'] ??
        0;

    return PresensiAttendanceItem(
      id: id,
      studentId: studentId,
      studentName: studentName.isEmpty ? 'Mahasiswa' : studentName,
      isPresent: _toBool(statusValue),
      raw: json,
    );
  }

  PresensiAttendanceItem copyWith({
    bool? isPresent,
  }) {
    return PresensiAttendanceItem(
      id: id,
      studentId: studentId,
      studentName: studentName,
      isPresent: isPresent ?? this.isPresent,
      raw: raw,
    );
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == '1' ||
          normalized == 'true' ||
          normalized == 'hadir' ||
          normalized == 'h';
    }
    return false;
  }
}
