import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/worker_model.dart';
import '../data/fake_workers.dart';

/// Интерфейс репозитория — контракт, который не зависит от источника данных
abstract class IWorkerRepository {
  Future<List<WorkerModel>> fetchAll();
  Future<void> update(WorkerModel worker);
// для будущего:
// Future<void> add(WorkerModel worker);
// Future<void> delete(String id);
}

/// Реализация с фейковыми данными (для разработки)
class FakeWorkerRepository implements IWorkerRepository {
  // Внутри храним копию, чтобы изменения сохранялись в течение сессии
  final List<WorkerModel> _workers = List.from(fakeWorkers);

  @override
  Future<List<WorkerModel>> fetchAll() async {
    // Имитируем задержку сети
    await Future.delayed(const Duration(milliseconds: 300));
    return _workers;
  }

  @override
  Future<void> update(WorkerModel worker) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _workers.indexWhere((w) => w.id == worker.id);
    if (index != -1) {
      _workers[index] = worker;
    }
  }
}

/// ЗАГОТОВКА для настоящего API (раскомментируешь, когда появится сервер)

class ApiWorkerRepository implements IWorkerRepository {
  final String baseUrl = 'https://твой-сервер.com/api';

  @override
  Future<List<WorkerModel>> fetchAll() async {
    final response = await http.get(Uri.parse('$baseUrl/workers'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => WorkerModel.fromJson(json)).toList();
    }
    throw Exception('Ошибка загрузки: ${response.statusCode}');
  }

  @override
  Future<void> update(WorkerModel worker) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workers/${worker.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(worker.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Ошибка обновления: ${response.statusCode}');
    }
  }
}
