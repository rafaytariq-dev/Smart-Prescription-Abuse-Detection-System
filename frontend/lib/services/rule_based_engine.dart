import '../models/prescription.dart';
import '../models/alert.dart';
import 'package:uuid/uuid.dart';

/// Rule-Based Inference Engine
/// Applies predefined rules to detect immediate red flags in prescription patterns
class RuleBasedEngine {
  final uuid = const Uuid();

  /// Analyze prescriptions and return triggered alerts
  List<Alert> analyzePatient(
    String patientId,
    List<Prescription> prescriptions,
  ) {
    List<Alert> alerts = [];

    if (prescriptions.isEmpty) return alerts;

    // Sort prescriptions by date (newest first)
    final sortedPrescriptions = List<Prescription>.from(prescriptions)
      ..sort((a, b) => b.prescribedDate.compareTo(a.prescribedDate));

    // Rule 1: Early Refill Detection
    alerts.addAll(_checkEarlyRefill(patientId, sortedPrescriptions));

    // Rule 2: Doctor Shopping Detection
    alerts.addAll(_checkDoctorShopping(patientId, sortedPrescriptions));

    // Rule 3: Excessive Dosage Detection
    alerts.addAll(_checkExcessiveDosage(patientId, sortedPrescriptions));

    // Rule 4: Dangerous Drug Combination Detection
    alerts.addAll(_checkDangerousCombinations(patientId, sortedPrescriptions));

    // Rule 5: High Frequency Detection
    alerts.addAll(_checkHighFrequency(patientId, sortedPrescriptions));

    return alerts;
  }

  /// Rule 1: Check for early refills (>30% earlier than expected)
  List<Alert> _checkEarlyRefill(
      String patientId, List<Prescription> prescriptions) {
    List<Alert> alerts = [];
    
    // Group by drug name
    Map<String, List<Prescription>> drugGroups = {};
    for (var prescription in prescriptions) {
      drugGroups.putIfAbsent(prescription.drugName, () => []).add(prescription);
    }

    // Check each drug group for early refills
    drugGroups.forEach((drugName, drugPrescriptions) {
      if (drugPrescriptions.length < 2) return;

      drugPrescriptions.sort((a, b) => a.prescribedDate.compareTo(b.prescribedDate));

      for (int i = 1; i < drugPrescriptions.length; i++) {
        final previous = drugPrescriptions[i - 1];
        final current = drugPrescriptions[i];

        final expectedRefill = previous.calculateExpectedRefillDate();
        final actualRefill = current.prescribedDate;
        final daysDifference = expectedRefill.difference(actualRefill).inDays;

        // If refilled more than 30% early
        if (daysDifference > (previous.quantity * 0.3)) {
          alerts.add(Alert(
            id: uuid.v4(),
            patientId: patientId,
            alertType: AlertType.earlyRefill,
            severity: AlertSeverity.high,
            message:
                'Early refill detected for $drugName. Refilled $daysDifference days early (expected: ${expectedRefill.toString().split(' ')[0]}, actual: ${actualRefill.toString().split(' ')[0]})',
            timestamp: DateTime.now(),
            metadata: {
              'drugName': drugName,
              'daysEarly': daysDifference,
              'expectedDate': expectedRefill.toIso8601String(),
              'actualDate': actualRefill.toIso8601String(),
            },
          ));
        }
      }
    });

    return alerts;
  }

  /// Rule 2: Check for doctor shopping (>3 different doctors for same drug class in 30 days)
  List<Alert> _checkDoctorShopping(
      String patientId, List<Prescription> prescriptions) {
    List<Alert> alerts = [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Get recent prescriptions
    final recentPrescriptions = prescriptions
        .where((p) => p.prescribedDate.isAfter(thirtyDaysAgo))
        .toList();

    // Group by drug class
    Map<String, Set<String>> doctorsByDrugClass = {};
    Map<String, List<String>> drugNamesByClass = {};

    for (var prescription in recentPrescriptions) {
      doctorsByDrugClass
          .putIfAbsent(prescription.drugClass, () => {})
          .add(prescription.doctorId);
      drugNamesByClass
          .putIfAbsent(prescription.drugClass, () => [])
          .add(prescription.drugName);
    }

    // Check if any drug class has >3 different doctors
    doctorsByDrugClass.forEach((drugClass, doctors) {
      if (doctors.length > 3) {
        alerts.add(Alert(
          id: uuid.v4(),
          patientId: patientId,
          alertType: AlertType.doctorShopping,
          severity: AlertSeverity.critical,
          message:
              'Doctor shopping detected: ${doctors.length} different doctors prescribed $drugClass in the last 30 days',
          timestamp: DateTime.now(),
          metadata: {
            'drugClass': drugClass,
            'doctorCount': doctors.length,
            'drugs': drugNamesByClass[drugClass]?.toSet().toList(),
          },
        ));
      }
    });

    return alerts;
  }

  /// Rule 3: Check for excessive dosages
  List<Alert> _checkExcessiveDosage(
      String patientId, List<Prescription> prescriptions) {
    List<Alert> alerts = [];

    // Define maximum daily doses for common controlled substances (in mg)
    final Map<String, double> maxDailyDoses = {
      'Oxycodone': 80.0,
      'Hydrocodone': 60.0,
      'Morphine': 200.0,
      'Fentanyl': 1.2,
      'Alprazolam': 4.0,
      'Diazepam': 40.0,
      'Adderall': 40.0,
      'Ritalin': 60.0,
    };

    for (var prescription in prescriptions) {
      final maxDose = maxDailyDoses[prescription.drugName];
      if (maxDose != null && prescription.dosage > maxDose) {
        final excessPercentage =
            ((prescription.dosage - maxDose) / maxDose * 100).toStringAsFixed(1);
        
        alerts.add(Alert(
          id: uuid.v4(),
          patientId: patientId,
          alertType: AlertType.excessiveDosage,
          severity: AlertSeverity.high,
          message:
              'Excessive dosage detected for ${prescription.drugName}: ${prescription.dosage}mg exceeds maximum recommended daily dose of ${maxDose}mg.',
          timestamp: DateTime.now(),
          metadata: {
            'drugName': prescription.drugName,
            'prescribedDosage': prescription.dosage,
            'maxDosage': maxDose,
            'excessPercentage': excessPercentage,
          },
        ));
      }
    }

    return alerts;
  }

  /// Rule 4: Check for dangerous drug combinations
  List<Alert> _checkDangerousCombinations(
      String patientId, List<Prescription> prescriptions) {
    List<Alert> alerts = [];
    final now = DateTime.now();

    // Check for concurrent prescriptions (within 30 days of each other)
    for (int i = 0; i < prescriptions.length; i++) {
      for (int j = i + 1; j < prescriptions.length; j++) {
        final p1 = prescriptions[i];
        final p2 = prescriptions[j];

        final daysDifference =
            (p1.prescribedDate.difference(p2.prescribedDate).inDays).abs();

        // If prescribed within 30 days
        if (daysDifference <= 30) {
          // Check for opioid + benzodiazepine combination
          if ((p1.drugClass == 'Opioid' && p2.drugClass == 'Benzodiazepine') ||
              (p1.drugClass == 'Benzodiazepine' && p2.drugClass == 'Opioid')) {
            alerts.add(Alert(
              id: uuid.v4(),
              patientId: patientId,
              alertType: AlertType.dangerousCombination,
              severity: AlertSeverity.critical,
              message:
                  'Dangerous combination: Concurrent prescription of ${p1.drugName} (${p1.drugClass}) and ${p2.drugName} (${p2.drugClass}). High risk of respiratory depression.',
              timestamp: DateTime.now(),
              metadata: {
                'drug1': p1.drugName,
                'drug2': p2.drugName,
                'class1': p1.drugClass,
                'class2': p2.drugClass,
              },
            ));
          }
        }
      }
    }

    return alerts;
  }

  /// Rule 5: Check for high frequency of controlled substance prescriptions
  List<Alert> _checkHighFrequency(
      String patientId, List<Prescription> prescriptions) {
    List<Alert> alerts = [];
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Count controlled substances (Schedule II-IV) in last 30 days
    final recentControlled = prescriptions
        .where((p) =>
            p.prescribedDate.isAfter(thirtyDaysAgo) &&
            p.schedule >= 2 &&
            p.schedule <= 4)
        .toList();

    if (recentControlled.length > 5) {
      alerts.add(Alert(
        id: uuid.v4(),
        patientId: patientId,
        alertType: AlertType.highFrequency,
        severity: AlertSeverity.medium,
        message:
            'High frequency of controlled substance prescriptions: ${recentControlled.length} prescriptions in the last 30 days',
        timestamp: DateTime.now(),
        metadata: {
          'count': recentControlled.length,
          'period': '30 days',
        },
      ));
    }

    return alerts;
  }
}
