import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/bimbingan_student_item.dart';
import '../provider/bimbingan_provider.dart';

void _showMahasiswaPickerSheet(
  BuildContext context,
  BimbinganProvider provider,
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
        initialChildSize: 0.52,
        minChildSize: 0.34,
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
                          'Pilih mahasiswa PA',
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
                    'Nama dan NPM ditampilkan lengkap.',
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
                    itemCount: provider.students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final student = provider.students[index];
                      final selected =
                          student.mhswId == provider.selectedStudent?.mhswId;
                      return _MahasiswaPickerTile(
                        student: student,
                        selected: selected,
                        enabled: !provider.isActionLoading,
                        onTap: () {
                          provider.selectStudent(student).then((_) {
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

class _MahasiswaPickerTile extends StatelessWidget {
  const _MahasiswaPickerTile({
    required this.student,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final BimbinganStudentItem student;
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primaryContainer.withValues(alpha: 0.95),
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(
                  _initials(student.displayName),
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.displayName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NPM ${student.displayNpm.isEmpty ? '—' : student.displayNpm}',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (student.prodi.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        student.prodi,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.check_circle_rounded, color: scheme.primary, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
}

class BimbinganScreen extends StatefulWidget {
  const BimbinganScreen({super.key});

  @override
  State<BimbinganScreen> createState() => _BimbinganScreenState();
}

class _BimbinganScreenState extends State<BimbinganScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BimbinganProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BimbinganProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bimbingan'),
            actions: [
              IconButton(
                onPressed: provider.isActionLoading ? null : provider.refreshAll,
                tooltip: 'Refresh data bimbingan',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          floatingActionButton: provider.selectedStudent == null
              ? null
              : FloatingActionButton(
                  onPressed: provider.isSubmitting
                      ? null
                      : () => _openCreateLogDialog(context),
                  tooltip: 'Tambah log bimbingan',
                  child: const Icon(Icons.add_rounded),
                ),
          body: RefreshIndicator(
            onRefresh: provider.refreshAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StudentSection(provider: provider),
                const SizedBox(height: 12),
                _LogSection(provider: provider),
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    provider.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 88),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreateLogDialog(BuildContext context) async {
    final provider = context.read<BimbinganProvider>();
    final draft = await showDialog<BimbinganLogDraft>(
      context: context,
      builder: (_) => const _LogEditorDialog(),
    );
    if (draft == null || !context.mounted) return;

    final ok = await provider.createLog(draft);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Log bimbingan berhasil ditambahkan.' : (provider.errorMessage ?? 'Tambah log gagal.'),
        ),
      ),
    );
  }
}

class _StudentSection extends StatelessWidget {
  const _StudentSection({required this.provider});

  final BimbinganProvider provider;

  @override
  Widget build(BuildContext context) {
    final selected = provider.selectedStudent;
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
                Icon(Icons.person_search_rounded, color: scheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mahasiswa PA',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.isLoading && provider.students.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.students.isEmpty)
              Text(
                'Belum ada mahasiswa bimbingan.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              )
            else ...[
              Semantics(
                button: true,
                label:
                    'Mahasiswa terpilih: ${_semanticsMahasiswa(selected)}. Ketuk untuk mengganti.',
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Mahasiswa',
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
                        : () => _showMahasiswaPickerSheet(context, provider),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: selected != null
                          ? _SelectedMahasiswaSummary(student: selected)
                          : Text(
                              'Ketuk untuk memilih mahasiswa',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _semanticsMahasiswa(BimbinganStudentItem? s) {
    if (s == null) return 'belum dipilih';
    final nama = s.displayName;
    final npm = s.displayNpm.isEmpty ? 'tanpa NPM' : s.displayNpm;
    final prodi = s.prodi.isEmpty ? '' : ', ${s.prodi}';
    return '$nama, NPM $npm$prodi';
  }
}

class _SelectedMahasiswaSummary extends StatelessWidget {
  const _SelectedMahasiswaSummary({required this.student});

  final BimbinganStudentItem student;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          student.displayName,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'NPM ${student.displayNpm.isEmpty ? '—' : student.displayNpm}',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (student.prodi.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            student.prodi,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogSection extends StatelessWidget {
  const _LogSection({required this.provider});

  final BimbinganProvider provider;

  @override
  Widget build(BuildContext context) {
    final student = provider.selectedStudent;
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
                Icon(Icons.history_edu_rounded, color: scheme.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log bimbingan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'Riwayat konsultasi per mahasiswa.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: student == null || provider.isActionLoading
                      ? null
                      : provider.loadLogs,
                  tooltip: 'Muat ulang log',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            if (student == null)
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
                        'Pilih mahasiswa di atas untuk melihat dan mengelola log.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              )
            else if (provider.isActionLoading && provider.logs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.logs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Belum ada log untuk mahasiswa ini. Gunakan tombol Tambah Log.',
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
                      'Entri log',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      avatar: Icon(
                        Icons.article_outlined,
                        size: 18,
                        color: scheme.primary,
                      ),
                      label: Text('${provider.logs.length} catatan'),
                    ),
                  ],
                ),
              ),
              ...provider.logs.map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LogItemTile(
                    item: log,
                    isBusy: provider.isSubmitting,
                    onEdit: () => _openEditLog(context, provider, log),
                    onDelete: () => _deleteLog(context, provider, log),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openEditLog(
    BuildContext context,
    BimbinganProvider provider,
    BimbinganLogItem item,
  ) async {
    final draft = await showDialog<BimbinganLogDraft>(
      context: context,
      builder: (_) => _LogEditorDialog(initial: item),
    );
    if (draft == null || !context.mounted) return;

    final ok = await provider.updateLog(item: item, draft: draft);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Log bimbingan berhasil diperbarui.' : (provider.errorMessage ?? 'Ubah log gagal.'),
        ),
      ),
    );
  }

  Future<void> _deleteLog(
    BuildContext context,
    BimbinganProvider provider,
    BimbinganLogItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus log bimbingan?'),
        content: const Text('Data log akan dihapus dari daftar mahasiswa ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await provider.deleteLog(item);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Log bimbingan dihapus.' : (provider.errorMessage ?? 'Hapus log gagal.'),
        ),
      ),
    );
  }
}

class _LogItemTile extends StatelessWidget {
  const _LogItemTile({
    required this.item,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final BimbinganLogItem item;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.tema.isEmpty ? 'Tanpa tema' : item.tema,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: scheme.primaryContainer.withValues(alpha: 0.65),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 14,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.tanggalKonsultasi.isEmpty ? '—' : item.tanggalKonsultasi,
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.ringkasan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.ringkasan,
                style: textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ],
            if (item.hasil.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Hasil: ${item.hasil}',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: 'Edit log ${item.tema}',
                    child: IconButton.filledTonal(
                      onPressed: isBusy ? null : onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      tooltip: 'Ubah',
                      style: IconButton.styleFrom(
                        minimumSize: const Size(40, 40),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Hapus log ${item.tema}',
                    child: IconButton(
                      onPressed: isBusy ? null : onDelete,
                      tooltip: 'Hapus',
                      icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(40, 40),
                        visualDensity: VisualDensity.compact,
                      ),
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

class _LogEditorDialog extends StatefulWidget {
  const _LogEditorDialog({this.initial});

  final BimbinganLogItem? initial;

  @override
  State<_LogEditorDialog> createState() => _LogEditorDialogState();
}

enum _LogEditorStep { form, preview }

class _LogEditorDialogState extends State<_LogEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  _LogEditorStep _step = _LogEditorStep.form;
  late final TextEditingController _tanggalController;
  late final TextEditingController _temaController;
  late final TextEditingController _ringkasanController;
  late final TextEditingController _hasilController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _tanggalController =
        TextEditingController(text: initial?.tanggalKonsultasi ?? '');
    _temaController = TextEditingController(text: initial?.tema ?? '');
    _ringkasanController = TextEditingController(text: initial?.ringkasan ?? '');
    _hasilController = TextEditingController(text: initial?.hasil ?? '');
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _temaController.dispose();
    _ringkasanController.dispose();
    _hasilController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final preview = _step == _LogEditorStep.preview;

    return AlertDialog(
      icon: Icon(
        preview
            ? Icons.fact_check_rounded
            : (isEdit ? Icons.edit_note_rounded : Icons.post_add_rounded),
        color: scheme.primary,
      ),
      title: Text(
        preview
            ? 'Konfirmasi log bimbingan'
            : (isEdit ? 'Ubah log bimbingan' : 'Tambah log bimbingan'),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      content: preview ? _buildPreviewContent(context) : _buildFormContent(context),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actionsAlignment: MainAxisAlignment.end,
      actions: preview
          ? [
              TextButton(
                onPressed: () => setState(() => _step = _LogEditorStep.form),
                child: const Text('Ubah'),
              ),
              FilledButton.icon(
                onPressed: _confirmSubmit,
                icon: const Icon(Icons.check_rounded),
                label: Text(isEdit ? 'Simpan perubahan' : 'Tambahkan'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                onPressed: _goToPreview,
                icon: const Icon(Icons.preview_rounded),
                label: const Text('Lanjut'),
              ),
            ],
    );
  }

  Widget _buildFormContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Lengkapi tanggal dan tema. Ringkasan & hasil membantu melacak konsultasi. '
                'Anda akan melihat ringkasan sebelum data dikirim.',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _dateField(
              context,
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'Tanggal konsultasi wajib diisi';
                if (!_isIsoDate(text)) return 'Format tanggal: YYYY-MM-DD';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _inputField(
              controller: _temaController,
              label: 'Tema',
              hint: 'Topik konsultasi',
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Tema wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _inputField(
              controller: _ringkasanController,
              label: 'Ringkasan',
              hint: 'Ringkasan pembahasan',
              minLines: 3,
              maxLines: 5,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Ringkasan wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _inputField(
              controller: _hasilController,
              label: 'Hasil',
              hint: 'Tindak lanjut / kesimpulan',
              minLines: 2,
              maxLines: 4,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Hasil wajib diisi';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tanggal = _tanggalController.text.trim();
    final tema = _temaController.text.trim();
    final ringkasan = _ringkasanController.text.trim();
    final hasil = _hasilController.text.trim();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Periksa kembali data berikut. Anda dapat mengubah melalui tombol Ubah.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _previewSection(
            context,
            icon: Icons.event_rounded,
            label: 'Tanggal konsultasi',
            body: tanggal,
          ),
          const SizedBox(height: 12),
          _previewSection(
            context,
            icon: Icons.topic_rounded,
            label: 'Tema',
            body: tema,
            emphasizeBody: true,
          ),
          const SizedBox(height: 12),
          _previewSection(
            context,
            icon: Icons.notes_rounded,
            label: 'Ringkasan',
            body: ringkasan,
            multiline: true,
          ),
          const SizedBox(height: 12),
          _previewSection(
            context,
            icon: Icons.task_alt_rounded,
            label: 'Hasil',
            body: hasil,
            multiline: true,
          ),
        ],
      ),
    );
  }

  Widget _previewSection(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String body,
    bool multiline = false,
    bool emphasizeBody = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: (emphasizeBody ? textTheme.titleSmall : textTheme.bodyMedium)?.copyWith(
                fontWeight: emphasizeBody ? FontWeight.w600 : null,
                height: multiline ? 1.4 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required FormFieldValidator<String> validator,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        filled: true,
      ),
      validator: validator,
    );
  }

  Widget _dateField(
    BuildContext context, {
    required FormFieldValidator<String> validator,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: _tanggalController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Tanggal konsultasi',
        hintText: 'YYYY-MM-DD',
        border: const OutlineInputBorder(),
        filled: true,
        suffixIcon: IconButton(
          tooltip: 'Pilih tanggal',
          onPressed: () => _pickDate(context),
          icon: Icon(Icons.calendar_month_rounded, color: scheme.primary),
        ),
      ),
      onTap: () => _pickDate(context),
      validator: validator,
    );
  }

  void _goToPreview() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = _LogEditorStep.preview);
  }

  void _confirmSubmit() {
    final tanggal = _tanggalController.text.trim();
    final tema = _temaController.text.trim();
    final ringkasan = _ringkasanController.text.trim();
    final hasil = _hasilController.text.trim();
    if (tanggal.isEmpty ||
        !_isIsoDate(tanggal) ||
        tema.isEmpty ||
        ringkasan.isEmpty ||
        hasil.isEmpty) {
      setState(() => _step = _LogEditorStep.form);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _formKey.currentState?.validate();
      });
      return;
    }
    Navigator.of(context).pop(
      BimbinganLogDraft(
        tanggalKonsultasi: tanggal,
        tema: tema,
        ringkasan: ringkasan,
        hasil: hasil,
      ),
    );
  }

  bool _isIsoDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return false;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return false;
    if (year < 2000 || year > 2100) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    return true;
  }

  Future<void> _pickDate(BuildContext context) async {
    final initial = _parseIsoDate(_tanggalController.text) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal Konsultasi',
    );
    if (selected == null || !mounted) return;
    _tanggalController.text = _formatIsoDate(selected);
  }

  DateTime? _parseIsoDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final parts = text.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime.tryParse(
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}',
    );
  }

  String _formatIsoDate(DateTime value) {
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}
