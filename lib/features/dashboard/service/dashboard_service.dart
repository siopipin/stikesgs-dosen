import '../../../core/network/api_client.dart';
import '../model/announcement_item.dart';
import '../model/dashboard_summary.dart';
import '../model/teaching_schedule_item.dart';

class DashboardService {
  DashboardService(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardSummary> getDashboardSummary() async {
    final response = await _apiClient.get('dashboard');
    return DashboardSummary.fromJson(response);
  }

  Future<List<TeachingScheduleItem>> getTeachingSchedule() async {
    final response = await _apiClient.get('jadwal-mengajar');
    final data = (response['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final list = (data['jadwal'] as List<dynamic>?) ?? <dynamic>[];

    return list
        .whereType<Map<String, dynamic>>()
        .map(TeachingScheduleItem.fromJson)
        .toList();
  }

  Future<List<AnnouncementItem>> getAnnouncements() async {
    final response = await _apiClient.get('notifikasi');
    final data = response['data'];

    if (data is List<dynamic>) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(AnnouncementItem.fromJson)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final candidate = data['notifikasi'] ?? data['list'] ?? data['items'];
      if (candidate is List<dynamic>) {
        return candidate
            .whereType<Map<String, dynamic>>()
            .map(AnnouncementItem.fromJson)
            .toList();
      }
    }

    return <AnnouncementItem>[];
  }
}
