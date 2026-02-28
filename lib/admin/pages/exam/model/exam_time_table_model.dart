class ExamTimeTable {
  final int? id;
  final int schoolId;
  final int classId;
  final String examTitle;
  final dynamic subjects;
  final dynamic date;
  final dynamic session;
  final String createdBy;

  ExamTimeTable({
    this.id,
    required this.schoolId,
    required this.classId,
    required this.examTitle,
    required this.subjects,
    required this.date,
    required this.session,
    required this.createdBy,
  });

  factory ExamTimeTable.fromJson(Map<String, dynamic> json) {
    return ExamTimeTable(
      id: json['id'],
      schoolId: json['school_id'],
      classId: json['class_id'],
      examTitle: json['exam_title'],
      subjects: json['subjects'],
      date: json['date'],
      session: json['session'],
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "school_id": schoolId,
      "class_id": classId,
      "exam_title": examTitle,
      "subjects": subjects,
      "date": date,
      "session": session,
      "created_by": createdBy,
    };
  }
}
