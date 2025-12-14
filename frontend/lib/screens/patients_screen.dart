import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../providers/alert_provider.dart';
import '../widgets/patient_card.dart';
import 'patient_detail_screen.dart';
import 'add_patient_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {

  String _filterLevel = 'All'; // All, Low, Medium, High

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patients',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search patients...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    Provider.of<PatientProvider>(context, listen: false).searchPatients(value);
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _filterLevel == 'All',
                        onTap: () => setState(() => _filterLevel = 'All'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Low Risk',
                        isSelected: _filterLevel == 'Low',
                        color: Colors.green,
                        onTap: () => setState(() => _filterLevel = 'Low'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Medium Risk',
                        isSelected: _filterLevel == 'Medium',
                        color: Colors.orange,
                        onTap: () => setState(() => _filterLevel = 'Medium'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'High Risk',
                        isSelected: _filterLevel == 'High',
                        color: Colors.red,
                        onTap: () => setState(() => _filterLevel = 'High'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Patient List
          Expanded(
            child: Consumer2<PatientProvider, AlertProvider>(
              builder: (context, patientProvider, alertProvider, child) {
                var patients = patientProvider.patients;



                // Apply risk level filter
                if (_filterLevel != 'All') {
                  patients = patients.where((p) => p.riskLevel == _filterLevel).toList();
                }

                // Sort by risk score (highest first)
                patients.sort((a, b) => b.riskScore.compareTo(a.riskScore));

                if (patients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No patients found',
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
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
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
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPatientScreen()),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Patient'),
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
