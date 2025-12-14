import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/prescription.dart';
import '../models/alert.dart';
import 'ml_service.dart';

class AnalysisResult {
  final List<Alert> alerts;
  final bool mlRan;
  final String? mlError;

  AnalysisResult({
    required this.alerts,
    required this.mlRan,
    this.mlError,
  });
}

/// Inductive Reasoning Engine
/// Uses statistical analysis and pattern detection to identify emerging abuse patterns
class InductiveReasoningEngine {
  final uuid = const Uuid();
  final MLService _mlService = MLService();

  /// Analyze prescriptions using inductive reasoning to detect patterns
  Future<AnalysisResult> analyzePatterns(
    String patientId,
    List<Prescription> prescriptions,
  ) async {
    List<Alert> alerts = [];
    bool mlRan = false;
    String? mlError;

    if (prescriptions.length < 3) {
      return AnalysisResult(alerts: alerts, mlRan: false, mlError: 'Not enough data');
    }

    // Sort prescriptions by date
    final sortedPrescriptions = List<Prescription>.from(prescriptions)
      ..sort((a, b) => a.prescribedDate.compareTo(b.prescribedDate));

    // Pattern 1: Temporal Pattern Detection
    alerts.addAll(_detectTemporalPatterns(patientId, sortedPrescriptions));

    // Pattern 2: Dosage Escalation Pattern
    alerts.addAll(_detectEscalationPattern(patientId, sortedPrescriptions));

    // Pattern 3: Geographic/Pharmacy Pattern
    alerts.addAll(_detectPharmacyPattern(patientId, sortedPrescriptions));

    // Pattern 4: Behavioral Clustering
    alerts.addAll(_detectBehavioralAnomalies(patientId, sortedPrescriptions));

    // Pattern 5: Inductive Dosage Anomaly (Smart Dosage Check)
    alerts.addAll(_detectDosageAnomaly(patientId, sortedPrescriptions));

    // Pattern 6: ML-Based Inductive Reasoning
    try {
      await _analyzeWithML(patientId, sortedPrescriptions, alerts);
      mlRan = true;
    } catch (e) {
      mlRan = false;
      mlError = e.toString();
    }

    return AnalysisResult(alerts: alerts, mlRan: mlRan, mlError: mlError);
  }

  /// Pattern 5: Detect dosage anomalies based on patient's personal history
  List<Alert> _detectDosageAnomaly(
      String patientId, List<Prescription> prescriptions) {
    List<Alert> alerts = [];

    // Group by drug name
    Map<String, List<Prescription>> drugGroups = {};
    for (var prescription in prescriptions) {
      drugGroups.putIfAbsent(prescription.drugName, () => []).add(prescription);
    }

    drugGroups.forEach((drugName, drugPrescriptions) {
      // Need at least 3 past prescriptions to establish a baseline
      if (drugPrescriptions.length < 4) return;

      // Sort by date
      drugPrescriptions.sort((a, b) => a.prescribedDate.compareTo(b.prescribedDate));

      // Get the latest prescription (the one we are analyzing)
      final current = drugPrescriptions.last;
      
      // Get history (excluding current)
      final history = drugPrescriptions.sublist(0, drugPrescriptions.length - 1);

      // Calculate Mean and Standard Deviation
      double sum = 0;
      for (var p in history) sum += p.dosage;
      final mean = sum / history.length;

      double varianceSum = 0;
      for (var p in history) varianceSum += pow(p.dosage - mean, 2);
      final variance = varianceSum / history.length;
      final stdDev = sqrt(variance);

      // Threshold: Mean + 2 Standard Deviations (95% confidence interval)
      // If stdDev is 0 (all past doses same), allow a small buffer (e.g., 10% increase)
      final threshold = stdDev == 0 ? mean * 1.1 : mean + (2 * stdDev);

      if (current.dosage > threshold) {
        final deviation = ((current.dosage - mean) / mean) * 100;
        final confidence = min(95.0, deviation); // Higher deviation = higher confidence

        alerts.add(Alert(
          id: uuid.v4(),
          patientId: patientId,
          alertType: AlertType.excessiveDosage, // Reusing type but with AI source
          severity: AlertSeverity.high,
          message: 'Abnormal Dosage Spike: ${current.dosage}mg is significantly higher than patient\'s average of ${mean.toStringAsFixed(1)}mg (+$deviation% increase).',
          timestamp: DateTime.now(),
          confidenceScore: confidence,
          metadata: {
            'source': 'Inductive_AI', // This tag triggers the AI badge
            'drugName': drugName,
            'currentDosage': current.dosage,
            'averageDosage': mean,
            'standardDeviation': stdDev,
          },
        ));
      }
    });

    return alerts;
  }

  Future<void> _analyzeWithML(
      String patientId, List<Prescription> prescriptions, List<Alert> alerts) async {
    
    // Check if ML service is available
    bool isServiceAvailable = await _mlService.checkHealth();
    if (!isServiceAvailable) {
      throw Exception("ML Service unavailable");
    }

    // Get Prediction
    RiskPrediction? prediction = await _mlService.predictRiskScore(prescriptions);
    
    if (prediction != null) {
      // Create an alert if risk is high or medium
      if (prediction.riskLevel == 'High' || prediction.riskLevel == 'Medium') {
        alerts.add(Alert(
          id: uuid.v4(),
          patientId: patientId,
          alertType: AlertType.patternDetected,
          severity: prediction.riskLevel == 'High' ? AlertSeverity.high : AlertSeverity.medium,
          message: 'ML-Detected Risk Pattern: The AI model detected a ${prediction.riskLevel} risk pattern based on prescription history.',
          timestamp: DateTime.now(),
          confidenceScore: prediction.confidence,
          metadata: {
            'source': 'ML_Model',
            'risk_score': prediction.riskScore,
            'factors': prediction.probabilities.toString(),
          },
        ));
      }
    } else {
       throw Exception("Prediction failed");
    }
  }

  /// Pattern 1: Detect temporal patterns (e.g., always requesting on specific days)
  List<Alert> _detectTemporalPatterns(
      String patientId, List<Prescription> prescriptions) {
    List<Alert> alerts = [];

    // Analyze day of week patterns
    Map<int, int> dayOfWeekCount = {};
    for (var prescription in prescriptions) {
      final dayOfWeek = prescription.prescribedDate.weekday;
      dayOfWeekCount[dayOfWeek] = (dayOfWeekCount[dayOfWeek] ?? 0) + 1;
    }

    // Check if >70% of prescriptions are on the same day of week
    dayOfWeekCount.forEach((day, count) {
      final percentage = (count / prescriptions.length) * 100;
      if (percentage > 70 && prescriptions.length >= 5) {
        final dayName = _getDayName(day);
        final confidence = percentage;

        alerts.add(Alert(
          id: uuid.v4(),
          patientId: patientId,
          alertType: AlertType.patternDetected,
          severity: AlertSeverity.medium,
          message: 'Temporal Pattern Detected: $percentage% of prescriptions obtained on $dayName. This may indicate planned behavior.',
          timestamp: DateTime.now(),
          confidenceScore: confidence,
          metadata: {
            'pattern': 'temporal',
            'dayOfWeek': dayName,
            'percentage': percentage.toStringAsFixed(1),
            'occurrences': count,
          },
        ));
      }
    });

    // Analyze time intervals between prescriptions
    if (prescriptions.length >= 4) {
      List<int> intervals = [];
      for (int i = 1; i < prescriptions.length; i++) {
        final interval = prescriptions[i]
            .prescribedDate
            .difference(prescriptions[i - 1].prescribedDate)
            .inDays;
        intervals.add(interval);
      }

      // Calculate standard deviation
      final mean = intervals.reduce((a, b) => a + b) / intervals.length;
      final variance = intervals
              .map((x) => pow(x - mean, 2))
              .reduce((a, b) => a + b) /
          intervals.length;
      final stdDev = sqrt(variance);

      // If intervals are very consistent (low std dev), it's suspicious
      if (stdDev < 3 && mean > 0 && mean < 30) {
        final confidence = min(95.0, 100 - (stdDev * 10));

        alerts.add(Alert(
          id: uuid.v4(),
          patientId: patientId,
          alertType: AlertType.patternDetected,
          severity: AlertSeverity.medium,
          message: 'Regular Interval Pattern: Prescriptions obtained every ${mean.toStringAsFixed(1)} days with minimal variation. Suggests calculated behavior.',
          timestamp: DateTime.now(),
          confidenceScore: confidence,
          metadata: {
            'pattern': 'regular_intervals',
            'averageInterval': mean.toStringAsFixed(1),
            'standardDeviation': stdDev.toStringAsFixed(2),
          },
        ));
      }
    }

    return alerts;
  }

  /// Pattern 2: Detect dosage escalation over time
  List<Alert> _detectEscalationPattern(
      String patientId, List<Prescription> prescriptions) {
    List<Alert> alerts = [];

    // Group by drug name
    Map<String, List<Prescription>> drugGroups = {};
    for (var prescription in prescriptions) {
      drugGroups.putIfAbsent(prescription.drugName, () => []).add(prescription);
    }

    // Check each drug for escalation
    drugGroups.forEach((drugName, drugPrescriptions) {
      if (drugPrescriptions.length < 3) return;

      drugPrescriptions.sort((a, b) => a.prescribedDate.compareTo(b.prescribedDate));

      // Check if dosage is consistently increasing
      int increases = 0;
      for (int i = 1; i < drugPrescriptions.length; i++) {
        if (drugPrescriptions[i].dosage > drugPrescriptions[i - 1].dosage) {
          increases++;
        }
      }

      final increaseRate = increases / (drugPrescriptions.length - 1);
      
      // If >60% of changes are increases
      if (increaseRate > 0.6 && increases >= 2) {
        final firstDosage = drugPrescriptions.first.dosage;
        final lastDosage = drugPrescriptions.last.dosage;
        final percentageIncrease = ((lastDosage - firstDosage) / firstDosage) * 100;
        final confidence = min(95.0, increaseRate * 100);

        alerts.add(Alert(
          id: uuid.v4(),
          patientId: patientId,
          alertType: AlertType.patternDetected,
          severity: AlertSeverity.high,
          message: 'Dosage Escalation Detected: Dosage for $drugName increased from ${firstDosage}mg to ${lastDosage}mg (${percentageIncrease.toStringAsFixed(1)}% increase).',
          timestamp: DateTime.now(),
          confidenceScore: confidence,
          metadata: {
            'pattern': 'escalation',
            'drugName': drugName,
            'initialDosage': firstDosage,
            'currentDosage': lastDosage,
            'percentageIncrease': percentageIncrease.toStringAsFixed(1),
            'numberOfIncreases': increases,
          },
        ));
      }
    });

    return alerts;
  }

  /// Pattern 3: Detect pharmacy hopping patterns
  List<Alert> _detectPharmacyPattern(
      String patientId, List<Prescription> prescriptions) {
    List<Alert> alerts = [];

    // Count unique pharmacies
    final uniquePharmacies = prescriptions.map((p) => p.pharmacy).toSet();

    // If using many different pharmacies
    if (uniquePharmacies.length > 4 && prescriptions.length >= 6) {
      final ratio = uniquePharmacies.length / prescriptions.length;
      final confidence = min(95.0, ratio * 150);

      alerts.add(Alert(
        id: uuid.v4(),
        patientId: patientId,
        alertType: AlertType.patternDetected,
        severity: AlertSeverity.medium,
        message: 'Pharmacy Hopping Detected: ${uniquePharmacies.length} different pharmacies used for ${prescriptions.length} prescriptions.',
        timestamp: DateTime.now(),
        confidenceScore: confidence,
        metadata: {
          'pattern': 'pharmacy_hopping',
          'pharmacyCount': uniquePharmacies.length,
          'prescriptionCount': prescriptions.length,
          'pharmacies': uniquePharmacies.toList(),
        },
      ));
    }

    return alerts;
  }

  /// Pattern 4: Detect behavioral anomalies using statistical clustering
  List<Alert> _detectBehavioralAnomalies(
      String patientId, List<Prescription> prescriptions) {
    List<Alert> alerts = [];

    // Calculate prescription velocity (prescriptions per month)
    if (prescriptions.length >= 3) {
      final firstDate = prescriptions.first.prescribedDate;
      final lastDate = prescriptions.last.prescribedDate;
      final monthsDifference = lastDate.difference(firstDate).inDays / 30.0;

      if (monthsDifference > 0) {
        final velocity = prescriptions.length / monthsDifference;

        // If getting >3 prescriptions per month on average
        if (velocity > 3.0) {
          final confidence = min(95.0, (velocity / 5.0) * 100);

          alerts.add(Alert(
            id: uuid.v4(),
            patientId: patientId,
            alertType: AlertType.patternDetected,
            severity: AlertSeverity.medium,
            message: 'High Prescription Velocity: ${velocity.toStringAsFixed(1)} prescriptions per month on average. Significantly above normal usage patterns.',
            timestamp: DateTime.now(),
            confidenceScore: confidence,
            metadata: {
              'pattern': 'high_velocity',
              'prescriptionsPerMonth': velocity.toStringAsFixed(1),
              'totalPrescriptions': prescriptions.length,
              'timeSpanMonths': monthsDifference.toStringAsFixed(1),
            },
          ));
        }
      }
    }

    // Detect sudden behavior changes
    if (prescriptions.length >= 6) {
      final midpoint = prescriptions.length ~/ 2;
      final firstHalf = prescriptions.sublist(0, midpoint);
      final secondHalf = prescriptions.sublist(midpoint);

      final firstHalfDoctors = firstHalf.map((p) => p.doctorId).toSet().length;
      final secondHalfDoctors = secondHalf.map((p) => p.doctorId).toSet().length;

      // If number of doctors doubled in second half
      if (secondHalfDoctors >= firstHalfDoctors * 2 && secondHalfDoctors >= 3) {
        final confidence = min(90.0, (secondHalfDoctors / firstHalfDoctors) * 40);

        alerts.add(Alert(
          id: uuid.v4(),
          patientId: patientId,
          alertType: AlertType.patternDetected,
          severity: AlertSeverity.high,
          message: 'Behavioral Shift Detected: Sudden increase in doctor diversity from $firstHalfDoctors to $secondHalfDoctors doctors.',
          timestamp: DateTime.now(),
          confidenceScore: confidence,
          metadata: {
            'pattern': 'behavioral_shift',
            'earlyDoctorCount': firstHalfDoctors,
            'recentDoctorCount': secondHalfDoctors,
          },
        ));
      }
    }

    return alerts;
  }

  String _getDayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[day - 1];
  }
}
