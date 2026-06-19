import 'package:flutter/foundation.dart';
import '../models/worker_model.dart';
import '../models/app_user.dart';
import '../repositories/worker_repository.dart';

class TableProvider extends ChangeNotifier {
  final IWorkerRepository _repository;

  AppRole _role = AppRole.user;
  List<WorkerModel> _allWorkers = [];
  bool _isLoading = false;
  String? _errorMessage;

  TableProvider({required IWorkerRepository repository})
      : _repository = repository {
    _loadData();
  }

  AppRole get role => _role;
  List<WorkerModel> get allWorkers => _allWorkers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Установить роль из AuthProvider
  void setRoleFromAuth(AppRole role) {
    _role = role;
    notifyListeners();
  }

  List<WorkerModel> get visibleWorkers {
    switch (_role) {
      case AppRole.developer:
        return _allWorkers;
      case AppRole.admin:
        return _allWorkers;
      case AppRole.user:
        return _allWorkers
            .where((w) => w.absenceReason != AbsenceReason.vacation)
            .toList();
    }
  }

  Future<void> _loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allWorkers = await _repository.fetchAll();
    } catch (e) {
      _errorMessage = 'Ошибка загрузки: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateWorker(String id, WorkerModel updated) async {
    final index = _allWorkers.indexWhere((w) => w.id == id);
    if (index != -1) {
      _allWorkers[index] = updated;
      notifyListeners();
    }

    try {
      await _repository.update(updated);
    } catch (e) {
      _errorMessage = 'Ошибка сохранения: $e';
      await _loadData();
    }
  }

  Future<void> refresh() => _loadData();
}