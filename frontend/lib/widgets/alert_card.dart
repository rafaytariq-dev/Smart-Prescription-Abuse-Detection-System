import 'package:flutter/material.dart';
import '../models/alert.dart';
import 'package:intl/intl.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;
  final VoidCallback? onResolve;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onResolve,
  });

  Color _getSeverityColor() {
    switch (alert.severity) {
      case AlertSeverity.low:
        return Colors.blue;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.high:
        return Colors.deepOrange;
      case AlertSeverity.critical:
        return Colors.red;
    }
  }

  IconData _getAlertIcon() {
    switch (alert.alertType) {
      case AlertType.doctorShopping:
        return Icons.local_hospital;
      case AlertType.earlyRefill:
        return Icons.schedule;
      case AlertType.excessiveDosage:
        return Icons.warning;
      case AlertType.dangerousCombination:
        return Icons.dangerous;
      case AlertType.patternDetected:
        return Icons.analytics;
      case AlertType.highFrequency:
        return Icons.trending_up;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor();
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getAlertIcon(), color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              alert.alertTypeString,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                alert.severityString.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(alert.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!alert.isResolved && onResolve != null)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      color: Colors.green,
                      onPressed: onResolve,
                      tooltip: 'Mark as Resolved',
                    ),
                  if (alert.isResolved)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: const TextStyle(fontSize: 14),
              ),
              if (alert.confidenceScore != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.psychology, size: 16, color: Colors.purple),
                    const SizedBox(width: 4),
                    Text(
                      'Confidence: ${alert.confidenceScore!.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
              if (alert.metadata?['source'] == 'ML_Model' || alert.metadata?['source'] == 'Inductive_AI') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                      const SizedBox(width: 6),
                      Text(
                        'AI Powered Analysis',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
