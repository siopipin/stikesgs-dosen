import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/global_config.dart';
import '../provider/profil_provider.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _handphoneController = TextEditingController();
  final TextEditingController _passwordLamaController = TextEditingController();
  final TextEditingController _passwordBaruController = TextEditingController();

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
    _passwordLamaController.dispose();
    _passwordBaruController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                icon: const Icon(Icons.refresh_rounded),
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

    final imageUrl = profil.foto.isEmpty ? '' : '${AppConfig.fotoDosen}/${profil.foto}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage:
                            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty
                            ? Text(
                                _avatarInitial(profil.nama),
                                style: Theme.of(context).textTheme.headlineMedium,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
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
                          icon: const Icon(Icons.camera_alt_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profil.nama,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIDN: ${profil.nidn}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Informasi Profil', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _ReadOnlyField(label: 'Nama', value: profil.nama),
                  const SizedBox(height: 8),
                  _ReadOnlyField(label: 'NIDN', value: profil.nidn),
                  const SizedBox(height: 8),
                  _ReadOnlyField(label: 'Gelar', value: profil.gelar),
                  const SizedBox(height: 8),
                  _ReadOnlyField(label: 'Program Studi', value: profil.prodi),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !provider.isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Masukkan email',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _handphoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !provider.isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Handphone',
                      hintText: 'Masukkan nomor handphone',
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
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
                    child: provider.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('Simpan Profil'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Ubah Password', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordLamaController,
                    obscureText: true,
                    enabled: !provider.isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Password Lama',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordBaruController,
                    obscureText: true,
                    enabled: !provider.isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Password Baru',
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: provider.isSubmitting
                        ? null
                        : () async {
                            final oldPassword = _passwordLamaController.text.trim();
                            final newPassword = _passwordBaruController.text.trim();

                            if (oldPassword.isEmpty || newPassword.isEmpty) {
                              _showSnack(context, 'Password lama dan baru wajib diisi.');
                              return;
                            }
                            if (newPassword.length < 6) {
                              _showSnack(context, 'Password baru minimal 6 karakter.');
                              return;
                            }

                            final ok = await provider.updatePassword(
                              passwordLama: oldPassword,
                              passwordBaru: newPassword,
                            );
                            if (!mounted) return;
                            _showSnack(
                              context,
                              ok
                                  ? 'Password berhasil diperbarui.'
                                  : (provider.errorMessage ?? 'Gagal memperbarui password.'),
                            );
                            if (ok) {
                              _passwordLamaController.clear();
                              _passwordBaruController.clear();
                            }
                          },
                    child: const Text('Simpan Password'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
      ),
      child: Text(
        value.isEmpty ? '-' : value,
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
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
