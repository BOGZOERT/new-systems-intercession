class SwapRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final int fromCategory;
  final String date;           // дата смены, которую хотят заменить
  final String toUserId;       // кому адресован запрос (3 категория)
  final String toUserName;
  final String status;         // 'pending', 'accepted', 'rejected'
  final String newDate;        // дата, на которую меняют (выбирает 3 категория)
  final DateTime createdAt;

  const SwapRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromCategory,
    required this.date,
    required this.toUserId,
    required this.toUserName,
    required this.status,
    this.newDate = '',
    required this.createdAt,
  });

  factory SwapRequest.fromFirestore(String id, Map<String, dynamic> data) {
    return SwapRequest(
      id: id,
      fromUserId: data['from_user_id'] as String? ?? '',
      fromUserName: data['from_user_name'] as String? ?? '',
      fromCategory: (data['from_category'] as num?)?.toInt() ?? 4,
      date: data['date'] as String? ?? '',
      toUserId: data['to_user_id'] as String? ?? '',
      toUserName: data['to_user_name'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      newDate: data['new_date'] as String? ?? '',
      createdAt: (data['created_at'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'from_user_id': fromUserId,
      'from_user_name': fromUserName,
      'from_category': fromCategory,
      'date': date,
      'to_user_id': toUserId,
      'to_user_name': toUserName,
      'status': status,
      'new_date': newDate,
      'created_at': DateTime.now(),
    };
  }
}