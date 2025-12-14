import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prescription.dart';

class RiskPrediction {
  final String riskLevel;
  final double riskScore;
  final double confidence;
  final Map<String, double> probabilities;
  final String? message;

  RiskPrediction({
    required this.riskLevel,
    required this.riskScore,
    required this.confidence,
    required this.probabilities,
    this.message,
  });

  factory RiskPrediction.fromJson(Map<String, dynamic> json) {
    return RiskPrediction(
      riskLevel: json['risk_level'] ?? 'Unknown',
      riskScore: (json['risk_score'] ?? 0.0).toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      probabilities: Map<String, double>.from(
        (json['probabilities'] ?? {}).map(
          (key, value) => MapEntry(key, (value ?? 0.0).toDouble()),
        ),
      ),
      message: json['message'],
    );
  }
}

class MLService {
  // Default fallback URL
  static const String _defaultUrl = 'http://192.168.18.48:5000';

  Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ml_backend_url') ?? _defaultUrl;
  }

  Future<bool> testConnection(String url) async {
    try {
      final response = await http.get(Uri.parse('$url/health')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'active';
      }
      return false;
    } catch (e) {
      print('Connection Test Failed: $e');
      return false;
    }
  }

  Future<bool> checkHealth() async {
    try {
      final baseUrl = await _getBaseUrl();
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'active';
      }
      return false;
    } catch (e) {
      print('ML Service Health Check Failed: $e');
      return false;
    }
  }

  Future<RiskPrediction?> predictRiskScore(List<Prescription> prescriptions) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/predict');
      final headers = {'Content-Type': 'application/json'};
      
      final body = json.encode({
        'prescriptions': prescriptions.map((p) => {
          'drugName': p.drugName,
          'dosage': p.dosage,
          'quantity': p.quantity,
          'date': p.prescribedDate.toIso8601String(),
        }).toList(),
      });

      final response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return RiskPrediction.fromJson(json.decode(response.body));
      } else {
        print('ML Prediction Failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling ML Service: $e');
      return null;
    }
  }
}
