class Homework {
  final int id;
  final int schoolId;
  final int classId;
  final String title;
  final String subject;
  final String description;
  final DateTime assignedDate;
  final DateTime dueDate;
  final String assignedBy;
  final String? attachments;

  Homework({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.title,
    required this.subject,
    required this.description,
    required this.assignedDate,
    required this.dueDate,
    required this.assignedBy,
    this.attachments,
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: json['id'],
      schoolId: json['school_id'],
      classId: json['class_id'],
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      assignedDate: DateTime.parse(json['assigned_date']),
      dueDate: DateTime.parse(json['due_date']),
      assignedBy: json['assigned_by'] ?? '',
      attachments: json['attachments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'class_id': classId,
      'title': title,
      'subject': subject,
      'description': description,
      'assigned_date': assignedDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'assigned_by': assignedBy,
      'attachments': attachments,
    };
  }
}
