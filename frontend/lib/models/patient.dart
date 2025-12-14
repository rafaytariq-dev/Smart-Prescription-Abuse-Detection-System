class Patient {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final String address;
  final String phone;
  double riskScore; // 0-100

  Patient({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.address,
    required this.phone,
    this.riskScore = 0.0,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  String get riskLevel {
    if (riskScore < 30) return 'Low';
    if (riskScore < 60) return 'Medium';
    return 'High';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'address': address,
      'phone': phone,
      'riskScore': riskScore,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      address: json['address'],
      phone: json['phone'],
      riskScore: json['riskScore'].toDouble(),
    );
  }

  Patient copyWith({
    String? id,
    String? name,
    DateTime? dateOfBirth,
    String? address,
    String? phone,
    double? riskScore,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      riskScore: riskScore ?? this.riskScore,
    );
  }
}
