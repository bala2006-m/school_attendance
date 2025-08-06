class Staff {
  final String username;
  final String name;
  final String email;
  final String gender;
  final String mobile;
  final String designation;
  final int schoolId;

  Staff({
    required this.schoolId,
    required this.username,
    required this.name,
    required this.email,
    required this.gender,
    required this.mobile,
    required this.designation,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      schoolId: json['school_id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      gender: json['gender'] ?? '',
      mobile: json['mobile'],
      designation: json['designation'],
    );
  }
}
