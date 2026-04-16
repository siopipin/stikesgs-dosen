class NotifikasiItem {
  NotifikasiItem({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.isRead,
    required this.createdAt,
    required this.raw,
  });

  final int id;
  final String judul;
  final String pesan;
  final bool isRead;
  final String createdAt;
  final Map<String, dynamic> raw;

  factory NotifikasiItem.fromJson(Map<String, dynamic> json) {
    final judul = _firstNonEmpty([
      json['judul'],
      json['title'],
      json['nama'],
      json['subject'],
    ]);
    final pesan = _firstNonEmpty([
      json['pesan'],
      json['message'],
      json['isi'],
      json['keterangan'],
      judul,
    ]);

    return NotifikasiItem(
      id: _toInt(json['id'] ?? json['ID']),
      judul: judul.isEmpty ? 'Notifikasi Akademik' : judul,
      pesan: pesan.isEmpty ? 'Tidak ada detail notifikasi.' : pesan,
      isRead: _toInt(json['status']) == 1,
      createdAt: _firstNonEmpty([
        json['TanggalBuat'],
        json['tanggal_buat'],
        json['created_at'],
        json['waktu'],
      ]),
      raw: json,
    );
  }

  NotifikasiItem copyWith({
    bool? isRead,
  }) {
    return NotifikasiItem(
      id: id,
      judul: judul,
      pesan: pesan,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
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

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
