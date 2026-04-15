class DashboardSummary {
  DashboardSummary({
    required this.login,
    required this.nama,
    required this.foto,
    required this.tahunId,
    required this.jumlahJadwalHariIni,
    required this.totalSksSemester,
    required this.jumlahMhsBimbingan,
    required this.jumlahNotifAkademik,
  });

  final String login;
  final String nama;
  final String foto;
  final String tahunId;
  final int jumlahJadwalHariIni;
  final int totalSksSemester;
  final int jumlahMhsBimbingan;
  final int jumlahNotifAkademik;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final profil = (data['profil'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final ringkasan =
        (data['ringkasan'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return DashboardSummary(
      login: (profil['login'] ?? '').toString(),
      nama: (profil['nama'] ?? '').toString(),
      foto: (profil['foto'] ?? '').toString(),
      tahunId: (ringkasan['tahunid'] ?? '').toString(),
      jumlahJadwalHariIni: _toInt(ringkasan['jumlah_jadwal_hari_ini']),
      totalSksSemester: _toInt(ringkasan['total_sks_semester']),
      jumlahMhsBimbingan: _toInt(ringkasan['jumlah_mhs_bimbingan']),
      jumlahNotifAkademik: _toInt(ringkasan['jumlah_notif_akademik']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }
}
