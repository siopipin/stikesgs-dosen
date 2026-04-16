import 'package:flutter/material.dart';

import '../../bimbingan/screen/bimbingan_screen.dart';
import '../../dashboard/screen/home_dashboard_screen.dart';
import '../../jadwal/screen/jadwal_screen.dart';
import '../../penilaian/screen/penilaian_screen.dart';
import '../../presensi/screen/presensi_screen.dart';
import '../../profil/screen/profil_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  // Default tab: Home
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProfilScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeDashboardScreen(
            onNavigateTab: _onTabSelected,
            onOpenProfile: _openProfile,
          ),
          const JadwalScreen(),
          const PresensiScreen(),
          const PenilaianScreen(),
          const BimbinganScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: scheme.surface,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Colors.transparent,
                elevation: 0,
                indicatorColor: scheme.primaryContainer.withValues(alpha: 0.95),
                iconTheme: WidgetStateProperty.resolveWith(
                  (states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      color: selected ? scheme.primary : scheme.onSurfaceVariant,
                      size: selected ? 25 : 23,
                    );
                  },
                ),
                labelTextStyle: WidgetStateProperty.resolveWith(
                  (states) {
                    final selected = states.contains(WidgetState.selected);
                    return theme.textTheme.labelMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    );
                  },
                ),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onTabSelected,
                animationDuration: const Duration(milliseconds: 350),
                height: 72,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: 'Jadwal',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.fact_check_outlined),
                    selectedIcon: Icon(Icons.fact_check_rounded),
                    label: 'Presensi',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.grading_outlined),
                    selectedIcon: Icon(Icons.grading_rounded),
                    label: 'Penilaian',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.forum_outlined),
                    selectedIcon: Icon(Icons.forum_rounded),
                    label: 'Bimbingan',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
