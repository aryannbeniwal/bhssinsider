class Event {
  int? id;
  String title;
  String description;
  DateTime eventDate;
  String location;
  DateTime createdAt;

  Event({
    this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'location': location,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      eventDate: DateTime.parse(map['eventDate']),
      location: map['location'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
