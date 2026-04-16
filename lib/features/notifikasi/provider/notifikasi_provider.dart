import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../model/notifikasi_item.dart';
import '../service/notifikasi_service.dart';

class NotifikasiProvider extends ChangeNotifier {
  NotifikasiProvider(this._service);

  final NotifikasiService _service;

  bool _initialized = false;
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  int _unreadTotal = 0;
  List<NotifikasiItem> _items = <NotifikasiItem>[];

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  int get unreadTotal => _unreadTotal;
  List<NotifikasiItem> get items => _items;

  Future<void> ensureLoaded() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _service.getNotifications(),
        _service.getUnreadTotal(),
      ]);
      _items = results[0] as List<NotifikasiItem>;
      _unreadTotal = results[1] as int;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Notifikasi belum dapat dimuat.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsRead(NotifikasiItem item) async {
    if (item.isRead || item.id == 0) return true;
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index == -1) return false;

    final oldValue = _items[index];
    _items[index] = oldValue.copyWith(isRead: true);
    if (_unreadTotal > 0) _unreadTotal -= 1;
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.markAsRead(id: item.id);
      return true;
    } on ApiException catch (error) {
      _items[index] = oldValue;
      _unreadTotal += 1;
      _errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      _items[index] = oldValue;
      _unreadTotal += 1;
      _errorMessage = 'Gagal menandai notifikasi.';
      notifyListeners();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
