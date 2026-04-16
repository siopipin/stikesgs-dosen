import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/notifikasi_item.dart';
import '../provider/notifikasi_provider.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotifikasiProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotifikasiProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifikasi'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: _UnreadBadge(count: provider.unreadTotal),
                ),
              ),
              IconButton(
                onPressed: provider.isActionLoading ? null : provider.refresh,
                tooltip: 'Refresh notifikasi',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.isLoading && provider.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.errorMessage != null && provider.items.isEmpty)
                  _ErrorState(
                    message: provider.errorMessage!,
                    onRetry: provider.refresh,
                  )
                else if (provider.items.isEmpty)
                  const _EmptyState()
                else
                  ...provider.items.map(
                    (item) => _NotifikasiCard(
                      item: item,
                      isBusy: provider.isActionLoading,
                      onMarkRead: () async {
                        final ok = await provider.markAsRead(item);
                        if (!context.mounted || ok) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.errorMessage ?? 'Gagal menandai notifikasi.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: count > 0
            ? theme.colorScheme.error.withValues(alpha: 0.14)
            : theme.colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        count > 99 ? '99+' : '$count unread',
        style: theme.textTheme.labelMedium?.copyWith(
          color: count > 0 ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NotifikasiCard extends StatelessWidget {
  const _NotifikasiCard({
    required this.item,
    required this.isBusy,
    required this.onMarkRead,
  });

  final NotifikasiItem item;
  final bool isBusy;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.isRead ? Icons.drafts_rounded : Icons.markunread_rounded,
                  color: item.isRead
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.judul,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusChip(isRead: item.isRead),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.pesan,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (item.createdAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.createdAt,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (!item.isRead) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Semantics(
                  button: true,
                  label: 'Tandai notifikasi sebagai dibaca',
                  child: TextButton.icon(
                    onPressed: isBusy ? null : onMarkRead,
                    icon: const Icon(Icons.done_rounded),
                    label: const Text('Tandai Dibaca'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isRead});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final color = isRead ? Colors.green : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
      ),
      child: Text(
        isRead ? 'Sudah dibaca' : 'Belum dibaca',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
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
            Icons.notifications_none_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada notifikasi.',
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
