import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/alert_provider.dart';
import '../models/alert.dart';
import '../widgets/alert_card.dart';
import '../widgets/patient_card.dart';
import 'patient_detail_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Prescription Abuse Detection',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer3<PatientProvider, PrescriptionProvider, AlertProvider>(
        builder: (context, patientProvider, prescriptionProvider, alertProvider, child) {
          final totalPatients = patientProvider.patients.length;
          final unresolvedAlerts = alertProvider.getUnresolvedAlerts();
          final highRiskPatients = patientProvider.getHighRiskPatients();
          final recentActivity = prescriptionProvider.getRecentActivity();
          
          final criticalAlerts = unresolvedAlerts.where((a) => a.severity == AlertSeverity.critical).length;
          final highAlerts = unresolvedAlerts.where((a) => a.severity == AlertSeverity.high).length;
          final mediumAlerts = unresolvedAlerts.where((a) => a.severity == AlertSeverity.medium).length;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Patients',
                              value: totalPatients.toString(),
                              icon: Icons.people,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Active Alerts',
                              value: unresolvedAlerts.length.toString(),
                              icon: Icons.warning,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'High Risk',
                              value: highRiskPatients.length.toString(),
                              icon: Icons.dangerous,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Recent (30d)',
                              value: recentActivity.length.toString(),
                              icon: Icons.medication,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Alert Severity Breakdown
                if (unresolvedAlerts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Alert Severity Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SeverityChip(
                            label: 'Critical',
                            count: criticalAlerts,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SeverityChip(
                            label: 'High',
                            count: highAlerts,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SeverityChip(
                            label: 'Medium',
                            count: mediumAlerts,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // High Risk Patients
                if (highRiskPatients.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'High Risk Patients',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...highRiskPatients.take(3).map((patient) {
                    final alertCount = alertProvider.getUnresolvedCountForPatient(patient.id);
                    return PatientCard(
                      patient: patient,
                      alertCount: alertCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientDetailScreen(patientId: patient.id),
                          ),
                        );
                      },
                    );
                  }),
                ],

                // Critical Alerts
                if (unresolvedAlerts.where((a) => a.severity == AlertSeverity.critical).isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Critical Alerts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...unresolvedAlerts
                      .where((a) => a.severity == AlertSeverity.critical)
                      .take(3)
                      .map((alert) {
                    return AlertCard(
                      alert: alert,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientDetailScreen(patientId: alert.patientId),
                          ),
                        );
                      },
                      onResolve: () async {
                        await alertProvider.resolveAlert(alert.id);
                      },
                    );
                  }),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SeverityChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
