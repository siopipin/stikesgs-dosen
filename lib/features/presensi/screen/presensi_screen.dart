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
                onPressed: provider.isActionLoading
                    ? null
                    : provider.refreshAll,
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

String _semanticsJadwalLabel(TeachingScheduleItem? item) {
  if (item == null) return 'belum dipilih';
  final mk = item.namaMk.trim().isEmpty ? 'mata kuliah' : item.namaMk;
  return '$mk, ${item.namaHari}, jam ${item.jamMulai}–${item.jamSelesai}, '
      'ruang ${item.ruang}, ${item.sks} SKS';
}

void _showJadwalPickerSheet(BuildContext context, PresensiProvider provider) {
  final scheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.38,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Material(
            color: scheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pilih jadwal mengajar',
                          style: textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Tutup',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Semua informasi jadwal ditampilkan lengkap. Ketuk salah satu untuk memilih.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: provider.schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = provider.schedules[index];
                      final selected =
                          item.jadwalId == provider.selectedSchedule?.jadwalId;
                      return _JadwalPickerCard(
                        item: item,
                        selected: selected,
                        enabled: !provider.isActionLoading,
                        onTap: () async {
                          await provider.selectSchedule(item);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _JadwalPickerCard extends StatelessWidget {
  const _JadwalPickerCard({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final TeachingScheduleItem item;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.55)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.namaMk.trim().isEmpty ? 'Mata kuliah' : item.namaMk,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: scheme.primary,
                        size: 22,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${item.namaHari} · ${item.jamMulai}–${item.jamSelesai}',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ruang ${item.ruang} · ${item.sks} SKS',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JadwalFieldSummary extends StatelessWidget {
  const _JadwalFieldSummary({required this.item});

  final TeachingScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.namaMk.trim().isEmpty ? 'Mata kuliah' : item.namaMk,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${item.namaHari} · ${item.jamMulai}–${item.jamSelesai}',
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ruang ${item.ruang} · ${item.sks} SKS',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({required this.provider});

  final PresensiProvider provider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = provider.isActionLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pilih Jadwal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (provider.isLoading && provider.schedules.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.schedules.isEmpty)
              const Text('Belum ada jadwal mengajar.')
            else
              Semantics(
                button: true,
                label:
                    'Jadwal terpilih: ${_semanticsJadwalLabel(provider.selectedSchedule)}. Ketuk untuk mengganti.',
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Jadwal',
                    border: const OutlineInputBorder(),
                    enabled: !disabled,
                    suffixIcon: Icon(
                      Icons.expand_more_rounded,
                      color: disabled
                          ? scheme.onSurface.withValues(alpha: 0.38)
                          : scheme.onSurfaceVariant,
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(14, 16, 8, 14),
                  ),
                  child: InkWell(
                    onTap: disabled
                        ? null
                        : () => _showJadwalPickerSheet(context, provider),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: provider.selectedSchedule != null
                          ? _JadwalFieldSummary(
                              item: provider.selectedSchedule!,
                            )
                          : Text(
                              'Ketuk untuk memilih jadwal',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                    ),
                  ),
                ),
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
              items: List<int>.generate(16, (index) => index + 1).map((value) {
                final locked = provider.isPertemuanLocked(value);
                final isSelected = value == provider.pertemuan;
                final label = locked ? '$value · selesai' : value.toString();
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
              }).toList(),
              onChanged:
                  provider.isActionLoading || provider.pertemuanLocksLoading
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

class _PresensiSessionTimerStripState
    extends State<_PresensiSessionTimerStrip> {
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
          end == null ? '—' : _formatCountdown(remaining ?? Duration.zero),
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

class _PresensiActiveSessionBodyState
    extends State<_PresensiActiveSessionBody> {
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
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
    final canEnd =
        open != null &&
        open.status.toUpperCase() == 'OPEN' &&
        !provider.isActionLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sesi Presensi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
            else ...[
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
              ...provider.attendance.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AttendanceTile(
                    item: item,
                    enabled: provider.canEditAttendance &&
                        !provider.isActionLoading,
                    onChanged: (value) async {
                      final ok = await provider.updateAttendance(
                        item: item,
                        statusCode: value,
                      );
                      if (!context.mounted || ok) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.errorMessage ??
                                'Gagal memperbarui kehadiran.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
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

  static const List<String> _codes = <String>['H', 'M', 'I', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final current = item.statusCode.toUpperCase();
    final npm = item.studentId.trim().isEmpty ? '—' : item.studentId.trim();

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.studentName,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'NPM $npm',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _AttendanceStatusPill(code: current),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < _codes.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _AttendanceStatusButton(
                      status: _codes[i],
                      current: current,
                      enabled: enabled,
                      tooltip: _AttendanceStatusButton.tooltipFor(_codes[i]),
                      onPressed: () => onChanged(_codes[i]),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge ringkas status aktual (kolom kanan baris identitas).
class _AttendanceStatusPill extends StatelessWidget {
  const _AttendanceStatusPill({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final c = _AttendanceStatusButton.colorForStatus(code, scheme);
    final label = _AttendanceStatusButton.longLabelFor(code);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            code.toUpperCase(),
            style: textTheme.labelLarge?.copyWith(
              color: c,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceStatusButton extends StatelessWidget {
  const _AttendanceStatusButton({
    required this.status,
    this.current = '',
    this.enabled = true,
    this.tooltip,
    this.onPressed,
  });

  final String status;
  final String current;
  final bool enabled;
  final String? tooltip;
  final VoidCallback? onPressed;

  static String tooltipFor(String code) {
    switch (code.toUpperCase()) {
      case 'H':
        return 'Hadir';
      case 'M':
        return 'Mangkir';
      case 'I':
        return 'Izin';
      case 'S':
        return 'Sakit';
      default:
        return code;
    }
  }

  static String longLabelFor(String code) {
    return tooltipFor(code);
  }

  static Color colorForStatus(String value, ColorScheme scheme) {
    switch (value.toUpperCase()) {
      case 'H':
        return const Color(0xFF2E7D32);
      case 'M':
        return scheme.error;
      case 'I':
        return const Color(0xFF1565C0);
      case 'S':
        return const Color(0xFFE65100);
      default:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = current.toUpperCase() == status.toUpperCase();
    final scheme = Theme.of(context).colorScheme;
    final borderColor = colorForStatus(status, scheme);

    final button = OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        side: BorderSide(
          color: selected ? borderColor : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
        backgroundColor:
            selected ? borderColor.withValues(alpha: 0.12) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: selected ? borderColor : scheme.onSurfaceVariant,
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return SizedBox(width: double.infinity, child: button);

    return Tooltip(
      message: tooltip!,
      child: SizedBox(width: double.infinity, child: button),
    );
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
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }
}

class _MeetingStateBanner extends StatelessWidget {
  const _MeetingStateBanner({required this.provider});

  final PresensiProvider provider;

  @override
  Widget build(BuildContext context) {
    final open = provider.openSession;
    final isLive = open != null && open.status.toUpperCase() == 'OPEN';
    final done = provider.isPresensiSudahDilakukan;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    late final Color color;
    late final IconData icon;
    late final String title;
    String? subtitle;

    if (isLive) {
      color = scheme.primary;
      icon = Icons.qr_code_2_rounded;
      title = 'Pertemuan ${provider.pertemuan}: Presensi sedang berlangsung';
      subtitle =
          'Sesi aktif — mahasiswa dapat memindai kode QR hingga waktu habis atau sesi ditutup.';
    } else if (done) {
      color = scheme.error;
      icon = Icons.event_busy_rounded;
      title = 'Pertemuan ${provider.pertemuan}: Presensi sudah dilakukan';
    } else {
      color = Colors.green;
      icon = Icons.event_available_rounded;
      title = 'Pertemuan ${provider.pertemuan}: Presensi belum dilakukan';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
