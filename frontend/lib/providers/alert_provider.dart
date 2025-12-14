import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert.dart';

class AlertProvider with ChangeNotifier {
  List<Alert> _alerts = [];

  List<Alert> get alerts => _alerts;

  List<Alert> getAlertsByPatient(String patientId) {
    return _alerts
        .where((a) => a.patientId == patientId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<Alert> getUnresolvedAlerts() {
    return _alerts
        .where((a) => !a.isResolved)
        .toList()
      ..sort((a, b) {
        // Sort by severity first, then by timestamp
        final severityCompare = b.severity.index.compareTo(a.severity.index);
        if (severityCompare != 0) return severityCompare;
        return b.timestamp.compareTo(a.timestamp);
      });
  }

  List<Alert> getAlertsBySeverity(AlertSeverity severity) {
    return _alerts
        .where((a) => a.severity == severity && !a.isResolved)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<Alert> getAlertsByType(AlertType type) {
    return _alerts
        .where((a) => a.alertType == type && !a.isResolved)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int getUnresolvedCountForPatient(String patientId) {
    return _alerts.where((a) => a.patientId == patientId && !a.isResolved).length;
  }

  Future<void> addAlert(Alert alert) async {
    _alerts.add(alert);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> addAlerts(List<Alert> alerts) async {
    _alerts.addAll(alerts);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> resolveAlert(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isResolved: true);
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString('alerts');
      
      if (alertsJson != null) {
        final List<dynamic> decoded = json.decode(alertsJson);
        _alerts = decoded.map((json) => Alert.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading alerts: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = json.encode(_alerts.map((a) => a.toJson()).toList());
      await prefs.setString('alerts', alertsJson);
    } catch (e) {
      debugPrint('Error saving alerts: $e');
    }
  }

  void setAlerts(List<Alert> alerts) {
    _alerts = alerts;
    notifyListeners();
    _saveToStorage();
  }

  // Clear all alerts (useful for testing)
  Future<void> clearAlerts() async {
    _alerts.clear();
    notifyListeners();
    await _saveToStorage();
  }
}
