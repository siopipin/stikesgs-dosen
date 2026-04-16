class PenilaianStudentItem {
  PenilaianStudentItem({
    required this.krsId,
    required this.mhswId,
    required this.npm,
    required this.nama,
    required this.tugas1,
    required this.tugas2,
    required this.tugas3,
    required this.tugas4,
    required this.tugas5,
    required this.uts,
    required this.uas,
    required this.raw,
  });

  final int krsId;
  final String mhswId;
  final String npm;
  final String nama;
  final int? tugas1;
  final int? tugas2;
  final int? tugas3;
  final int? tugas4;
  final int? tugas5;
  final int? uts;
  final int? uas;
  final Map<String, dynamic> raw;

  factory PenilaianStudentItem.fromJson(Map<String, dynamic> json) {
    return PenilaianStudentItem(
      krsId: _toInt(json['krs_id'] ?? json['KRSID'] ?? json['KrsID']),
      mhswId: _toText([
        json['mhsw_id'],
        json['MhswID'],
      ]),
      npm: _toText([
        json['npm'],
        json['NPM'],
      ]),
      nama: _toText([
        json['nama'],
        json['Nama'],
        json['nama_mhs'],
      ]),
      tugas1: _toNullableInt(json['tugas1']),
      tugas2: _toNullableInt(json['tugas2']),
      tugas3: _toNullableInt(json['tugas3']),
      tugas4: _toNullableInt(json['tugas4']),
      tugas5: _toNullableInt(json['tugas5']),
      uts: _toNullableInt(json['uts']),
      uas: _toNullableInt(json['uas']),
      raw: json,
    );
  }

  PenilaianStudentItem copyWith({
    int? tugas1,
    int? tugas2,
    int? tugas3,
    int? tugas4,
    int? tugas5,
    int? uts,
    int? uas,
  }) {
    return PenilaianStudentItem(
      krsId: krsId,
      mhswId: mhswId,
      npm: npm,
      nama: nama,
      tugas1: tugas1 ?? this.tugas1,
      tugas2: tugas2 ?? this.tugas2,
      tugas3: tugas3 ?? this.tugas3,
      tugas4: tugas4 ?? this.tugas4,
      tugas5: tugas5 ?? this.tugas5,
      uts: uts ?? this.uts,
      uas: uas ?? this.uas,
      raw: raw,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isEmpty) return null;
    return _toInt(value);
  }

  static String _toText(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

class NilaiDraft {
  const NilaiDraft({
    required this.tugas1,
    required this.tugas2,
    required this.tugas3,
    required this.tugas4,
    required this.tugas5,
    required this.uts,
    required this.uas,
  });

  final int tugas1;
  final int tugas2;
  final int tugas3;
  final int tugas4;
  final int tugas5;
  final int uts;
  final int uas;

  Map<String, dynamic> toBody(int krsId) {
    return <String, dynamic>{
      'krs_id': krsId,
      'tugas1': tugas1,
      'tugas2': tugas2,
      'tugas3': tugas3,
      'tugas4': tugas4,
      'tugas5': tugas5,
      'uts': uts,
      'uas': uas,
    };
  }
}
