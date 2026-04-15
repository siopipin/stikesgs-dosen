class TeachingScheduleItem {
  TeachingScheduleItem({
    required this.jadwalId,
    required this.namaMk,
    required this.namaHari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.ruang,
    required this.sks,
  });

  final int jadwalId;
  final String namaMk;
  final String namaHari;
  final String jamMulai;
  final String jamSelesai;
  final String ruang;
  final int sks;

  factory TeachingScheduleItem.fromJson(Map<String, dynamic> json) {
    return TeachingScheduleItem(
      jadwalId: _toInt(json['JadwalID']),
      namaMk: (json['nama_mk'] ?? '').toString(),
      namaHari: (json['nama_hari'] ?? '').toString(),
      jamMulai: (json['jam_mulai'] ?? '').toString(),
      jamSelesai: (json['jam_selesai'] ?? '').toString(),
      ruang: (json['RuangID'] ?? json['ruang'] ?? '-').toString(),
      sks: _toInt(json['SKS']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }
}
