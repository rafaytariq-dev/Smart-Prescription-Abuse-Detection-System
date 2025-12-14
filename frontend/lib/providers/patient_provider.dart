import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';

class PatientProvider with ChangeNotifier {
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  String _searchQuery = '';
  
  // Backend URL (Use 10.0.2.2 for Android Emulator, localhost for Windows)
  // Assuming user is on Windows mostly based on OS info, but keeping standard local dev URL
  static const String _baseUrl = 'http://127.0.0.1:5000'; 
  
  List<Patient> get patients => _searchQuery.isEmpty ? _patients : _filteredPatients;

  Patient? getPatient(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Patient> getHighRiskPatients() {
    return _patients.where((p) => p.riskScore >= 60).toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
  }

  Future<void> searchPatients(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredPatients = _patients;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search_patients?query=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _filteredPatients = data.map((json) => Patient.fromJson(json)).toList();
      } else {
        debugPrint('Search failed: ${response.statusCode}');
        _filteredPatients = []; // Fallback or empty
      }
    } catch (e) {
      debugPrint('Error searching patients: $e');
      _filteredPatients = [];
    }
    notifyListeners();
  }

  Future<void> syncPatientsToBackend() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sync_patients'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patients': _patients.map((p) => p.toJson()).toList(),
        }),
      );
      
      if (response.statusCode != 200) {
        debugPrint('Sync failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error syncing to backend: $e');
    }
  }

  Future<void> addPatient(Patient patient) async {
    _patients.add(patient);
    await _saveToStorage();
    await syncPatientsToBackend(); // Keep backend updated
    if (_searchQuery.isNotEmpty) searchPatients(_searchQuery);
  }

  Future<void> updatePatient(Patient patient) async {
    final index = _patients.indexWhere((p) => p.id == patient.id);
    if (index != -1) {
      _patients[index] = patient;
      await _saveToStorage();
      await syncPatientsToBackend(); // Keep backend updated
      if (_searchQuery.isNotEmpty) searchPatients(_searchQuery);
    }
  }

  Future<void> updateRiskScore(String patientId, double newScore) async {
    final patient = getPatient(patientId);
    if (patient != null) {
      final updatedPatient = patient.copyWith(riskScore: newScore);
      await updatePatient(updatedPatient);
    }
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientsJson = prefs.getString('patients');
      
      if (patientsJson != null) {
        final List<dynamic> decoded = json.decode(patientsJson);
        _patients = decoded.map((json) => Patient.fromJson(json)).toList();
        notifyListeners();
        // Sync with backend on load
        syncPatientsToBackend();
      }
    } catch (e) {
      debugPrint('Error loading patients: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientsJson = json.encode(_patients.map((p) => p.toJson()).toList());
      await prefs.setString('patients', patientsJson);
    } catch (e) {
      debugPrint('Error saving patients: $e');
    }
  }

  void setPatients(List<Patient> patients) {
    _patients = patients;
    _saveToStorage();
    syncPatientsToBackend();
  }
}
