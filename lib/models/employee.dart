class Employee {
  int? id;
  String name;
  String phone;
  String email;
  String address;
  String position;
  double salary;
  DateTime joiningDate;
  bool isActive;

  Employee({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.position,
    required this.salary,
    required this.joiningDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'position': position,
      'salary': salary,
      'joiningDate': joiningDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      position: map['position'],
      salary: map['salary'],
      joiningDate: DateTime.parse(map['joiningDate']),
      isActive: map['isActive'] == 1,
    );
  }
}
