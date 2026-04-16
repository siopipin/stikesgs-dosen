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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
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
    );
  }
}
