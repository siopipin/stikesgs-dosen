import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard/model/teaching_schedule_item.dart';
import '../../dashboard/provider/home_dashboard_provider.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  bool _todayOnly = true;

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
        final schedules = _todayOnly
            ? provider.schedules
                  .where(
                    (item) =>
                        item.namaHari.toLowerCase() ==
                        _dayName(DateTime.now().weekday).toLowerCase(),
                  )
                  .toList()
            : provider.schedules;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Jadwal Mengajar'),
            actions: [
              IconButton(
                onPressed: provider.isLoading ? null : provider.refresh,
                tooltip: 'Refresh jadwal',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(58),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _JadwalFilterBar(
                  todayOnly: _todayOnly,
                  onChanged: (value) => setState(() => _todayOnly = value),
                ),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ScheduleSummary(
                  todayOnly: _todayOnly,
                  totalFiltered: schedules.length,
                  todayName: _dayName(DateTime.now().weekday),
                ),
                const SizedBox(height: 12),
                if (provider.isLoading && provider.schedules.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (provider.errorMessage != null &&
                    provider.schedules.isEmpty)
                  _ErrorState(
                    message: provider.errorMessage!,
                    onRetry: provider.refresh,
                  )
                else if (schedules.isEmpty)
                  const _EmptyState()
                else
                  ...schedules.map((item) => _JadwalCard(item: item)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _dayName(int weekday) {
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada jadwal.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ScheduleSummary extends StatelessWidget {
  const _ScheduleSummary({
    required this.todayOnly,
    required this.totalFiltered,
    required this.todayName,
  });

  final bool todayOnly;
  final int totalFiltered;
  final String todayName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = todayOnly ? 'Jadwal $todayName' : 'Semua Jadwal';
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: scheme.primaryContainer,
              ),
              child: Icon(Icons.calendar_month_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '$totalFiltered kelas',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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

class _JadwalCard extends StatelessWidget {
  const _JadwalCard({required this.item});

  final TeachingScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label:
          'Jadwal ${item.namaMk}, hari ${item.namaHari}, jam ${item.jamMulai} sampai ${item.jamSelesai}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: scheme.primaryContainer,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${item.sks}',
                        style: textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'sks',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaMk,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.namaHari} · ${item.jamMulai} – ${item.jamSelesai}',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      if (item.ruang.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.ruang,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _JadwalFilterBar extends StatelessWidget {
  const _JadwalFilterBar({
    required this.todayOnly,
    required this.onChanged,
  });

  final bool todayOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterToggleButton(
              label: 'Hari Ini',
              icon: Icons.today_rounded,
              isSelected: todayOnly,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _FilterToggleButton(
              label: 'Semua',
              icon: Icons.view_list_rounded,
              isSelected: !todayOnly,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterToggleButton extends StatelessWidget {
  const _FilterToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedBg = scheme.primary.withValues(alpha: 0.14);
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Filter jadwal $label',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? selectedBg : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
