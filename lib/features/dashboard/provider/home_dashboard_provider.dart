import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../model/announcement_item.dart';
import '../model/dashboard_summary.dart';
import '../model/teaching_schedule_item.dart';
import '../service/dashboard_service.dart';

class HomeDashboardProvider extends ChangeNotifier {
  HomeDashboardProvider(this._service);

  final DashboardService _service;

  bool _isLoading = false;
  String? _errorMessage;
  DashboardSummary? _summary;
  List<TeachingScheduleItem> _schedules = <TeachingScheduleItem>[];
  List<AnnouncementItem> _announcements = <AnnouncementItem>[];
  bool _initialized = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DashboardSummary? get summary => _summary;
  List<TeachingScheduleItem> get schedules => _schedules;
  List<AnnouncementItem> get announcements => _announcements;

  Future<void> ensureLoaded() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _service.getDashboardSummary(),
        _service.getTeachingSchedule(),
        _service.getAnnouncements(),
      ]);

      _summary = results[0] as DashboardSummary;
      _schedules = results[1] as List<TeachingScheduleItem>;
      _announcements = results[2] as List<AnnouncementItem>;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Data dashboard belum dapat dimuat. Silakan coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
