import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../dashboard/model/teaching_schedule_item.dart';
import '../model/presensi_attendance_item.dart';
import '../model/presensi_session.dart';
import '../provider/presensi_provider.dart';

class PresensiScreen extends StatefulWidget {
  const PresensiScreen({super.key});

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PresensiProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PresensiProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Presensi'),
            actions: [
              IconButton(
                onPressed: provider.isActionLoading ? null : provider.refreshAll,
                tooltip: 'Refresh data presensi',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: provider.refreshAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ScheduleSection(provider: provider),
                const SizedBox(height: 12),
                _SessionSection(provider: provider),
                const SizedBox(height: 12),
                _AttendanceSection(provider: provider),
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    provider.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({required this.provider});

  final PresensiProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pilih Jadwal', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (provider.isLoading && provider.schedules.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.schedules.isEmpty)
              const Text('Belum ada jadwal mengajar.')
            else
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: provider.selectedSchedule?.jadwalId,
                decoration: const InputDecoration(
                  labelText: 'Jadwal',
                ),
                items: provider.schedules
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item.jadwalId,
                        child: Text(
                          _scheduleLabel(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: provider.isActionLoading
                    ? null
                    : (value) {
                        if (value == null) return;
                        final selected = provider.schedules.firstWhere(
                          (e) => e.jadwalId == value,
                        );
                        provider.selectSchedule(selected);
                      },
              ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: provider.pertemuan,
              decoration: InputDecoration(
                labelText: 'Pertemuan',
                helperText: provider.pertemuanLocksLoading
                    ? 'Memuat status pertemuan…'
                    : null,
              ),
              items: List<int>.generate(16, (index) => index + 1)
                  .map(
                    (value) {
                      final locked = provider.isPertemuanLocked(value);
                      final isSelected = value == provider.pertemuan;
                      final label = locked
                          ? '$value · selesai'
                          : value.toString();
                      return DropdownMenuItem<int>(
                        value: value,
                        enabled: !locked || isSelected,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: locked && !isSelected
                                ? Colors.grey.shade500
                                : null,
                          ),
                        ),
                      );
                    },
                  )
                  .toList(),
              onChanged: provider.isActionLoading || provider.pertemuanLocksLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        provider.setPertemuan(value);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  String _scheduleLabel(TeachingScheduleItem item) {
    return '${item.namaHari} ${item.jamMulai}-${item.jamSelesai} • ${item.namaMk}';
  }
}

void _openFullQrDialog(BuildContext context, PresensiSession session) {
  final shortest = MediaQuery.sizeOf(context).shortestSide;
  final qrSize = (shortest * 0.82).clamp(240.0, 380.0);

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Scan untuk presensi',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pastikan layar cukup terang agar kamera mahasiswa dapat membaca QR '
                  'sebelum waktu sesi berakhir.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: session.qrSessionToken,
                      version: QrVersions.auto,
                      size: qrSize,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF000000),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _PresensiSessionTimerStrip(session: session),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

DateTime? _presensiSessionEndAt(PresensiSession s) {
  if (s.expiredAt != null) return s.expiredAt;
  final start = s.startedAt;
  if (start != null) return start.add(const Duration(minutes: 20));
  return null;
}

String _formatTimeHm(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)}';
}

String _formatCountdown(Duration d) {
  if (d.isNegative || d.inSeconds <= 0) return '00:00';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final sec = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${_twoPad(h)}:${_twoPad(m)}:${_twoPad(sec)}';
  }
  return '${_twoPad(m)}:${_twoPad(sec)}';
}

String _twoPad(int n) => n.toString().padLeft(2, '0');

/// Timer + ringkasan waktu (dipakai di dialog fullscreen dan kartu sesi).
class _PresensiSessionTimerStrip extends StatefulWidget {
  const _PresensiSessionTimerStrip({required this.session});

  final PresensiSession session;

  @override
  State<_PresensiSessionTimerStrip> createState() =>
      _PresensiSessionTimerStripState();
}

class _PresensiSessionTimerStripState extends State<_PresensiSessionTimerStrip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final end = _presensiSessionEndAt(widget.session);
    final start = widget.session.startedAt;
    final now = DateTime.now();
    Duration? remaining;
    var expired = false;
    if (end != null) {
      remaining = end.difference(now);
      expired = remaining.isNegative;
      if (expired) remaining = Duration.zero;
    }

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sisa waktu sesi',
          style: textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          end == null
              ? '—'
              : _formatCountdown(remaining ?? Duration.zero),
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: expired ? scheme.error : scheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        if (end != null && expired) ...[
          const SizedBox(height: 6),
          Text(
            'Waktu scan untuk sesi ini telah lewat. Tutup sesi jika semua sudah selesai.',
            style: textTheme.bodySmall?.copyWith(color: scheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        if (start != null || end != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TimeInfoTile(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Dimulai',
                  value: start != null ? _formatTimeHm(start) : '—',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TimeInfoTile(
                  icon: Icons.timer_outlined,
                  label: 'Berakhir',
                  value: end != null ? _formatTimeHm(end) : '—',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TimeInfoTile extends StatelessWidget {
  const _TimeInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresensiActiveSessionBody extends StatefulWidget {
  const _PresensiActiveSessionBody({
    required this.session,
    required this.onFullScreen,
    required this.isActionLoading,
    required this.canCorrect,
  });

  final PresensiSession session;
  final VoidCallback onFullScreen;
  final bool isActionLoading;
  final bool canCorrect;

  @override
  State<_PresensiActiveSessionBody> createState() =>
      _PresensiActiveSessionBodyState();
}

class _PresensiActiveSessionBodyState extends State<_PresensiActiveSessionBody> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final end = _presensiSessionEndAt(widget.session);
    final start = widget.session.startedAt;
    final now = DateTime.now();

    double? progress;
    if (start != null && end != null) {
      final totalSec = end.difference(start).inSeconds;
      if (totalSec > 0) {
        final left = end.difference(now).inSeconds;
        progress = (1 - left / totalSec).clamp(0.0, 1.0);
      }
    }

    final remaining = end != null ? end.difference(now) : null;
    final expired = remaining != null && remaining.isNegative;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _PresensiQrPreview(data: widget.session.qrSessionToken)),
        const SizedBox(height: 16),
        Text(
          'Sisa waktu sesi',
          style: textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          end == null
              ? '—'
              : _formatCountdown(
                  expired ? Duration.zero : (remaining ?? Duration.zero),
                ),
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: expired ? scheme.error : scheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        if (end != null && start != null && progress != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: scheme.surfaceContainerHighest,
              color: expired ? scheme.error : scheme.primary,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TimeInfoTile(
                icon: Icons.schedule_rounded,
                label: 'Dimulai',
                value: start != null ? _formatTimeHm(start) : '—',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TimeInfoTile(
                icon: Icons.event_available_rounded,
                label: 'Berakhir',
                value: end != null ? _formatTimeHm(end) : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Mahasiswa memindai kode di atas sebelum waktu berakhir. '
          'Gunakan layar terang dan pertahankan jarak yang nyaman.',
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.canCorrect
              ? 'Koreksi kehadiran di bagian bawah diizinkan selama sesi terbuka.'
              : 'Koreksi kehadiran tidak diizinkan setelah sesi ditutup.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Text(
          end != null
              ? 'Sesi ditutup otomatis pada ${_formatTimeHm(end)} (sesuai aturan server).'
              : 'Sesi dihentikan otomatis setelah ±20 menit dari waktu mulai.',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          button: true,
          label: 'Tampilkan kode QR layar penuh untuk pemindaian',
          child: OutlinedButton.icon(
            onPressed: widget.isActionLoading ? null : widget.onFullScreen,
            icon: const Icon(Icons.fullscreen_rounded),
            label: const Text('Tampilkan QR layar penuh'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Token sesi',
          style: textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          widget.session.qrSessionToken,
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _PresensiQrPreview extends StatelessWidget {
  const _PresensiQrPreview({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: 168,
          backgroundColor: Colors.white,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF000000),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF000000),
          ),
        ),
      ),
    );
  }
}

class _SessionSection extends StatelessWidget {
  const _SessionSection({required this.provider});

  final PresensiProvider provider;

  @override
  Widget build(BuildContext context) {
    final open = provider.openSession;
    final canStart = provider.canStartSession;
    final canEnd = open != null &&
        open.status.toUpperCase() == 'OPEN' &&
        !provider.isActionLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sesi Presensi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _MeetingStateBanner(provider: provider),
            const SizedBox(height: 8),
            if (open == null)
              Text(
                provider.isPresensiSudahDilakukan
                    ? 'Presensi untuk pertemuan ini sudah dilakukan. Anda dapat melihat daftar mahasiswa dan statusnya.'
                    : 'Belum ada sesi aktif. Mulai sesi untuk membuat QR token presensi.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusChip(status: open.status),
                  const SizedBox(height: 12),
                  if (open.status.toUpperCase() == 'OPEN' &&
                      open.qrSessionToken.trim().isNotEmpty)
                    _PresensiActiveSessionBody(
                      session: open,
                      onFullScreen: () => _openFullQrDialog(context, open),
                      isActionLoading: provider.isActionLoading,
                      canCorrect: open.canEditAttendance,
                    )
                  else
                    Text(
                      open.qrSessionToken.trim().isEmpty
                          ? 'Token QR belum tersedia. Tunggu sinkron atau refresh.'
                          : 'Sesi tidak menampilkan QR.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: canStart
                        ? () async {
                            final ok = await provider.startSession();
                            if (!context.mounted) return;
                            _showSnack(
                              context,
                              ok
                                  ? 'Sesi presensi berhasil dimulai.'
                                  : (provider.errorMessage ??
                                      'Gagal memulai sesi presensi.'),
                            );
                          }
                        : null,
                    child: const Text('Start Sesi'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: canEnd
                        ? () async {
                            final ok = await provider.endSession();
                            if (!context.mounted) return;
                            _showSnack(
                              context,
                              ok
                                  ? 'Sesi presensi ditutup.'
                                  : (provider.errorMessage ??
                                      'Gagal menutup sesi presensi.'),
                            );
                          }
                        : null,
                    child: const Text('End Sesi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AttendanceSection extends StatelessWidget {
  const _AttendanceSection({required this.provider});

  final PresensiProvider provider;

  @override
  Widget build(BuildContext context) {
    final meeting = provider.meetingSession;
    final hasPresensiRow = meeting != null && meeting.presensiId != 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Rekap Kehadiran',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (provider.totalMahasiswa > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '${provider.totalMahasiswa} mhs',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                IconButton(
                  onPressed: provider.isActionLoading || !hasPresensiRow
                      ? null
                      : provider.refreshAttendance,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh daftar dan status kehadiran',
                ),
              ],
            ),
            if (!hasPresensiRow && provider.attendance.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Belum ada data presensi untuk jadwal dan pertemuan ini. '
                  'Jika sudah pernah presensi, coba tombol Refresh di atas untuk sinkron ulang.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else if (provider.attendance.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Belum ada data kehadiran.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              ...[
                if (!hasPresensiRow)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      'Daftar mahasiswa pertemuan ini diambil dari endpoint aktif.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
              ],
              ...provider.attendance.map(
                (item) => _AttendanceTile(
                  item: item,
                  enabled: provider.canEditAttendance && !provider.isActionLoading,
                  onChanged: (value) async {
                    final ok = await provider.updateAttendance(
                      item: item,
                      statusCode: value,
                    );
                    if (!context.mounted || ok) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.errorMessage ?? 'Gagal memperbarui kehadiran.',
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({
    required this.item,
    required this.enabled,
    required this.onChanged,
  });

  final PresensiAttendanceItem item;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = item.statusCode.toUpperCase();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(item.studentName),
      subtitle: Text(item.studentId.isEmpty ? '-' : item.studentId),
      trailing: Wrap(
        spacing: 6,
        children: ['H', 'M', 'I', 'S']
            .map(
              (status) => _AttendanceStatusButton(
                status: status,
                current: current,
                enabled: enabled,
                onPressed: () => onChanged(status),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AttendanceStatusButton extends StatelessWidget {
  const _AttendanceStatusButton({
    required this.status,
    this.current = '',
    this.enabled = true,
    this.onPressed,
  });

  final String status;
  final String current;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final selected = current == status;
    final scheme = Theme.of(context).colorScheme;
    final Color borderColor = _colorForStatus(status, scheme);

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(40, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        side: BorderSide(color: selected ? borderColor : scheme.outlineVariant),
        backgroundColor: selected ? borderColor.withValues(alpha: 0.14) : null,
      ),
      child: Text(
        status,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? borderColor : scheme.onSurface,
        ),
      ),
    );
  }

  Color _colorForStatus(String value, ColorScheme scheme) {
    switch (value) {
      case 'H':
        return Colors.green;
      case 'M':
        return scheme.error;
      case 'I':
        return Colors.blue;
      case 'S':
        return Colors.orange;
      default:
        return scheme.primary;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final Color color;
    switch (normalized) {
      case 'OPEN':
        color = Colors.green;
        break;
      case 'AUTO-CLOSED':
      case 'CLOSED':
        color = Colors.orange;
        break;
      default:
        color = Theme.of(context).colorScheme.primary;
    }

    return Chip(
      label: Text(normalized),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MeetingStateBanner extends StatelessWidget {
  const _MeetingStateBanner({required this.provider});

  final PresensiProvider provider;

  @override
  Widget build(BuildContext context) {
    final done = provider.isPresensiSudahDilakukan;
    final scheme = Theme.of(context).colorScheme;
    final Color color = done ? scheme.error : Colors.green;
    final text = done
        ? 'Pertemuan ${provider.pertemuan}: Presensi sudah dilakukan'
        : 'Pertemuan ${provider.pertemuan}: Presensi belum dilakukan';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.event_busy_rounded : Icons.event_available_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
