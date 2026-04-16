import '../../../core/network/api_client.dart';
import '../model/penilaian_schedule_item.dart';
import '../model/penilaian_student_item.dart';

class PenilaianService {
  PenilaianService(this._apiClient);

  final ApiClient _apiClient;

  Future<String> getDefaultTahunId() async {
    final response = await _apiClient.get('dashboard');
    final data = (response['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final ringkasan = (data['ringkasan'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return (ringkasan['tahunid'] ?? '').toString();
  }

  Future<List<PenilaianScheduleItem>> getSchedules({
    required String tahunId,
  }) async {
    final response = await _apiClient.get('nilai/jadwal-input?tahunid=$tahunId');
    final data = response['data'];

    if (data is List<dynamic>) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PenilaianScheduleItem.fromJson)
          .where((item) => item.jadwalId != 0)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final list = data['jadwal'] ?? data['list'] ?? data['items'] ?? data['data'];
      if (list is List<dynamic>) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(PenilaianScheduleItem.fromJson)
            .where((item) => item.jadwalId != 0)
            .toList();
      }
    }

    return <PenilaianScheduleItem>[];
  }

  Future<List<PenilaianStudentItem>> getStudents({
    required int jadwalId,
  }) async {
    final response = await _apiClient.get('nilai/mahasiswa?jadwal_id=$jadwalId');
    final data = response['data'];

    if (data is List<dynamic>) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PenilaianStudentItem.fromJson)
          .where((item) => item.krsId != 0)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final list = data['mahasiswa'] ?? data['list'] ?? data['items'] ?? data['data'];
      if (list is List<dynamic>) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(PenilaianStudentItem.fromJson)
            .where((item) => item.krsId != 0)
            .toList();
      }
    }

    return <PenilaianStudentItem>[];
  }

  Future<void> updateNilai({
    required NilaiDraft draft,
    required int krsId,
  }) async {
    await _apiClient.put(
      'nilai/update',
      body: draft.toBody(krsId),
    );
  }
}
