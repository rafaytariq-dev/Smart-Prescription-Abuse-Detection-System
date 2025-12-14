class Prescription {
  final String id;
  final String patientId;
  final String drugName;
  final String drugClass; // e.g., "Opioid", "Benzodiazepine", "Stimulant"
  final int schedule; // DEA Schedule I-V (1-5)
  final double dosage; // in mg
  final int quantity; // number of pills/units
  final DateTime prescribedDate;
  final String doctorId;
  final String doctorName;
  final String pharmacy;
  final DateTime? expectedRefillDate;

  Prescription({
    required this.id,
    required this.patientId,
    required this.drugName,
    required this.drugClass,
    required this.schedule,
    required this.dosage,
    required this.quantity,
    required this.prescribedDate,
    required this.doctorId,
    required this.doctorName,
    required this.pharmacy,
    this.expectedRefillDate,
  });

  // Calculate expected refill date based on quantity and typical dosing
  DateTime calculateExpectedRefillDate() {
    // Assume 1 pill per day for simplicity
    return prescribedDate.add(Duration(days: quantity));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'drugName': drugName,
      'drugClass': drugClass,
      'schedule': schedule,
      'dosage': dosage,
      'quantity': quantity,
      'prescribedDate': prescribedDate.toIso8601String(),
      'doctorId': doctorId,
      'doctorName': doctorName,
      'pharmacy': pharmacy,
      'expectedRefillDate': expectedRefillDate?.toIso8601String(),
    };
  }

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      patientId: json['patientId'],
      drugName: json['drugName'],
      drugClass: json['drugClass'],
      schedule: json['schedule'],
      dosage: json['dosage'].toDouble(),
      quantity: json['quantity'],
      prescribedDate: DateTime.parse(json['prescribedDate']),
      doctorId: json['doctorId'],
      doctorName: json['doctorName'],
      pharmacy: json['pharmacy'],
      expectedRefillDate: json['expectedRefillDate'] != null
          ? DateTime.parse(json['expectedRefillDate'])
          : null,
    );
  }

  Prescription copyWith({
    String? id,
    String? patientId,
    String? drugName,
    String? drugClass,
    int? schedule,
    double? dosage,
    int? quantity,
    DateTime? prescribedDate,
    String? doctorId,
    String? doctorName,
    String? pharmacy,
    DateTime? expectedRefillDate,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      drugName: drugName ?? this.drugName,
      drugClass: drugClass ?? this.drugClass,
      schedule: schedule ?? this.schedule,
      dosage: dosage ?? this.dosage,
      quantity: quantity ?? this.quantity,
      prescribedDate: prescribedDate ?? this.prescribedDate,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      pharmacy: pharmacy ?? this.pharmacy,
      expectedRefillDate: expectedRefillDate ?? this.expectedRefillDate,
    );
  }
}
