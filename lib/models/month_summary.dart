class ShiftEntry {
  final String replacedUser;    // кого заменили
  final String replacementUser; // кто заменил
  final int count;              // количество выходов
  final String date;            // дата
  final String type;            // 'fact' (по факту) или 'payment' (по выплате)

  const ShiftEntry({
    required this.replacedUser,
    required this.replacementUser,
    required this.count,
    required this.date,
    required this.type,
  });

  factory ShiftEntry.fromFirestore(Map<String, dynamic> data) {
    return ShiftEntry(
      replacedUser: data['replaced_user'] as String? ?? '',
      replacementUser: data['replacement_user'] as String? ?? '',
      count: (data['count'] as num?)?.toInt() ?? 0,
      date: data['date'] as String? ?? '',
      type: data['type'] as String? ?? 'fact',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'replaced_user': replacedUser,
      'replacement_user': replacementUser,
      'count': count,
      'date': date,
      'type': type,
    };
  }
}

class MonthSummary {
  final String id;          // 'YYYY-MM_userId'
  final String userId;
  final String month;       // 'YYYY-MM'
  final int totalShifts;
  final double ratePerShift;
  final double totalEarnings;
  final List<ShiftEntry> factEntries;
  final List<ShiftEntry> paymentEntries;

  const MonthSummary({
    required this.id,
    required this.userId,
    required this.month,
    this.totalShifts = 0,
    this.ratePerShift = 0,
    this.totalEarnings = 0,
    this.factEntries = const [],
    this.paymentEntries = const [],
  });

  factory MonthSummary.fromFirestore(String id, Map<String, dynamic> data) {
    return MonthSummary(
      id: id,
      userId: data['user_id'] as String? ?? '',
      month: data['month'] as String? ?? '',
      totalShifts: (data['total_shifts'] as num?)?.toInt() ?? 0,
      ratePerShift: (data['rate_per_shift'] as num?)?.toDouble() ?? 0,
      totalEarnings: (data['total_earnings'] as num?)?.toDouble() ?? 0,
      factEntries: (data['fact_entries'] as List<dynamic>?)
          ?.map((e) => ShiftEntry.fromFirestore(e as Map<String, dynamic>))
          .toList() ??
          [],
      paymentEntries: (data['payment_entries'] as List<dynamic>?)
          ?.map((e) => ShiftEntry.fromFirestore(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'month': month,
      'total_shifts': totalShifts,
      'rate_per_shift': ratePerShift,
      'total_earnings': totalEarnings,
      'fact_entries': factEntries.map((e) => e.toFirestore()).toList(),
      'payment_entries': paymentEntries.map((e) => e.toFirestore()).toList(),
    };
  }
  MonthSummary copyWith({
    int? totalShifts,
    double? ratePerShift,
    double? totalEarnings,
    List<ShiftEntry>? factEntries,
    List<ShiftEntry>? paymentEntries,
  }) {
    return MonthSummary(
      id: id,
      userId: userId,
      month: month,
      totalShifts: totalShifts ?? this.totalShifts,
      ratePerShift: ratePerShift ?? this.ratePerShift,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      factEntries: factEntries ?? this.factEntries,
      paymentEntries: paymentEntries ?? this.paymentEntries,
    );
  }
}