class Message {
  final int id;
  final String messages;
  final String? date;
  final int schoolId;

  Message({
    required this.id,
    required this.messages,
    this.date,
    required this.schoolId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      messages: json['messages'],
      date: json['date'],
      schoolId: json['school_id'],
    );
  }
}
