enum AbsenceReason { sick, vacation }

class WorkerModel {
  final String id;
  final String lastName; // теперь это ФИО полностью
  final int totalShifts;
  final int mustGive;
  final int overtimeHours;
  final bool shiftGiven;
  final AbsenceReason? absenceReason;
  final int category;
  final List<int> categories;
  final String phone;
  final String photoUrl;

  const WorkerModel({
    required this.id,
    required this.lastName,
    required this.totalShifts,
    required this.mustGive,
    required this.overtimeHours,
    required this.shiftGiven,
    this.absenceReason,
    this.category = 4,
    this.categories = const [4],
    this.phone = '',
    this.photoUrl = '',
  });

  String get shiftStatusText => shiftGiven ? 'Отдал' : 'Не выход';

  String get absenceText {
    if (shiftGiven) return '-';
    switch (absenceReason) {
      case AbsenceReason.sick:
        return 'Болеет';
      case AbsenceReason.vacation:
        return 'Отпуск';
      default:
        return '-';
    }
  }

  WorkerModel copyWith({
    int? totalShifts,
    int? mustGive,
    int? overtimeHours,
    bool? shiftGiven,
    AbsenceReason? absenceReason,
    bool clearAbsence = false,
    int? category,
    List<int>? categories,
    String? phone,
    String? photoUrl,
    String? lastName,
  }) {
    return WorkerModel(
      id: id,
      lastName: lastName ?? this.lastName,
      totalShifts: totalShifts ?? this.totalShifts,
      mustGive: mustGive ?? this.mustGive,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      shiftGiven: shiftGiven ?? this.shiftGiven,
      absenceReason: clearAbsence ? null : (absenceReason ?? this.absenceReason),
      category: category ?? this.category,
      categories: categories ?? this.categories,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    final absenceRaw = json['absence_reason'];
    AbsenceReason? absenceReason;

    if (absenceRaw != null && absenceRaw is String && absenceRaw.isNotEmpty) {
      absenceReason = AbsenceReason.values.firstWhere(
            (e) => e.name == absenceRaw,
        orElse: () => AbsenceReason.sick,
      );
    }

    List<int> categories;
    if (json['categories'] != null) {
      categories = List<int>.from(json['categories']);
    } else if (json['category'] != null) {
      categories = [(json['category'] as num).toInt()];
    } else {
      categories = [4];
    }

    return WorkerModel(
      id: json['id'] as String,
      lastName: json['last_name'] as String,
      totalShifts: (json['total_shifts'] as num).toInt(),
      mustGive: (json['must_give'] as num).toInt(),
      overtimeHours: (json['overtime_hours'] as num).toInt(),
      shiftGiven: json['shift_given'] as bool,
      absenceReason: absenceReason,
      category: (json['category'] as num?)?.toInt() ?? categories.first,
      categories: categories,
      phone: json['phone'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'last_name': lastName,
      'total_shifts': totalShifts,
      'must_give': mustGive,
      'overtime_hours': overtimeHours,
      'shift_given': shiftGiven,
      'absence_reason': absenceReason?.name ?? '',
      'category': category,
      'categories': categories,
      'phone': phone,
      'photo_url': photoUrl,
    };
  }
}