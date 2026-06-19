import '../models/worker_model.dart';

List<WorkerModel> fakeWorkers = [
  WorkerModel(id: '1', lastName: 'Иванов',   totalShifts: 15, mustGive: 2, overtimeHours: 8,  shiftGiven: true),
  WorkerModel(id: '2', lastName: 'Петров',   totalShifts: 12, mustGive: 3, overtimeHours: 0,  shiftGiven: false, absenceReason: AbsenceReason.sick),
  WorkerModel(id: '3', lastName: 'Сидорова', totalShifts: 10, mustGive: 5, overtimeHours: 12, shiftGiven: false, absenceReason: AbsenceReason.vacation),
  WorkerModel(id: '4', lastName: 'Козлов',   totalShifts: 20, mustGive: 1, overtimeHours: 4,  shiftGiven: false), // Не выход без причины
  WorkerModel(id: '5', lastName: 'Морозова', totalShifts: 18, mustGive: 0, overtimeHours: 16, shiftGiven: true),
  // ... добавь ещё 15-20 фамилий для объёма
];