import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/bimbingan_student_item.dart';
import '../provider/bimbingan_provider.dart';

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
              : FloatingActionButton.extended(
                  onPressed: provider.isSubmitting
                      ? null
                      : () => _openCreateLogDialog(context),
                  label: const Text('Tambah Log'),
                  icon: const Icon(Icons.add_rounded),
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
                const SizedBox(height: 84),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mahasiswa PA', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (provider.isLoading && provider.students.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (provider.students.isEmpty)
              const Text('Belum ada mahasiswa bimbingan.')
            else
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selected?.mhswId,
                decoration: const InputDecoration(
                  labelText: 'Pilih Mahasiswa',
                ),
                items: provider.students
                    .map(
                      (student) => DropdownMenuItem<String>(
                        value: student.mhswId,
                        child: Text(
                          '${student.displayName} • ${student.displayNpm}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: provider.isActionLoading
                    ? null
                    : (value) {
                        if (value == null) return;
                        final student = provider.students.firstWhere((e) => e.mhswId == value);
                        provider.selectStudent(student);
                      },
              ),
            if (selected != null) ...[
              const SizedBox(height: 10),
              _StudentInfoTile(student: selected),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentInfoTile extends StatelessWidget {
  const _StudentInfoTile({required this.student});

  final BimbinganStudentItem student;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              student.displayNpm.isEmpty ? '-' : student.displayNpm,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (student.prodi.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                student.prodi,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LogSection extends StatelessWidget {
  const _LogSection({required this.provider});

  final BimbinganProvider provider;

  @override
  Widget build(BuildContext context) {
    final student = provider.selectedStudent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Log Bimbingan', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  onPressed: student == null || provider.isActionLoading
                      ? null
                      : provider.loadLogs,
                  tooltip: 'Refresh log',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            if (student == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Pilih mahasiswa untuk melihat log bimbingan.'),
              )
            else if (provider.isActionLoading && provider.logs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.logs.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Belum ada log bimbingan untuk mahasiswa ini.'),
              )
            else
              ...provider.logs.map(
                (log) => _LogItemTile(
                  item: log,
                  isBusy: provider.isSubmitting,
                  onEdit: () => _openEditLog(context, provider, log),
                  onDelete: () => _deleteLog(context, provider, log),
                ),
              ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.tema.isEmpty ? 'Tanpa Tema' : item.tema,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Text(
                      item.tanggalKonsultasi.isEmpty ? '-' : item.tanggalKonsultasi,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.ringkasan.isEmpty ? '-' : item.ringkasan,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Hasil: ${item.hasil.isEmpty ? '-' : item.hasil}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Semantics(
                    button: true,
                    label: 'Edit log ${item.tema}',
                    child: TextButton.icon(
                      onPressed: isBusy ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: 'Hapus log ${item.tema}',
                    child: TextButton.icon(
                      onPressed: isBusy ? null : onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

class _LogEditorDialogState extends State<_LogEditorDialog> {
  final _formKey = GlobalKey<FormState>();
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
    return AlertDialog(
      title: Text(isEdit ? 'Ubah Log Bimbingan' : 'Tambah Log Bimbingan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dateField(
                context,
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'Tanggal konsultasi wajib diisi';
                  if (!_isIsoDate(text)) return 'Format tanggal: YYYY-MM-DD';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _inputField(
                controller: _temaController,
                label: 'Tema',
                hint: 'Tema bimbingan',
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Tema wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _inputField(
                controller: _ringkasanController,
                label: 'Ringkasan',
                hint: 'Ringkasan konsultasi',
                minLines: 3,
                maxLines: 4,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Ringkasan wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _inputField(
                controller: _hasilController,
                label: 'Hasil',
                hint: 'Hasil / tindak lanjut',
                minLines: 2,
                maxLines: 3,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Hasil wajib diisi';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Simpan'),
        ),
      ],
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
      ),
      validator: validator,
    );
  }

  Widget _dateField(
    BuildContext context, {
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: _tanggalController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Tanggal Konsultasi',
        hintText: 'YYYY-MM-DD',
        suffixIcon: IconButton(
          tooltip: 'Pilih tanggal',
          onPressed: () => _pickDate(context),
          icon: const Icon(Icons.calendar_month_rounded),
        ),
      ),
      onTap: () => _pickDate(context),
      validator: validator,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      BimbinganLogDraft(
        tanggalKonsultasi: _tanggalController.text.trim(),
        tema: _temaController.text.trim(),
        ringkasan: _ringkasanController.text.trim(),
        hasil: _hasilController.text.trim(),
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
