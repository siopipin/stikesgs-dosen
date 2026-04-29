import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/penilaian_schedule_item.dart';
import '../model/penilaian_student_item.dart';
import '../provider/penilaian_provider.dart';

void _showPenilaianJadwalSheet(
  BuildContext context,
  PenilaianProvider provider,
) {
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
        minChildSize: 0.36,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Material(
            color: scheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pilih jadwal penilaian',
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
                    'Informasi mata kuliah, kelas, dan waktu ditampilkan lengkap.',
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
                      return _PenilaianJadwalPickerTile(
                        item: item,
                        selected: selected,
                        enabled: !provider.isActionLoading,
                        onTap: () {
                          provider.selectSchedule(item).then((_) {
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          });
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

class _PenilaianJadwalPickerTile extends StatelessWidget {
  const _PenilaianJadwalPickerTile({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PenilaianScheduleItem item;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mk = item.namaMk.trim().isEmpty ? 'Mata kuliah' : item.namaMk;

    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.55)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? () => onTap() : null,
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
                      mk,
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
              if (item.kelas.isNotEmpty)
                Text(
                  'Kelas ${item.kelas}',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                [
                  if (item.namaHari.isNotEmpty) item.namaHari,
                  if (item.jamMulai.isNotEmpty || item.jamSelesai.isNotEmpty)
                    '${item.jamMulai}${item.jamMulai.isNotEmpty && item.jamSelesai.isNotEmpty ? '–' : ''}${item.jamSelesai}',
                ].join(' · '),
                style: textTheme.bodyMedium?.copyWith(
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

class PenilaianScreen extends StatefulWidget {
  const PenilaianScreen({super.key});

  @override
  State<PenilaianScreen> createState() => _PenilaianScreenState();
}

class _PenilaianScreenState extends State<PenilaianScreen> {
  final TextEditingController _tahunController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PenilaianProvider>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _tahunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PenilaianProvider>(
      builder: (context, provider, _) {
        if (_tahunController.text != provider.tahunId) {
          _tahunController.text = provider.tahunId;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Penilaian'),
            actions: [
              IconButton(
                onPressed: provider.isActionLoading
                    ? null
                    : provider.refreshAll,
                tooltip: 'Refresh data penilaian',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: provider.refreshAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _FilterSection(
                  provider: provider,
                  tahunController: _tahunController,
                ),
                const SizedBox(height: 12),
                _StudentListSection(provider: provider),
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

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.provider, required this.tahunController});

  final PenilaianProvider provider;
  final TextEditingController tahunController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list_rounded, color: scheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Filter Penilaian',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tahunController,
              enabled: !provider.isActionLoading,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Tahun akademik',
                hintText: 'Contoh: 20251',
                helperText: 'Isi kode tahun lalu ketuk muat jadwal.',
                border: const OutlineInputBorder(),
                isDense: false,
              ),
              onSubmitted: (_) => _loadSchedules(context),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  provider.isActionLoading ? null : () => _loadSchedules(context),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Muat jadwal penilaian'),
            ),
            const SizedBox(height: 14),
            if (provider.isLoading && provider.schedules.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.schedules.isEmpty)
              Text(
                'Belum ada jadwal. Pastikan tahun benar lalu muat ulang.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              )
            else ...[
              Semantics(
                button: true,
                label:
                    'Jadwal terpilih: ${_jadwalSemantics(provider.selectedSchedule)}',
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Jadwal',
                    border: const OutlineInputBorder(),
                    enabled: !provider.isActionLoading,
                    suffixIcon: Icon(
                      Icons.expand_more_rounded,
                      color: provider.isActionLoading
                          ? scheme.onSurface.withValues(alpha: 0.38)
                          : scheme.onSurfaceVariant,
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(14, 16, 8, 14),
                  ),
                  child: InkWell(
                    onTap: provider.isActionLoading
                        ? null
                        : () => _showPenilaianJadwalSheet(context, provider),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: provider.selectedSchedule != null
                          ? _SelectedJadwalSummary(item: provider.selectedSchedule!)
                          : Text(
                              'Ketuk untuk memilih jadwal',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                    ),
                  ),
                ),
              ),
              if (provider.selectedSchedule != null) ...[
                const SizedBox(height: 12),
                _CoordinatorInfo(provider: provider),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _jadwalSemantics(PenilaianScheduleItem? item) {
    if (item == null) return 'belum dipilih';
    final mk = item.namaMk.trim().isEmpty ? 'mata kuliah' : item.namaMk;
    return '$mk, kelas ${item.kelas}, ${item.namaHari} ${item.jamMulai}–${item.jamSelesai}';
  }

  void _loadSchedules(BuildContext context) {
    final p = context.read<PenilaianProvider>();
    p.setTahunId(tahunController.text);
    p.loadSchedules();
  }
}

class _SelectedJadwalSummary extends StatelessWidget {
  const _SelectedJadwalSummary({required this.item});

  final PenilaianScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mk = item.namaMk.trim().isEmpty ? 'Mata kuliah' : item.namaMk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mk,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        if (item.kelas.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Kelas ${item.kelas}',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          [
            if (item.namaHari.isNotEmpty) item.namaHari,
            if (item.jamMulai.isNotEmpty || item.jamSelesai.isNotEmpty)
              '${item.jamMulai}${item.jamMulai.isNotEmpty && item.jamSelesai.isNotEmpty ? '–' : ''}${item.jamSelesai}',
          ].join(' · '),
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _CoordinatorInfo extends StatelessWidget {
  const _CoordinatorInfo({required this.provider});

  final PenilaianProvider provider;

  @override
  Widget build(BuildContext context) {
    final schedule = provider.selectedSchedule;
    if (schedule == null) return const SizedBox.shrink();

    final jenis = schedule.jenisDosenId.toUpperCase();
    final hasJenis = jenis.isNotEmpty;
    final isCoordinator = provider.canEditScores;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Color accent;
    final Color onAccent;
    final String message;

    if (!hasJenis) {
      accent = scheme.secondaryContainer;
      onAccent = scheme.onSecondaryContainer;
      message =
          'Jenis dosen tidak dikirim backend. Input nilai tetap akan diverifikasi server.';
    } else if (isCoordinator) {
      accent = scheme.tertiaryContainer;
      onAccent = scheme.onTertiaryContainer;
      message =
          'Anda koordinator ($jenis). Mengisi dan menyimpan nilai diizinkan.';
    } else {
      accent = scheme.errorContainer;
      onAccent = scheme.onErrorContainer;
      message =
          'Peran Anda $jenis (bukan koordinator). Input nilai tidak diizinkan untuk jadwal ini.';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: onAccent,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: onAccent,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentListSection extends StatelessWidget {
  const _StudentListSection({required this.provider});

  final PenilaianProvider provider;

  @override
  Widget build(BuildContext context) {
    final selected = provider.selectedSchedule;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school_rounded, color: scheme.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daftar nilai mahasiswa',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'Tugas 1–5, UTS, dan UAS.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: selected == null || provider.isActionLoading
                      ? null
                      : provider.loadStudents,
                  tooltip: 'Muat ulang daftar mahasiswa',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            if (selected == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pilih jadwal di atas untuk menampilkan mahasiswa.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              )
            else if (provider.isActionLoading && provider.students.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.students.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Belum ada mahasiswa pada jadwal ini.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Mahasiswa',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      label: Text('${provider.students.length} orang'),
                      avatar: Icon(
                        Icons.people_outline_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              ...provider.students.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StudentScoreTile(
                    item: item,
                    canEdit: provider.canEditScores && !provider.isSaving,
                    onEdit: () async {
                      final draft = await showDialog<NilaiDraft>(
                        context: context,
                        builder: (_) => _ScoreEditorDialog(student: item),
                      );
                      if (draft == null || !context.mounted) return;

                      final ok = await provider.saveScores(
                        student: item,
                        draft: draft,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Nilai ${item.nama} berhasil disimpan.'
                                : (provider.errorMessage ??
                                      'Simpan nilai gagal.'),
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

class _StudentScoreTile extends StatelessWidget {
  const _StudentScoreTile({
    required this.item,
    required this.canEdit,
    required this.onEdit,
  });

  final PenilaianStudentItem item;
  final bool canEdit;
  final VoidCallback onEdit;

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.single;
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
    }
    return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final npm = item.npm.isEmpty ? item.mhswId : item.npm;
    final npmDisplay = npm.isEmpty ? '—' : npm;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      scheme.primaryContainer.withValues(alpha: 0.9),
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(
                    _initials(item.nama.isEmpty ? '?' : item.nama),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nama.isEmpty ? 'Mahasiswa' : item.nama,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NPM $npmDisplay',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Isi atau ubah nilai ${item.nama}',
                  button: true,
                  child: IconButton.filledTonal(
                    onPressed: canEdit ? onEdit : null,
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    tooltip: 'Isi nilai',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      maximumSize: const Size(40, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _NilaiCell(label: 'T1', value: item.tugas1, scheme: scheme),
                  const SizedBox(width: 5),
                  _NilaiCell(label: 'T2', value: item.tugas2, scheme: scheme),
                  const SizedBox(width: 5),
                  _NilaiCell(label: 'T3', value: item.tugas3, scheme: scheme),
                  const SizedBox(width: 5),
                  _NilaiCell(label: 'T4', value: item.tugas4, scheme: scheme),
                  const SizedBox(width: 5),
                  _NilaiCell(label: 'T5', value: item.tugas5, scheme: scheme),
                  const SizedBox(width: 5),
                  _NilaiCell(label: 'UTS', value: item.uts, scheme: scheme),
                  const SizedBox(width: 5),
                  _NilaiCell(label: 'UAS', value: item.uas, scheme: scheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NilaiCell extends StatelessWidget {
  const _NilaiCell({
    required this.label,
    required this.value,
    required this.scheme,
  });

  final String label;
  final int? value;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final display = value?.toString() ?? '—';

    return SizedBox(
      width: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreEditorDialog extends StatefulWidget {
  const _ScoreEditorDialog({required this.student});

  final PenilaianStudentItem student;

  @override
  State<_ScoreEditorDialog> createState() => _ScoreEditorDialogState();
}

class _ScoreEditorDialogState extends State<_ScoreEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _t1;
  late final TextEditingController _t2;
  late final TextEditingController _t3;
  late final TextEditingController _t4;
  late final TextEditingController _t5;
  late final TextEditingController _uts;
  late final TextEditingController _uas;

  @override
  void initState() {
    super.initState();
    _t1 = TextEditingController(text: _init(widget.student.tugas1));
    _t2 = TextEditingController(text: _init(widget.student.tugas2));
    _t3 = TextEditingController(text: _init(widget.student.tugas3));
    _t4 = TextEditingController(text: _init(widget.student.tugas4));
    _t5 = TextEditingController(text: _init(widget.student.tugas5));
    _uts = TextEditingController(text: _init(widget.student.uts));
    _uas = TextEditingController(text: _init(widget.student.uas));
  }

  @override
  void dispose() {
    _t1.dispose();
    _t2.dispose();
    _t3.dispose();
    _t4.dispose();
    _t5.dispose();
    _uts.dispose();
    _uas.dispose();
    super.dispose();
  }

  NilaiDraft _buildDraft() {
    int? p(TextEditingController c) {
      final t = c.text.trim();
      if (t.isEmpty) return null;
      return int.tryParse(t);
    }

    return NilaiDraft(
      tugas1: p(_t1),
      tugas2: p(_t2),
      tugas3: p(_t3),
      tugas4: p(_t4),
      tugas5: p(_t5),
      uts: p(_uts),
      uas: p(_uas),
    );
  }

  Future<void> _openConfirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = _buildDraft();
    final resolved = draft.resolvedAgainst(widget.student);

    if (!mounted) return;
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Konfirmasi simpan'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nilai berikut akan dikirim (kolom kosong di form mempertahankan nilai yang sudah ada).',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),
                _ConfirmNilaiTable(resolved: resolved),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Kembali'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('Ya, simpan'),
            ),
          ],
        );
      },
    );

    if (approved == true && mounted) {
      Navigator.of(context).pop(draft);
    }
  }

  String? _optionalScoreValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final n = int.tryParse(text);
    if (n == null) return 'Harus berupa angka';
    if (n < 0 || n > 100) return 'Rentang 0–100';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final npm = widget.student.npm.isEmpty
        ? widget.student.mhswId
        : widget.student.npm;
    // Jangan pakai LayoutBuilder di dalam AlertDialog (intrinsic size tidak didukung).
    final useTwoColumns = MediaQuery.sizeOf(context).width >= 400;

    return AlertDialog(
      icon: Icon(Icons.edit_note_rounded, color: scheme.primary),
      title: Text(
        widget.student.nama.isEmpty ? 'Input nilai' : widget.student.nama,
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (npm.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'NPM $npm',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semua kolom opsional.',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Isi hanya komponen yang ingin diubah (0–100). Kosongkan untuk mempertahankan nilai saat ini.',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!useTwoColumns)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _scoreField(controller: _t1, label: 'Tugas 1'),
                    const SizedBox(height: 10),
                    _scoreField(controller: _t2, label: 'Tugas 2'),
                    const SizedBox(height: 10),
                    _scoreField(controller: _t3, label: 'Tugas 3'),
                    const SizedBox(height: 10),
                    _scoreField(controller: _t4, label: 'Tugas 4'),
                    const SizedBox(height: 10),
                    _scoreField(controller: _t5, label: 'Tugas 5'),
                    const SizedBox(height: 10),
                    _scoreField(controller: _uts, label: 'UTS'),
                    const SizedBox(height: 10),
                    _scoreField(controller: _uas, label: 'UAS'),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _scoreField(controller: _t1, label: 'Tugas 1'),
                          const SizedBox(height: 10),
                          _scoreField(controller: _t2, label: 'Tugas 2'),
                          const SizedBox(height: 10),
                          _scoreField(controller: _t3, label: 'Tugas 3'),
                          const SizedBox(height: 10),
                          _scoreField(controller: _t4, label: 'Tugas 4'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _scoreField(controller: _t5, label: 'Tugas 5'),
                          const SizedBox(height: 10),
                          _scoreField(controller: _uts, label: 'UTS'),
                          const SizedBox(height: 10),
                          _scoreField(controller: _uas, label: 'UAS'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _openConfirm,
          icon: const Icon(Icons.fact_check_rounded),
          label: const Text('Tinjau & simpan'),
        ),
      ],
    );
  }

  Widget _scoreField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Opsional · 0–100',
        border: const OutlineInputBorder(),
        isDense: true,
        filled: true,
      ),
      validator: _optionalScoreValidator,
    );
  }

  String _init(int? value) => value?.toString() ?? '';
}

class _ConfirmNilaiTable extends StatelessWidget {
  const _ConfirmNilaiTable({required this.resolved});

  final NilaiDraft resolved;

  static String _v(int? n) {
    if (n == null) return '—';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rows = <MapEntry<String, int?>>[
      MapEntry('Tugas 1', resolved.tugas1),
      MapEntry('Tugas 2', resolved.tugas2),
      MapEntry('Tugas 3', resolved.tugas3),
      MapEntry('Tugas 4', resolved.tugas4),
      MapEntry('Tugas 5', resolved.tugas5),
      MapEntry('UTS', resolved.uts),
      MapEntry('UAS', resolved.uas),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: rows.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.key,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    _v(e.value),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
