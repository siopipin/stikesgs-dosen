class AnnouncementItem {
  AnnouncementItem({
    required this.id,
    required this.title,
    required this.isRead,
  });

  final String id;
  final String title;
  final bool isRead;

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    final title = _firstNonEmpty([
      json['judul'],
      json['title'],
      json['pesan'],
      json['message'],
      json['isi'],
      json['keterangan'],
      json['notif'],
      json['nama'],
    ]);

    return AnnouncementItem(
      id: (json['id'] ?? '').toString(),
      title: title.isEmpty ? 'Informasi akademik terbaru' : title,
      isRead: _toInt(json['status']) == 1,
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
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }
}
