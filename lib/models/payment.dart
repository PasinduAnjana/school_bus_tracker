class Payment {
  final String id;
  final String studentId;
  final String month;
  final bool paid;

  Payment({
    required this.id,
    required this.studentId,
    required this.month,
    required this.paid,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      month: map['month'] as String,
      paid: map['paid'] as bool,
    );
  }
}
