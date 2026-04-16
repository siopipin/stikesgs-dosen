import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../notifikasi/screen/notifikasi_screen.dart';
import '../model/announcement_item.dart';
import '../model/teaching_schedule_item.dart';
import '../provider/home_dashboard_provider.dart';

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
                onOpenNotifications: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotifikasiScreen(),
                    ),
                  );
                  if (!context.mounted) return;
                  await context.read<HomeDashboardProvider>().refresh();
                },
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
                  jumlahPenilaian: provider.schedules.isNotEmpty
                      ? provider.schedules.length
                      : 0,
                  onSelectTab: widget.onNavigateTab,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AnnouncementPanel(
                  items: announcements,
                  onViewAll: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotifikasiScreen(),
                      ),
                    );
                    if (!context.mounted) return;
                    await context.read<HomeDashboardProvider>().refresh();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  TeachingScheduleItem? _pickTodaySchedule(
    List<TeachingScheduleItem> schedules,
  ) {
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
    required this.onOpenNotifications,
  });

  final String lecturerName;
  final int unreadCount;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateLabel =
        '${_indonesianDayName(now.weekday)}, ${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B57D0), Color(0xFF00639A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
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
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'STIKESGS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Buka notifikasi',
                child: InkWell(
                  onTap: onOpenNotifications,
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            child: const Icon(
                              Icons.notifications_none,
                              color: Colors.white,
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: -2,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
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
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Buka profil dosen',
                child: InkWell(
                  onTap: onOpenProfile,
                  borderRadius: BorderRadius.circular(30),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Selamat Datang, $lecturerName',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _greetingByTime(),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dateLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
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

  String _greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}

class _TodayScheduleCard extends StatelessWidget {
  const _TodayScheduleCard({required this.schedule, required this.onTap});

  final TeachingScheduleItem? schedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasData = schedule != null;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Buka tab jadwal mengajar',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0B7D65), Color(0xFF149A7D)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Hari Ini',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: scheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasData
                            ? schedule!.namaMk
                            : 'Belum ada jadwal hari ini.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasData) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${schedule!.jamMulai} - ${schedule!.jamSelesai} • ${schedule!.ruang}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (!hasData) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Tap untuk lihat semua jadwal.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
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
        semanticLabel: 'jadwal hari ini',
        value: '$jadwalHariIni',
        color: const Color(0xFF0B7D65),
        gradientEndColor: const Color(0xFF149A7D),
        icon: Icons.calendar_today_rounded,
        targetTabIndex: 1,
      ),
      _StatCardData(
        title: 'SKS\nDiampu',
        semanticLabel: 'rekap sks diampu',
        value: '$totalSks',
        color: const Color(0xFFDD8A00),
        gradientEndColor: const Color(0xFFF4A321),
        icon: Icons.assignment_rounded,
        targetTabIndex: 2,
      ),
      _StatCardData(
        title: 'Mahasiswa\nPA',
        semanticLabel: 'daftar mahasiswa pa',
        value: '$jumlahPa',
        color: const Color(0xFF2A67C7),
        gradientEndColor: const Color(0xFF4F82D6),
        icon: Icons.groups_rounded,
        targetTabIndex: 4,
      ),
      _StatCardData(
        title: 'Jadwal\nPenilaian',
        semanticLabel: 'jadwal penilaian',
        value: '$jumlahPenilaian',
        color: const Color(0xFFB8405E),
        gradientEndColor: const Color(0xFFCC5D79),
        icon: Icons.schedule_rounded,
        targetTabIndex: 3,
      ),
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemBuilder: (_, index) => _StatCard(
        item: items[index],
        onTap: () => onSelectTab(items[index].targetTabIndex),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item, required this.onTap});

  final _StatCardData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.title.replaceAll('\n', ' ');
    return Semantics(
      button: true,
      label: 'Buka ${item.semanticLabel}',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [item.color, item.gradientEndColor],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 39,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                item.icon,
                color: Colors.white.withValues(alpha: 0.92),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.title,
    required this.semanticLabel,
    required this.value,
    required this.color,
    required this.gradientEndColor,
    required this.icon,
    required this.targetTabIndex,
  });

  final String title;
  final String semanticLabel;
  final String value;
  final Color color;
  final Color gradientEndColor;
  final IconData icon;
  final int targetTabIndex;
}

class _AnnouncementPanel extends StatelessWidget {
  const _AnnouncementPanel({required this.items, required this.onViewAll});

  final List<AnnouncementItem> items;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: scheme.surface,
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
                Text(
                  '${items.length} item',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.isRead
                            ? Icons.drafts_rounded
                            : Icons.markunread_rounded,
                        size: 18,
                        color: item.isRead
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.primary,
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
            Semantics(
              button: true,
              label: 'Lihat semua notifikasi',
              child: OutlinedButton(
                onPressed: onViewAll,
                child: const Text('Lihat Semua'),
              ),
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
  const _DashboardErrorView({required this.message, required this.onRetry});

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
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
