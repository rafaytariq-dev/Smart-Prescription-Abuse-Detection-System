import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';
import '../models/alert.dart';
import '../widgets/alert_card.dart';
import 'patient_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _filterType = 'All';
  String _filterSeverity = 'All';
  bool _showResolved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Severity',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _filterSeverity == 'All',
                        onTap: () => setState(() => _filterSeverity = 'All'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Critical',
                        isSelected: _filterSeverity == 'Critical',
                        color: Colors.red,
                        onTap: () => setState(() => _filterSeverity = 'Critical'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'High',
                        isSelected: _filterSeverity == 'High',
                        color: Colors.deepOrange,
                        onTap: () => setState(() => _filterSeverity = 'High'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Medium',
                        isSelected: _filterSeverity == 'Medium',
                        color: Colors.orange,
                        onTap: () => setState(() => _filterSeverity = 'Medium'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Low',
                        isSelected: _filterSeverity == 'Low',
                        color: Colors.blue,
                        onTap: () => setState(() => _filterSeverity = 'Low'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Show Resolved',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Switch(
                      value: _showResolved,
                      onChanged: (value) {
                        setState(() => _showResolved = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Alert List
          Expanded(
            child: Consumer<AlertProvider>(
              builder: (context, alertProvider, child) {
                var alerts = _showResolved 
                    ? alertProvider.alerts 
                    : alertProvider.getUnresolvedAlerts();

                // Apply severity filter
                if (_filterSeverity != 'All') {
                  final severity = AlertSeverity.values.firstWhere(
                    (s) => s.toString().split('.').last.toLowerCase() == 
                           _filterSeverity.toLowerCase(),
                  );
                  alerts = alerts.where((a) => a.severity == severity).toList();
                }

                // Sort by severity and timestamp
                alerts.sort((a, b) {
                  final severityCompare = b.severity.index.compareTo(a.severity.index);
                  if (severityCompare != 0) return severityCompare;
                  return b.timestamp.compareTo(a.timestamp);
                });

                if (alerts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No alerts found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
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
                      onResolve: alert.isResolved ? null : () async {
                        await alertProvider.resolveAlert(alert.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
