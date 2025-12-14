import 'package:flutter/material.dart';

class RiskScoreIndicator extends StatelessWidget {
  final double riskScore;
  final double size;

  const RiskScoreIndicator({
    super.key,
    required this.riskScore,
    this.size = 100,
  });

  Color _getRiskColor() {
    if (riskScore < 30) return Colors.green;
    if (riskScore < 60) return Colors.orange;
    return Colors.red;
  }

  String _getRiskLevel() {
    if (riskScore < 30) return 'Low Risk';
    if (riskScore < 60) return 'Medium Risk';
    return 'High Risk';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: riskScore / 100,
                  strokeWidth: size * 0.1,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    riskScore.toInt().toString(),
                    style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'Risk',
                    style: TextStyle(
                      fontSize: size * 0.12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: size * 0.1),
        Text(
          _getRiskLevel(),
          style: TextStyle(
            fontSize: size * 0.14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
