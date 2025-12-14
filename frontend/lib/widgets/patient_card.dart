import 'package:flutter/material.dart';
import '../models/patient.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;
  final int alertCount;
  final VoidCallback onTap;

  const PatientCard({
    super.key,
    required this.patient,
    required this.alertCount,
    required this.onTap,
  });

  Color _getRiskColor() {
    if (patient.riskScore < 30) return Colors.green;
    if (patient.riskScore < 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: riskColor.withOpacity(0.2),
                child: Text(
                  patient.name.split(' ').map((n) => n[0]).take(2).join(),
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age: ${patient.age} • ${patient.phone}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (alertCount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.warning, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            '$alertCount active alert${alertCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: riskColor, width: 4),
                    ),
                    child: Center(
                      child: Text(
                        patient.riskScore.toInt().toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patient.riskLevel,
                    style: TextStyle(
                      fontSize: 12,
                      color: riskColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
