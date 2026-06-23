class SwapRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final int fromCategory;
  final String date;
  final String toUserId;
  final String toUserName;
  final String status;
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
      'created_at': DateTime.now(),
    };
  }
}