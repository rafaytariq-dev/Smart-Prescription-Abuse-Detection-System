import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/patient_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/alert_provider.dart';
import '../widgets/risk_score_indicator.dart';
import '../widgets/alert_card.dart';
import 'add_prescription_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        elevation: 0,
      ),
      body: Consumer3<PatientProvider, PrescriptionProvider, AlertProvider>(
        builder: (context, patientProvider, prescriptionProvider, alertProvider, child) {
          final patient = patientProvider.getPatient(patientId);
          
          if (patient == null) {
            return const Center(child: Text('Patient not found'));
          }

          final prescriptions = prescriptionProvider.getPrescriptionsByPatient(patientId);
          final alerts = alertProvider.getAlertsByPatient(patientId);
          final unresolvedAlerts = alerts.where((a) => !a.isResolved).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Info Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          patient.name.split(' ').map((n) => n[0]).take(2).join(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Age: ${patient.age} • ${patient.phone}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        patient.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Risk Score
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: RiskScoreIndicator(riskScore: patient.riskScore),
                  ),
                ),

                // Statistics
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: 'Prescriptions',
                          value: prescriptions.length.toString(),
                          icon: Icons.medication,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          title: 'Active Alerts',
                          value: unresolvedAlerts.length.toString(),
                          icon: Icons.warning,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                // Alerts Section
                if (unresolvedAlerts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Active Alerts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...unresolvedAlerts.map((alert) {
                    return AlertCard(
                      alert: alert,
                      onResolve: () async {
                        await alertProvider.resolveAlert(alert.id);
                      },
                    );
                  }),
                ],

                // Prescription History
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Prescription History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddPrescriptionScreen(patientId: patientId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (prescriptions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No prescriptions recorded',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                else
                  ...prescriptions.map((prescription) {
                    return _PrescriptionTile(prescription: prescription);
                  }),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionTile extends StatelessWidget {
  final prescription;

  const _PrescriptionTile({required this.prescription});

  Color _getScheduleColor(int schedule) {
    switch (schedule) {
      case 1:
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getScheduleColor(prescription.schedule).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.medication,
            color: _getScheduleColor(prescription.schedule),
          ),
        ),
        title: Text(
          prescription.drugName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${prescription.dosage}mg • Qty: ${prescription.quantity}'),
            Text('Dr. ${prescription.doctorName}'),
            Text(
              dateFormat.format(prescription.prescribedDate),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getScheduleColor(prescription.schedule),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Sch ${prescription.schedule}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}
