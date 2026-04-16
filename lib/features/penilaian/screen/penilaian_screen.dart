import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/penilaian_schedule_item.dart';
import '../model/penilaian_student_item.dart';
import '../provider/penilaian_provider.dart';

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
                onPressed: provider.isActionLoading ? null : provider.refreshAll,
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
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
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
  const _FilterSection({
    required this.provider,
    required this.tahunController,
  });

  final PenilaianProvider provider;
  final TextEditingController tahunController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter Penilaian',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: tahunController,
              enabled: !provider.isActionLoading,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tahun Akademik',
                hintText: 'Contoh: 20251',
              ),
              onSubmitted: (_) => _loadSchedules(context),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: provider.isActionLoading ? null : () => _loadSchedules(context),
              icon: const Icon(Icons.filter_alt_rounded),
              label: const Text('Muat Jadwal Penilaian'),
            ),
            const SizedBox(height: 12),
            if (provider.isLoading && provider.schedules.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (provider.schedules.isEmpty)
              const Text('Jadwal penilaian belum tersedia.')
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
                          item.displayLabel,
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
                        final selected = provider.schedules.firstWhere(
                          (item) => item.jadwalId == value,
                        );
                        provider.selectSchedule(selected);
                      },
              ),
            if (provider.selectedSchedule != null) ...[
              const SizedBox(height: 10),
              _CoordinatorInfo(provider: provider),
            ],
          ],
        ),
      ),
    );
  }

  void _loadSchedules(BuildContext context) {
    final provider = context.read<PenilaianProvider>();
    provider.setTahunId(tahunController.text);
    provider.loadSchedules();
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
    final colorScheme = Theme.of(context).colorScheme;

    final color = !hasJenis
        ? colorScheme.secondary
        : isCoordinator
            ? Colors.green
            : colorScheme.error;
    final message = !hasJenis
        ? 'Jenis dosen tidak dikirim backend. Input nilai tetap akan diverifikasi server.'
        : isCoordinator
            ? 'Anda dosen koordinator ($jenis), input nilai diizinkan.'
            : 'Anda bukan koordinator ($jenis). Input nilai dikunci.';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Daftar Nilai Mahasiswa',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: selected == null || provider.isActionLoading
                      ? null
                      : provider.loadStudents,
                  tooltip: 'Refresh mahasiswa',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            if (selected == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Pilih jadwal terlebih dahulu.'),
              )
            else if (provider.isActionLoading && provider.students.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.students.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Belum ada mahasiswa pada jadwal ini.'),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${provider.students.length} mahasiswa',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              ...provider.students.map(
                (item) => _StudentScoreTile(
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
                              : (provider.errorMessage ?? 'Simpan nilai gagal.'),
                        ),
                      ),
                    );
                  },
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

  @override
  Widget build(BuildContext context) {
    final npm = item.npm.isEmpty ? item.mhswId : item.npm;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.nama.isEmpty ? 'Mahasiswa' : item.nama,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                npm.isEmpty ? '-' : npm,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _scoreChip('T1', item.tugas1),
                  _scoreChip('T2', item.tugas2),
                  _scoreChip('T3', item.tugas3),
                  _scoreChip('T4', item.tugas4),
                  _scoreChip('T5', item.tugas5),
                  _scoreChip('UTS', item.uts),
                  _scoreChip('UAS', item.uas),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Semantics(
                  label: 'Ubah nilai ${item.nama}',
                  button: true,
                  child: FilledButton.tonalIcon(
                    onPressed: canEdit ? onEdit : null,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Ubah Nilai'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreChip(String label, int? value) {
    return Chip(
      label: Text('$label: ${value?.toString() ?? '-'}'),
      visualDensity: VisualDensity.compact,
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.student.nama.isEmpty ? 'Input Nilai' : widget.student.nama,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _scoreField(controller: _t1, label: 'Tugas 1'),
              const SizedBox(height: 8),
              _scoreField(controller: _t2, label: 'Tugas 2'),
              const SizedBox(height: 8),
              _scoreField(controller: _t3, label: 'Tugas 3'),
              const SizedBox(height: 8),
              _scoreField(controller: _t4, label: 'Tugas 4'),
              const SizedBox(height: 8),
              _scoreField(controller: _t5, label: 'Tugas 5'),
              const SizedBox(height: 8),
              _scoreField(controller: _uts, label: 'UTS'),
              const SizedBox(height: 8),
              _scoreField(controller: _uas, label: 'UAS'),
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

  Widget _scoreField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: '0 - 100',
      ),
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) return 'Nilai wajib diisi';
        final number = int.tryParse(text);
        if (number == null) return 'Nilai harus berupa angka';
        if (number < 0 || number > 100) return 'Rentang nilai 0-100';
        return null;
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      NilaiDraft(
        tugas1: int.parse(_t1.text.trim()),
        tugas2: int.parse(_t2.text.trim()),
        tugas3: int.parse(_t3.text.trim()),
        tugas4: int.parse(_t4.text.trim()),
        tugas5: int.parse(_t5.text.trim()),
        uts: int.parse(_uts.text.trim()),
        uas: int.parse(_uas.text.trim()),
      ),
    );
  }

  String _init(int? value) => value?.toString() ?? '';
}
