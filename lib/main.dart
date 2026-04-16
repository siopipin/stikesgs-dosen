import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/global_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/app_prefs.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/provider/session_provider.dart';
import 'features/auth/screen/login_screen.dart';
import 'features/auth/screen/splash_screen.dart';
import 'features/auth/service/auth_service.dart';
import 'features/bimbingan/provider/bimbingan_provider.dart';
import 'features/bimbingan/service/bimbingan_service.dart';
import 'features/dashboard/provider/home_dashboard_provider.dart';
import 'features/dashboard/service/dashboard_service.dart';
import 'features/home/screen/home_shell_screen.dart';
import 'features/penilaian/provider/penilaian_provider.dart';
import 'features/penilaian/service/penilaian_service.dart';
import 'features/presensi/provider/presensi_provider.dart';
import 'features/presensi/service/presensi_service.dart';
import 'features/profil/provider/profil_provider.dart';
import 'features/profil/service/profil_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPrefs.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs});

  final AppPrefs prefs;

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(prefs: prefs);
    final authService = AuthService(apiClient);
    final dashboardService = DashboardService(apiClient);
    final bimbinganService = BimbinganService(apiClient);
    final penilaianService = PenilaianService(apiClient);
    final presensiService = PresensiService(apiClient);
    final profilService = ProfilService(apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SessionProvider(
            prefs: prefs,
            authService: authService,
            apiClient: apiClient,
          )..initializeSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeDashboardProvider(dashboardService),
        ),
        ChangeNotifierProvider(
          create: (_) => PresensiProvider(presensiService),
        ),
        ChangeNotifierProvider(
          create: (_) => PenilaianProvider(penilaianService),
        ),
        ChangeNotifierProvider(
          create: (_) => BimbinganProvider(bimbinganService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfilProvider(profilService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConfig.appName,
        theme: AppTheme.light,
        home: const _StartupGate(),
      ),
    );
  }
}

class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        if (session.isInitializing) {
          return const SplashScreen();
        }

        if (session.isAuthenticated) {
          return const HomeShellScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
