class Finance {
  final int id;
  final int schoolId;
  final double amount;
  final String? reason;
  final String type;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Finance({
    required this.id,
    required this.schoolId,
    required this.amount,
    this.reason,
    required this.type,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Finance.fromJson(Map<String, dynamic> json) {
    return Finance(
      id: json['id'],
      schoolId: json['school_id'],
      amount: json['amount'],
      reason: json['reason'],
      type: json['type'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
