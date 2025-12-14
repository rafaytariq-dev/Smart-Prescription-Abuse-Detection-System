import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prescription.dart';

class PrescriptionProvider with ChangeNotifier {
  List<Prescription> _prescriptions = [];

  List<Prescription> get prescriptions => _prescriptions;

  List<Prescription> getPrescriptionsByPatient(String patientId) {
    return _prescriptions
        .where((p) => p.patientId == patientId)
        .toList()
      ..sort((a, b) => b.prescribedDate.compareTo(a.prescribedDate));
  }

  Future<void> addPrescription(Prescription prescription) async {
    _prescriptions.add(prescription);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prescriptionsJson = prefs.getString('prescriptions');
      
      if (prescriptionsJson != null) {
        final List<dynamic> decoded = json.decode(prescriptionsJson);
        _prescriptions = decoded.map((json) => Prescription.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading prescriptions: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prescriptionsJson = json.encode(_prescriptions.map((p) => p.toJson()).toList());
      await prefs.setString('prescriptions', prescriptionsJson);
    } catch (e) {
      debugPrint('Error saving prescriptions: $e');
    }
  }

  void setPrescriptions(List<Prescription> prescriptions) {
    _prescriptions = prescriptions;
    notifyListeners();
    _saveToStorage();
  }

  // Get recent prescription activity (last 30 days)
  List<Prescription> getRecentActivity() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _prescriptions
        .where((p) => p.prescribedDate.isAfter(thirtyDaysAgo))
        .toList()
      ..sort((a, b) => b.prescribedDate.compareTo(a.prescribedDate));
  }
}
