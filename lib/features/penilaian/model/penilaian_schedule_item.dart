class PenilaianScheduleItem {
  PenilaianScheduleItem({
    required this.jadwalId,
    required this.namaMk,
    required this.kelas,
    required this.namaHari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.jenisDosenId,
    required this.raw,
  });

  final int jadwalId;
  final String namaMk;
  final String kelas;
  final String namaHari;
  final String jamMulai;
  final String jamSelesai;
  /// Rule backend: hanya `DSN` (koordinator) yang boleh input nilai.
  final String jenisDosenId;
  final Map<String, dynamic> raw;

  bool get isCoordinator => jenisDosenId.toUpperCase() == 'DSN';

  factory PenilaianScheduleItem.fromJson(Map<String, dynamic> json) {
    final nestedJadwalDosen =
        (json['jadwaldosen'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return PenilaianScheduleItem(
      jadwalId: _toInt(json['JadwalID'] ?? json['jadwal_id']),
      namaMk: _toText([
        json['nama_mk'],
        json['NamaMK'],
        json['MKNama'],
      ]),
      kelas: _toText([
        json['NamaKelas'],
        json['KelasID'],
        json['kelas'],
      ]),
      namaHari: _toText([
        json['nama_hari'],
        json['NamaHari'],
      ]),
      jamMulai: _toText([
        json['jam_mulai'],
        json['JamMulai'],
      ]),
      jamSelesai: _toText([
        json['jam_selesai'],
        json['JamSelesai'],
      ]),
      jenisDosenId: _toText([
        nestedJadwalDosen['JenisDosenID'],
        json['JenisDosenID'],
        json['jenis_dosen_id'],
      ]),
      raw: json,
    );
  }

  String get displayLabel {
    final time = (jamMulai.isEmpty && jamSelesai.isEmpty)
        ? ''
        : ' • $jamMulai-$jamSelesai';
    final kelasPart = kelas.isEmpty ? '' : ' • $kelas';
    return '$namaMk$kelasPart$time';
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _toText(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
