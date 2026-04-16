class BimbinganStudentItem {
  BimbinganStudentItem({
    required this.mhswId,
    required this.npm,
    required this.nama,
    required this.prodi,
    required this.raw,
  });

  final String mhswId;
  final String npm;
  final String nama;
  final String prodi;
  final Map<String, dynamic> raw;

  factory BimbinganStudentItem.fromJson(Map<String, dynamic> json) {
    return BimbinganStudentItem(
      mhswId: _firstNonEmpty([
        json['mhsw_id'],
        json['MhswID'],
        json['MhswId'],
      ]),
      npm: _firstNonEmpty([
        json['npm'],
        json['NPM'],
      ]),
      nama: _firstNonEmpty([
        json['nama'],
        json['Nama'],
      ]),
      prodi: _firstNonEmpty([
        json['prodi'],
        json['Prodi'],
        json['NamaProdi'],
      ]),
      raw: json,
    );
  }

  String get displayName => nama.isEmpty ? 'Mahasiswa' : nama;

  String get displayNpm => npm.isNotEmpty ? npm : mhswId;

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

class BimbinganLogItem {
  BimbinganLogItem({
    required this.id,
    required this.mhswId,
    required this.tanggalKonsultasi,
    required this.tema,
    required this.ringkasan,
    required this.hasil,
    required this.raw,
  });

  final int id;
  final String mhswId;
  final String tanggalKonsultasi;
  final String tema;
  final String ringkasan;
  final String hasil;
  final Map<String, dynamic> raw;

  factory BimbinganLogItem.fromJson(Map<String, dynamic> json) {
    return BimbinganLogItem(
      id: _toInt(json['id'] ?? json['ID']),
      mhswId: _firstNonEmpty([
        json['mhsw_id'],
        json['MhswID'],
      ]),
      tanggalKonsultasi: _firstNonEmpty([
        json['tanggal_konsultasi'],
        json['TanggalKonsultasi'],
        json['tanggal'],
      ]),
      tema: _firstNonEmpty([
        json['tema'],
        json['Tema'],
      ]),
      ringkasan: _firstNonEmpty([
        json['ringkasan'],
        json['Ringkasan'],
      ]),
      hasil: _firstNonEmpty([
        json['hasil'],
        json['Hasil'],
      ]),
      raw: json,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

class BimbinganLogDraft {
  const BimbinganLogDraft({
    required this.tanggalKonsultasi,
    required this.tema,
    required this.ringkasan,
    required this.hasil,
  });

  final String tanggalKonsultasi;
  final String tema;
  final String ringkasan;
  final String hasil;

  Map<String, dynamic> toCreateBody(String mhswId) {
    return <String, dynamic>{
      'mhsw_id': mhswId,
      'tanggal_konsultasi': tanggalKonsultasi,
      'tema': tema,
      'ringkasan': ringkasan,
      'hasil': hasil,
    };
  }

  Map<String, dynamic> toUpdateBody() {
    return <String, dynamic>{
      'tanggal_konsultasi': tanggalKonsultasi,
      'tema': tema,
      'ringkasan': ringkasan,
      'hasil': hasil,
    };
  }
}
