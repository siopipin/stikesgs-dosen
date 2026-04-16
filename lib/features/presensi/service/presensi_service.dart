import '../../../core/network/api_client.dart';
import '../../dashboard/model/teaching_schedule_item.dart';
import '../model/presensi_attendance_item.dart';
import '../model/presensi_session.dart';

class PresensiService {
  PresensiService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<TeachingScheduleItem>> getTeachingSchedule() async {
    final response = await _apiClient.get('jadwal-mengajar');
    final data = (response['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final list = (data['jadwal'] as List<dynamic>?) ?? <dynamic>[];

    return list
        .whereType<Map<String, dynamic>>()
        .map(TeachingScheduleItem.fromJson)
        .toList();
  }

  /// GET `presensi/aktif` — [pertemuan] dikirim sebagai query agar backend bisa mengembalikan
  /// konteks pertemuan (termasuk yang sudah ditutup) tanpa harus ada sesi OPEN.
  Future<PresensiAktifContext> fetchAktifContext({
    required int jadwalId,
    required int pertemuan,
  }) async {
    final response = await _apiClient.get(
      'presensi/aktif?jadwal_id=$jadwalId&pertemuan=$pertemuan',
    );
    final data = response['data'];
    return _parseAktifEnvelope(data, selectedPertemuan: pertemuan);
  }

  Future<PresensiSession> startSession({
    required int jadwalId,
    required int pertemuan,
  }) async {
    final response = await _apiClient.post(
      'presensi/start',
      body: {
        'jadwal_id': jadwalId,
        'pertemuan': pertemuan,
      },
    );
    return PresensiSession.fromJson(response);
  }

  Future<void> endSession({
    required int presensiId,
  }) async {
    await _apiClient.post(
      'presensi/end',
      body: {
        'presensi_id': presensiId,
      },
    );
  }

  Future<List<PresensiAttendanceItem>> getAttendance({
    required int presensiId,
  }) async {
    final response = await _apiClient.get('presensi/$presensiId/kehadiran');
    final data = response['data'];

    if (data is List<dynamic>) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PresensiAttendanceItem.fromJson)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final list = data['kehadiran'] ?? data['list'] ?? data['items'];
      if (list is List<dynamic>) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(PresensiAttendanceItem.fromJson)
            .toList();
      }
    }

    return <PresensiAttendanceItem>[];
  }

  Future<void> updateAttendance({
    required int presensiId,
    required PresensiAttendanceItem item,
    required bool isPresent,
  }) async {
    final body = <String, dynamic>{
      'presensi_id': presensiId,
      'status_hadir': isPresent ? 1 : 0,
    };

    if (item.id.isNotEmpty) {
      body['krs_id'] = item.id;
    }
    if (item.studentId.isNotEmpty) {
      body['mhsw_id'] = item.studentId;
    }

    await _apiClient.put(
      'presensi/kehadiran',
      body: body,
    );
  }
}

PresensiSession? _sessionFromInnerMap(Map<String, dynamic> inner) {
  final id = PresensiSession.fromJson({'data': inner}).presensiId;
  if (id == 0) return null;
  return PresensiSession.fromJson({'data': inner});
}

PresensiAktifContext _parseAktifEnvelope(
  dynamic dataRoot, {
  required int selectedPertemuan,
}) {
  if (dataRoot == null || dataRoot is! Map<String, dynamic>) {
    return const PresensiAktifContext();
  }
  final data = dataRoot;

  PresensiSession? activeMap;
  final rawActive = data['active_session'];
  if (rawActive is Map<String, dynamic>) {
    activeMap = _sessionFromInnerMap(rawActive);
  }

  PresensiSession? openSession;
  if (activeMap != null && activeMap.status.toUpperCase() == 'OPEN') {
    openSession = activeMap;
  }

  PresensiSession? meetingFromLists;
  const listKeys = <String>[
    'histori',
    'riwayat',
    'sessions',
    'daftar_presensi',
    'presensi_list',
    'items',
    'daftar',
  ];
  for (final key in listKeys) {
    final list = data[key];
    if (list is! List<dynamic>) continue;
    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;
      final s = _sessionFromInnerMap(e);
      if (s != null && s.matchesPertemuan(selectedPertemuan)) {
        meetingFromLists = s;
        break;
      }
    }
    if (meetingFromLists != null) break;
  }

  PresensiSession? meetingSession = meetingFromLists;

  final perMap = data['presensi_per_pertemuan'];
  if (meetingSession == null && perMap is Map) {
    final raw = perMap[selectedPertemuan.toString()] ??
        perMap[selectedPertemuan] ??
        perMap['$selectedPertemuan'];
    if (raw is Map<String, dynamic>) {
      meetingSession = _sessionFromInnerMap(raw);
    }
  }

  if (meetingSession == null && activeMap != null && activeMap.matchesPertemuan(selectedPertemuan)) {
    meetingSession = activeMap;
  }

  if (meetingSession == null) {
    const mapKeys = <String>[
      'presensi',
      'presensi_terakhir',
      'last_presensi',
      'meeting_session',
      'rekap_presensi',
    ];
    for (final key in mapKeys) {
      final m = data[key];
      if (m is! Map<String, dynamic>) continue;
      final s = _sessionFromInnerMap(m);
      if (s != null && s.matchesPertemuan(selectedPertemuan)) {
        meetingSession = s;
        break;
      }
    }
  }

  if (meetingSession == null && data.containsKey('presensi_id')) {
    final s = _sessionFromInnerMap(Map<String, dynamic>.from(data));
    if (s != null && s.matchesPertemuan(selectedPertemuan)) {
      meetingSession = s;
    }
  }

  return PresensiAktifContext(
    openSession: openSession,
    meetingSession: meetingSession,
  );
}
