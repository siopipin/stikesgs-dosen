import '../../../core/network/api_client.dart';
import '../model/notifikasi_item.dart';

class NotifikasiService {
  NotifikasiService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<NotifikasiItem>> getNotifications() async {
    final response = await _apiClient.get('notifikasi');
    final data = response['data'];

    if (data is List<dynamic>) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(NotifikasiItem.fromJson)
          .where((e) => e.id != 0)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final list = data['notifikasi'] ?? data['list'] ?? data['items'];
      if (list is List<dynamic>) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(NotifikasiItem.fromJson)
            .where((e) => e.id != 0)
            .toList();
      }
    }

    return <NotifikasiItem>[];
  }

  Future<int> getUnreadTotal() async {
    final response = await _apiClient.get('notifikasi/total');
    final data = response['data'];

    if (data is int) return data;
    if (data is String) return int.tryParse(data) ?? 0;
    if (data is Map<String, dynamic>) {
      return _toInt(
        data['total'] ?? data['unread'] ?? data['jumlah'] ?? data['count'],
      );
    }
    return 0;
  }

  Future<void> markAsRead({
    required int id,
  }) async {
    await _apiClient.put(
      'notifikasi/baca',
      body: <String, dynamic>{'id': id},
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
