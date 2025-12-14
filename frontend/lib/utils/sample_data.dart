import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../models/prescription.dart';

class SampleData {
  static const uuid = Uuid();

  static List<Patient> generateSamplePatients() {
    return [
      Patient(
        id: 'patient-1',
        name: 'John Doe',
        dateOfBirth: DateTime(1975, 5, 15),
        address: '123 Main St, Springfield',
        phone: '555-0101',
        riskScore: 0,
      ),
      Patient(
        id: 'patient-2',
        name: 'Sarah Johnson',
        dateOfBirth: DateTime(1982, 8, 22),
        address: '456 Oak Ave, Riverside',
        phone: '555-0102',
        riskScore: 0,
      ),
      Patient(
        id: 'patient-3',
        name: 'Michael Chen',
        dateOfBirth: DateTime(1990, 3, 10),
        address: '789 Pine Rd, Lakeside',
        phone: '555-0103',
        riskScore: 0,
      ),
      Patient(
        id: 'patient-4',
        name: 'Emily Rodriguez',
        dateOfBirth: DateTime(1968, 11, 30),
        address: '321 Elm St, Hilltown',
        phone: '555-0104',
        riskScore: 0,
      ),
      Patient(
        id: 'patient-5',
        name: 'David Williams',
        dateOfBirth: DateTime(1985, 7, 18),
        address: '654 Maple Dr, Greenville',
        phone: '555-0105',
        riskScore: 0,
      ),
    ];
  }

  static List<Prescription> generateSamplePrescriptions() {
    final now = DateTime.now();
    List<Prescription> prescriptions = [];

    // Patient 1 (John Doe) - Doctor Shopping Pattern
    prescriptions.addAll([
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-1',
        drugName: 'Oxycodone',
        drugClass: 'Opioid',
        schedule: 2,
        dosage: 30,
        quantity: 30,
        prescribedDate: now.subtract(const Duration(days: 25)),
        doctorId: 'doc-1',
        doctorName: 'Dr. Smith',
        pharmacy: 'Main Street Pharmacy',
      ),
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-1',
        drugName: 'Oxycodone',
        drugClass: 'Opioid',
        schedule: 2,
        dosage: 30,
        quantity: 30,
        prescribedDate: now.subtract(const Duration(days: 20)),
        doctorId: 'doc-2',
        doctorName: 'Dr. Johnson',
        pharmacy: 'Downtown Pharmacy',
      ),
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-1',
        drugName: 'Oxycodone',
        drugClass: 'Opioid',
        schedule: 2,
        dosage: 30,
        quantity: 30,
        prescribedDate: now.subtract(const Duration(days: 15)),
        doctorId: 'doc-3',
        doctorName: 'Dr. Williams',
        pharmacy: 'Riverside Pharmacy',
      ),
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-1',
        drugName: 'Oxycodone',
        drugClass: 'Opioid',
        schedule: 2,
        dosage: 30,
        quantity: 30,
        prescribedDate: now.subtract(const Duration(days: 10)),
        doctorId: 'doc-4',
        doctorName: 'Dr. Brown',
        pharmacy: 'Lakeside Pharmacy',
      ),
    ]);

    // Patient 2 (Sarah Johnson) - Early Refill Pattern
    prescriptions.addAll([
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-2',
        drugName: 'Hydrocodone',
        drugClass: 'Opioid',
        schedule: 2,
        dosage: 20,
        quantity: 30,
        prescribedDate: now.subtract(const Duration(days: 60)),
        doctorId: 'doc-5',
        doctorName: 'Dr. Davis',
        pharmacy: 'Main Street Pharmacy',
      ),
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-2',
        drugName: 'Hydrocodone',
        drugClass: 'Opioid',
        schedule: 2,
        dosage: 20,
        quantity: 30,
        prescribedDate: now.subtract(const Duration(days: 40)), // 20 days early
        doctorId: 'doc-5',
        doctorName: 'Dr. Davis',
        pharmacy: 'Main Street Pharmacy',
      ),
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-2',
        drugName: 'Hydrocodone',
        drugClass: 'Opioid',
        schedule: 2,
        dosage: 20,
        quantity: 30,
        prescribedDate: now.subtract(const Duration(days: 22)), // 18 days early
        doctorId: 'doc-5',
        doctorName: 'Dr. Davis',
        pharmacy: 'Main Street Pharmacy',
      ),
    ]);

    // Patient 3 (Michael Chen) - Excessive Dosage Pattern
    prescriptions.addAll([
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-3',
        drugName: 'Oxycodone',
        drugClass: 'Opioid',
        schedule: 2,
        dosage: 120, // Exceeds max of 80mg
        quantity: 60,
        prescribedDate: now.subtract(const Duration(days: 15)),
        doctorId: 'doc-6',
        doctorName: 'Dr. Martinez',
        pharmacy: 'Downtown Pharmacy',
      ),
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-3',
        drugName: 'Alprazolam',
        drugClass: 'Benzodiazepine',
        schedule: 4,
        dosage: 2,
        quantity: 60,
        prescribedDate: now.subtract(const Duration(days: 10)),
        doctorId: 'doc-6',
        doctorName: 'Dr. Martinez',
        pharmacy: 'Downtown Pharmacy',
      ),
    ]);

    // Patient 4 (Emily Rodriguez) - Dangerous Combination
    prescriptions.addAll([
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-4',
        drugName: 'Morphine',
        drugClass: 'Opioid',
        schedule: 2,
        dosage: 60,
        quantity: 30,
        prescribedDate: now.subtract(const Duration(days: 20)),
        doctorId: 'doc-7',
        doctorName: 'Dr. Anderson',
        pharmacy: 'Riverside Pharmacy',
      ),
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-4',
        drugName: 'Diazepam',
        drugClass: 'Benzodiazepine',
        schedule: 4,
        dosage: 10,
        quantity: 30,
        prescribedDate: now.subtract(const Duration(days: 18)), // Within 30 days
        doctorId: 'doc-8',
        doctorName: 'Dr. Taylor',
        pharmacy: 'Riverside Pharmacy',
      ),
    ]);

    // Patient 5 (David Williams) - Temporal Pattern (always on Fridays) + Escalation
    final baseFriday = now.subtract(Duration(days: now.weekday - DateTime.friday));
    prescriptions.addAll([
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-5',
        drugName: 'Adderall',
        drugClass: 'Stimulant',
        schedule: 2,
        dosage: 10,
        quantity: 30,
        prescribedDate: baseFriday.subtract(const Duration(days: 84)), // 12 weeks ago
        doctorId: 'doc-9',
        doctorName: 'Dr. Wilson',
        pharmacy: 'Main Street Pharmacy',
      ),
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-5',
        drugName: 'Adderall',
        drugClass: 'Stimulant',
        schedule: 2,
        dosage: 15,
        quantity: 30,
        prescribedDate: baseFriday.subtract(const Duration(days: 56)), // 8 weeks ago
        doctorId: 'doc-9',
        doctorName: 'Dr. Wilson',
        pharmacy: 'Downtown Pharmacy',
      ),
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-5',
        drugName: 'Adderall',
        drugClass: 'Stimulant',
        schedule: 2,
        dosage: 20,
        quantity: 30,
        prescribedDate: baseFriday.subtract(const Duration(days: 28)), // 4 weeks ago
        doctorId: 'doc-9',
        doctorName: 'Dr. Wilson',
        pharmacy: 'Lakeside Pharmacy',
      ),
      Prescription(
        id: uuid.v4(),
        patientId: 'patient-5',
        drugName: 'Adderall',
        drugClass: 'Stimulant',
        schedule: 2,
        dosage: 30,
        quantity: 30,
        prescribedDate: baseFriday, // This Friday
        doctorId: 'doc-9',
        doctorName: 'Dr. Wilson',
        pharmacy: 'Greenville Pharmacy',
      ),
    ]);

    return prescriptions;
  }
}
