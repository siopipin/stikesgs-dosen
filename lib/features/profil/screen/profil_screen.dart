import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/global_config.dart';
import '../../auth/provider/session_provider.dart';
import '../provider/profil_provider.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _handphoneController = TextEditingController();

  String _lastProfileKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfilProvider>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _handphoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSessionSubmitting = context.select<SessionProvider, bool>(
      (session) => session.isSubmitting,
    );
    return Consumer<ProfilProvider>(
      builder: (context, provider, _) {
        final profil = provider.profil;
        if (profil != null) {
          final profileKey = '${profil.login}-${profil.email}-${profil.handphone}-${profil.foto}';
          if (_lastProfileKey != profileKey) {
            _lastProfileKey = profileKey;
            _emailController.text = profil.email;
            _handphoneController.text = profil.handphone;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil Dosen'),
            actions: [
              IconButton(
                onPressed: provider.isSubmitting ? null : provider.loadProfil,
                tooltip: 'Refresh profil',
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                onPressed: provider.isSubmitting || isSessionSubmitting
                    ? null
                    : () => _onExitPressed(context),
                tooltip: 'Exit',
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: provider.isLoading && profil == null
              ? const Center(child: CircularProgressIndicator())
              : provider.errorMessage != null && profil == null
                  ? _ErrorState(
                      message: provider.errorMessage!,
                      onRetry: provider.loadProfil,
                    )
                  : _buildContent(context, provider),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ProfilProvider provider) {
    final profil = provider.profil;
    if (profil == null) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final imageUrl = profil.foto.isEmpty ? '' : '${AppConfig.fotoDosen}/${profil.foto}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 0,
            color: scheme.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: scheme.primaryContainer,
                        backgroundImage:
                            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty
                            ? Text(
                                _avatarInitial(profil.nama),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                    ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: IconButton.filledTonal(
                          onPressed: provider.isSubmitting
                              ? null
                              : () async {
                                  final ok = await provider.pickAndUploadPhoto();
                                  if (!mounted) return;
                                  _showSnack(
                                    context,
                                    ok
                                        ? 'Foto profil berhasil diperbarui.'
                                        : (provider.errorMessage ?? 'Gagal memperbarui foto.'),
                                  );
                                },
                          tooltip: 'Ubah foto',
                          icon: const Icon(Icons.camera_alt_rounded),
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profil.nama,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'NIDN ${profil.nidn}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
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
                      Icon(Icons.badge_outlined, color: scheme.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Informasi profil',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Data identitas bersifat hanya baca. Email dan nomor dapat diperbarui.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                  _ReadOnlyField(label: 'Nama', value: profil.nama),
                  const SizedBox(height: 10),
                  _ReadOnlyField(label: 'NIDN', value: profil.nidn),
                  const SizedBox(height: 10),
                  _ReadOnlyField(label: 'Gelar', value: profil.gelar),
                  const SizedBox(height: 10),
                  _ReadOnlyField(label: 'Program Studi', value: profil.prodi),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !provider.isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Masukkan email',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _handphoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !provider.isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Handphone',
                      hintText: 'Masukkan nomor handphone',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: provider.isSubmitting
                        ? null
                        : () async {
                            final ok = await provider.updateProfil(
                              email: _emailController.text.trim(),
                              handphone: _handphoneController.text.trim(),
                            );
                            if (!mounted) return;
                            _showSnack(
                              context,
                              ok
                                  ? 'Profil berhasil diperbarui.'
                                  : (provider.errorMessage ?? 'Gagal memperbarui profil.'),
                            );
                          },
                    icon: provider.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(provider.isSubmitting ? 'Menyimpan…' : 'Simpan profil'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
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
                      Icon(Icons.lock_outline_rounded, color: scheme.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Keamanan',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ganti password masuk akun. Anda akan diminta konfirmasi sebelum disimpan.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    button: true,
                    label: 'Ubah password akun',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.password_rounded, color: scheme.primary),
                      title: const Text('Ubah password'),
                      subtitle: Text(
                        'Memerlukan password saat ini',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                      onTap: provider.isSubmitting
                          ? null
                          : () => _openChangePasswordDialog(context, provider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChangePasswordDialog(
    BuildContext context,
    ProfilProvider provider,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ChangePasswordDialog(provider: provider),
    );
    if (ok == true && context.mounted) {
      _showSnack(context, 'Password berhasil diperbarui.');
    }
  }

  String _avatarInitial(String name) {
    final value = name.trim();
    if (value.isEmpty) return 'D';
    return value.substring(0, 1).toUpperCase();
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onExitPressed(BuildContext context) async {
    final confirmed = await _confirmExitDialog(context);
    if (!confirmed || !context.mounted) return;

    await context.read<SessionProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<bool> _confirmExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Exit aplikasi?'),
          content: const Text(
            'Sesi login dan data lokal akan dihapus dari perangkat ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

enum _PwdStep { form, confirm }

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.provider});

  final ProfilProvider provider;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  _PwdStep _step = _PwdStep.form;

  final _lamaController = TextEditingController();
  final _baruController = TextEditingController();
  final _ulangController = TextEditingController();

  bool _obscureLama = true;
  bool _obscureBaru = true;
  bool _obscureUlang = true;

  @override
  void dispose() {
    _lamaController.dispose();
    _baruController.dispose();
    _ulangController.dispose();
    super.dispose();
  }

  void _goPreview() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _step = _PwdStep.confirm);
  }

  Future<void> _submitConfirmed() async {
    final lama = _lamaController.text.trim();
    final baru = _baruController.text.trim();
    final ok = await widget.provider.updatePassword(
      passwordLama: lama,
      passwordBaru: baru,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.provider.errorMessage ?? 'Gagal memperbarui password.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final preview = _step == _PwdStep.confirm;
    final busy = widget.provider.isSubmitting;

    return AlertDialog(
      icon: Icon(
        preview ? Icons.fact_check_rounded : Icons.password_rounded,
        color: scheme.primary,
      ),
      title: Text(preview ? 'Konfirmasi ubah password' : 'Ubah password'),
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      content: preview ? _buildConfirmBody(scheme, textTheme) : _buildFormBody(scheme, textTheme),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actionsAlignment: MainAxisAlignment.end,
      actions: preview
          ? [
              TextButton(
                onPressed: busy ? null : () => setState(() => _step = _PwdStep.form),
                child: const Text('Ubah'),
              ),
              FilledButton.icon(
                onPressed: busy ? null : _submitConfirmed,
                icon: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(busy ? 'Menyimpan…' : 'Konfirmasi'),
              ),
            ]
          : [
              TextButton(
                onPressed: busy ? null : () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                onPressed: busy ? null : _goPreview,
                icon: const Icon(Icons.preview_rounded),
                label: const Text('Lanjut'),
              ),
            ],
    );
  }

  Widget _buildFormBody(ColorScheme scheme, TextTheme textTheme) {
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
                'Gunakan password kuat. Anda akan melihat ringkasan sebelum perubahan dikirim.',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lamaController,
              obscureText: _obscureLama,
              enabled: !widget.provider.isSubmitting,
              decoration: InputDecoration(
                labelText: 'Password saat ini',
                border: const OutlineInputBorder(),
                filled: true,
                suffixIcon: IconButton(
                  tooltip: _obscureLama ? 'Tampilkan' : 'Sembunyikan',
                  onPressed: () => setState(() => _obscureLama = !_obscureLama),
                  icon: Icon(_obscureLama ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'Password saat ini wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _baruController,
              obscureText: _obscureBaru,
              enabled: !widget.provider.isSubmitting,
              decoration: InputDecoration(
                labelText: 'Password baru',
                border: const OutlineInputBorder(),
                filled: true,
                suffixIcon: IconButton(
                  tooltip: _obscureBaru ? 'Tampilkan' : 'Sembunyikan',
                  onPressed: () => setState(() => _obscureBaru = !_obscureBaru),
                  icon: Icon(_obscureBaru ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Password baru wajib diisi';
                if (t.length < 6) return 'Minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ulangController,
              obscureText: _obscureUlang,
              enabled: !widget.provider.isSubmitting,
              decoration: InputDecoration(
                labelText: 'Ulangi password baru',
                border: const OutlineInputBorder(),
                filled: true,
                suffixIcon: IconButton(
                  tooltip: _obscureUlang ? 'Tampilkan' : 'Sembunyikan',
                  onPressed: () => setState(() => _obscureUlang = !_obscureUlang),
                  icon: Icon(_obscureUlang ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              validator: (v) {
                final u = (v ?? '').trim();
                final b = _baruController.text.trim();
                if (u != b) return 'Password baru tidak sama';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmBody(ColorScheme scheme, TextTheme textTheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Password akun akan diganti. Pastikan password saat ini sudah benar dan Anda mengingat password baru.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Ringkasan',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Password baru: ${_baruController.text.trim().length} karakter',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Isi password tidak ditampilkan demi keamanan.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: const OutlineInputBorder(),
        enabled: false,
      ),
      child: Text(
        value.isEmpty ? '—' : value,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
