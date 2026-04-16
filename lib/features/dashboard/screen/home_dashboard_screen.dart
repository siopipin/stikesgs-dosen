import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../model/announcement_item.dart';
import '../model/teaching_schedule_item.dart';
import '../provider/home_dashboard_provider.dart';
import 'announcement_list_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    super.key,
    required this.onNavigateTab,
    required this.onOpenProfile,
  });

  final ValueChanged<int> onNavigateTab;
  final VoidCallback onOpenProfile;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeDashboardProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeDashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.summary == null) {
          return const _DashboardLoadingView();
        }

        if (provider.errorMessage != null && provider.summary == null) {
          return _DashboardErrorView(
            message: provider.errorMessage!,
            onRetry: provider.refresh,
          );
        }

        final summary = provider.summary;
        final todaySchedule = _pickTodaySchedule(provider.schedules);
        final announcements = provider.announcements.take(3).toList();

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _DashboardHeader(
                lecturerName: summary?.nama.isNotEmpty == true
                    ? summary!.nama
                    : 'Dosen',
                unreadCount: summary?.jumlahNotifAkademik ?? 0,
                onOpenProfile: widget.onOpenProfile,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _TodayScheduleCard(
                  schedule: todaySchedule,
                  onTap: () => widget.onNavigateTab(1),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _QuickStatGrid(
                  jadwalHariIni: summary?.jumlahJadwalHariIni ?? 0,
                  totalSks: summary?.totalSksSemester ?? 0,
                  jumlahPa: summary?.jumlahMhsBimbingan ?? 0,
                  jumlahPenilaian:
                      provider.schedules.isNotEmpty ? provider.schedules.length : 0,
                  onSelectTab: widget.onNavigateTab,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AnnouncementPanel(
                  items: announcements,
                  onViewAll: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AnnouncementListScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  TeachingScheduleItem? _pickTodaySchedule(List<TeachingScheduleItem> schedules) {
    if (schedules.isEmpty) return null;

    final dayName = _indonesianDayName(DateTime.now().weekday);
    for (final item in schedules) {
      if (item.namaHari.toLowerCase() == dayName.toLowerCase()) {
        return item;
      }
    }
    return schedules.first;
  }

  String _indonesianDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return '';
    }
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.lecturerName,
    required this.unreadCount,
    required this.onOpenProfile,
  });

  final String lecturerName;
  final int unreadCount;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B57D0), Color(0xFF00639A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  AppAssets.logo,
                  width: 44,
                  height: 44,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.school, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RuangDosen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'STIKESGS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.notifications_none, color: Colors.white),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onOpenProfile,
                borderRadius: BorderRadius.circular(30),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white30,
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Selamat Datang, $lecturerName',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '${_greetingByTime()}!',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }

  String _greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Good Morning';
    if (hour < 15) return 'Good Afternoon';
    if (hour < 19) return 'Good Evening';
    return 'Good Night';
  }
}

class _TodayScheduleCard extends StatelessWidget {
  const _TodayScheduleCard({
    required this.schedule,
    required this.onTap,
  });

  final TeachingScheduleItem? schedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasData = schedule != null;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Hari Ini',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasData
                          ? '${schedule!.jamMulai} - ${schedule!.jamSelesai} | ${schedule!.namaMk} | ${schedule!.ruang}'
                          : 'Belum ada jadwal hari ini.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatGrid extends StatelessWidget {
  const _QuickStatGrid({
    required this.jadwalHariIni,
    required this.totalSks,
    required this.jumlahPa,
    required this.jumlahPenilaian,
    required this.onSelectTab,
  });

  final int jadwalHariIni;
  final int totalSks;
  final int jumlahPa;
  final int jumlahPenilaian;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatCardData(
        title: 'Jadwal\nHari Ini',
        value: '$jadwalHariIni',
        color: const Color(0xFF0B7D65),
        icon: Icons.calendar_today_rounded,
        targetTabIndex: 1,
      ),
      _StatCardData(
        title: 'SKS\nDiampu',
        value: '$totalSks',
        color: const Color(0xFFDD8A00),
        icon: Icons.assignment_rounded,
        targetTabIndex: 2,
      ),
      _StatCardData(
        title: 'Mahasiswa\nPA',
        value: '$jumlahPa',
        color: const Color(0xFF2A67C7),
        icon: Icons.groups_rounded,
        targetTabIndex: 4,
      ),
      _StatCardData(
        title: 'Jadwal\nPenilaian',
        value: '$jumlahPenilaian',
        color: const Color(0xFFB8405E),
        icon: Icons.schedule_rounded,
        targetTabIndex: 3,
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.35,
      ),
      itemBuilder: (_, index) => _StatCard(
        item: items[index],
        onTap: () => onSelectTab(items[index].targetTabIndex),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.item,
    required this.onTap,
  });

  final _StatCardData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Text(
              item.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
            Icon(item.icon, color: Colors.white70, size: 29),
          ],
        ),
      ),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.targetTabIndex,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final int targetTabIndex;
}

class _AnnouncementPanel extends StatelessWidget {
  const _AnnouncementPanel({
    required this.items,
    required this.onViewAll,
  });

  final List<AnnouncementItem> items;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pengumuman Kampus',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Icon(
                  Icons.more_horiz_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Belum ada pengumuman terbaru.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              ...items.map((item) {
                final text = item.title.toString();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.isRead ? Icons.drafts_rounded : Icons.markunread_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: onViewAll,
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoadingView extends StatelessWidget {
  const _DashboardLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _DashboardErrorView extends StatelessWidget {
  const _DashboardErrorView({
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
