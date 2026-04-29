import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../dashboard/model/teaching_schedule_item.dart';
import '../model/presensi_attendance_item.dart';
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
              decoration: const InputDecoration(
                labelText: 'Pertemuan',
              ),
              items: List<int>.generate(16, (index) => index + 1)
                  .map(
                    (value) => DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    ),
                  )
                  .toList(),
              onChanged: provider.isActionLoading
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

void _openFullQrDialog(BuildContext context, String data) {
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
                  'Pastikan layar cukup terang agar kamera mahasiswa dapat membaca QR.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: data,
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

class _PresensiQrPreview extends StatelessWidget {
  const _PresensiQrPreview({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outline),
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
                      open.qrSessionToken.trim().isNotEmpty) ...[
                    Center(
                      child: _PresensiQrPreview(data: open.qrSessionToken),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: provider.isActionLoading
                          ? null
                          : () => _openFullQrDialog(context, open.qrSessionToken),
                      icon: const Icon(Icons.fullscreen_rounded),
                      label: const Text('Tampilkan QR penuh'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SelectableText(
                    'Token: ${open.qrSessionToken}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    open.canEditAttendance
                        ? 'Koreksi kehadiran diizinkan.'
                        : 'Koreksi kehadiran tidak diizinkan (sesi sudah ditutup).',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sesi akan auto-close setelah 20 menit sesuai aturan backend.',
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
