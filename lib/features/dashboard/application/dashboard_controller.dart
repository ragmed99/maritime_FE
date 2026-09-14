import 'package:flutter/foundation.dart';

import '../data/dashboard_repository.dart';
import '../domain/dashboard_models.dart';

enum DashboardStatus { idle, loading, loaded, error }

class DashboardController extends ChangeNotifier {
  DashboardController(this._repository);
  final DashboardDataSource _repository;
  DashboardStatus status = DashboardStatus.idle;
  DashboardData? data;

  Future<void> load() async {
    if (status == DashboardStatus.loading) return;
    status = DashboardStatus.loading;
    notifyListeners();
    try {
      data = await _repository.fetchDashboard();
      status = DashboardStatus.loaded;
    } catch (_) {
      status = DashboardStatus.error;
    }
    notifyListeners();
  }
}
