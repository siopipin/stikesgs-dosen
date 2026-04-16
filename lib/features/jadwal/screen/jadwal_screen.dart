import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                  (item) => item.namaHari.toLowerCase() ==
                      _dayName(DateTime.now().weekday).toLowerCase(),
                )
                .toList()
            : provider.schedules;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Jadwal Mengajar'),
          ),
          body: RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Hari Ini'),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Semua'),
                    ),
                  ],
                  selected: <bool>{_todayOnly},
                  onSelectionChanged: (selection) {
                    setState(() => _todayOnly = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                if (provider.isLoading && provider.schedules.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (provider.errorMessage != null && provider.schedules.isEmpty)
                  _ErrorState(
                    message: provider.errorMessage!,
                    onRetry: provider.refresh,
                  )
                else if (schedules.isEmpty)
                  const _EmptyState()
                else
                  ...schedules.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(item.sks.toString()),
                        ),
                        title: Text(item.namaMk),
                        subtitle: Text(
                          '${item.namaHari}, ${item.jamMulai}-${item.jamSelesai} • ${item.ruang}',
                        ),
                      ),
                    ),
                  ),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
