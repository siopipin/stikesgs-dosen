import '../../../core/network/api_client.dart';
import '../model/bimbingan_student_item.dart';

class BimbinganService {
  BimbinganService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<BimbinganStudentItem>> getStudents() async {
    final response = await _apiClient.get('bimbingan/mahasiswa');
    final data = response['data'];

    if (data is List<dynamic>) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(BimbinganStudentItem.fromJson)
          .where((item) => item.mhswId.isNotEmpty)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final list = data['mahasiswa'] ?? data['list'] ?? data['items'];
      if (list is List<dynamic>) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(BimbinganStudentItem.fromJson)
            .where((item) => item.mhswId.isNotEmpty)
            .toList();
      }
    }

    return <BimbinganStudentItem>[];
  }

  Future<List<BimbinganLogItem>> getLogs({
    required String mhswId,
  }) async {
    final response = await _apiClient.get('bimbingan/log/$mhswId');
    final data = response['data'];

    if (data is List<dynamic>) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(BimbinganLogItem.fromJson)
          .where((item) => item.id != 0)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final list = data['log'] ?? data['list'] ?? data['items'];
      if (list is List<dynamic>) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(BimbinganLogItem.fromJson)
            .where((item) => item.id != 0)
            .toList();
      }
    }

    return <BimbinganLogItem>[];
  }

  Future<void> createLog({
    required String mhswId,
    required BimbinganLogDraft draft,
  }) async {
    await _apiClient.post(
      'bimbingan/log',
      body: draft.toCreateBody(mhswId),
    );
  }

  Future<void> updateLog({
    required int logId,
    required BimbinganLogDraft draft,
  }) async {
    await _apiClient.put(
      'bimbingan/log/$logId',
      body: draft.toUpdateBody(),
    );
  }

  Future<void> deleteLog({
    required int logId,
  }) async {
    await _apiClient.delete('bimbingan/log/$logId');
  }
}
