enum AlertType {
  doctorShopping,
  earlyRefill,
  excessiveDosage,
  dangerousCombination,
  patternDetected,
  highFrequency,
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

class Alert {
  final String id;
  final String patientId;
  final AlertType alertType;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;
  bool isResolved;
  final double? confidenceScore; // For inductive reasoning alerts (0-100)
  final Map<String, dynamic>? metadata; // Additional context

  Alert({
    required this.id,
    required this.patientId,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.isResolved = false,
    this.confidenceScore,
    this.metadata,
  });

  String get alertTypeString {
    switch (alertType) {
      case AlertType.doctorShopping:
        return 'Doctor Shopping';
      case AlertType.earlyRefill:
        return 'Early Refill';
      case AlertType.excessiveDosage:
        return 'Excessive Dosage';
      case AlertType.dangerousCombination:
        return 'Dangerous Combination';
      case AlertType.patternDetected:
        return 'Pattern Detected';
      case AlertType.highFrequency:
        return 'High Frequency';
    }
  }

  String get severityString {
    switch (severity) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'alertType': alertType.index,
      'severity': severity.index,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isResolved': isResolved,
      'confidenceScore': confidenceScore,
      'metadata': metadata,
    };
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      patientId: json['patientId'],
      alertType: AlertType.values[json['alertType']],
      severity: AlertSeverity.values[json['severity']],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isResolved: json['isResolved'],
      confidenceScore: json['confidenceScore']?.toDouble(),
      metadata: json['metadata'],
    );
  }

  Alert copyWith({
    String? id,
    String? patientId,
    AlertType? alertType,
    AlertSeverity? severity,
    String? message,
    DateTime? timestamp,
    bool? isResolved,
    double? confidenceScore,
    Map<String, dynamic>? metadata,
  }) {
    return Alert(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      alertType: alertType ?? this.alertType,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isResolved: isResolved ?? this.isResolved,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      metadata: metadata ?? this.metadata,
    );
  }
}
