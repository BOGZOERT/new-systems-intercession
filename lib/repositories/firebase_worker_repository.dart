import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import 'worker_repository.dart';

class FirebaseWorkerRepository implements IWorkerRepository {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('workers');

  @override
  Future<List<WorkerModel>> fetchAll() async {
    print('🔥 Запрашиваю данные из Firestore...');

    final snapshot = await _collection.orderBy('last_name').get();

    print('🔥 Получено документов: ${snapshot.docs.length}');

    if (snapshot.docs.isEmpty) {
      print('🔥 Коллекция workers пустая!');
      return [];
    }

    final workers = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      print('🔥 Документ ${doc.id}: $data');
      return WorkerModel.fromJson({
        'id': doc.id,
        ...data,
      });
    }).toList();

    print('🔥 Всего работников загружено: ${workers.length}');
    return workers;
  }

  @override
  Future<void> update(WorkerModel worker) async {
    print('🔥 Обновляю документ ${worker.id}');
    await _collection.doc(worker.id).update(worker.toJson());
    print('🔥 Документ ${worker.id} обновлён');
  }
}