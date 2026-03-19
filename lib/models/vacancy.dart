class Vacancy {
  int? id;
  String position;
  String description;
  String requirements;
  int openings;
  String location;
  double? salaryRange;
  bool isActive;
  DateTime createdAt;

  Vacancy({
    this.id,
    required this.position,
    required this.description,
    required this.requirements,
    required this.openings,
    required this.location,
    this.salaryRange,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'position': position,
      'description': description,
      'requirements': requirements,
      'openings': openings,
      'location': location,
      'salaryRange': salaryRange,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Vacancy.fromMap(Map<String, dynamic> map) {
    return Vacancy(
      id: map['id'],
      position: map['position'],
      description: map['description'],
      requirements: map['requirements'],
      openings: map['openings'],
      location: map['location'],
      salaryRange: map['salaryRange'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
