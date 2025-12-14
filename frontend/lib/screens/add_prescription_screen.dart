import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/prescription_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/patient_provider.dart';
import '../models/prescription.dart';
import '../models/alert.dart';
import '../services/rule_based_engine.dart';
import '../services/inductive_reasoning_engine.dart';

class AddPrescriptionScreen extends StatefulWidget {
  final String patientId;

  const AddPrescriptionScreen({super.key, required this.patientId});

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _drugNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _pharmacyController = TextEditingController();
  
  String _selectedDrugClass = 'Opioid';
  int _selectedSchedule = 2;
  DateTime _selectedDate = DateTime.now();

  final List<String> _drugClasses = [
    'Opioid',
    'Benzodiazepine',
    'Stimulant',
    'Barbiturate',
    'Other',
  ];

  final List<Map<String, String>> _commonDrugs = [
    {'name': 'Oxycodone', 'class': 'Opioid', 'schedule': '2'},
    {'name': 'Hydrocodone', 'class': 'Opioid', 'schedule': '2'},
    {'name': 'Morphine', 'class': 'Opioid', 'schedule': '2'},
    {'name': 'Fentanyl', 'class': 'Opioid', 'schedule': '2'},
    {'name': 'Alprazolam', 'class': 'Benzodiazepine', 'schedule': '4'},
    {'name': 'Diazepam', 'class': 'Benzodiazepine', 'schedule': '4'},
    {'name': 'Adderall', 'class': 'Stimulant', 'schedule': '2'},
    {'name': 'Ritalin', 'class': 'Stimulant', 'schedule': '2'},
  ];

  @override
  void dispose() {
    _drugNameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    _doctorNameController.dispose();
    _pharmacyController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _savePrescription() async {
    if (_formKey.currentState!.validate()) {
      const uuid = Uuid();
      
      final prescription = Prescription(
        id: uuid.v4(),
        patientId: widget.patientId,
        drugName: _drugNameController.text.trim(),
        drugClass: _selectedDrugClass,
        schedule: _selectedSchedule,
        dosage: double.parse(_dosageController.text),
        quantity: int.parse(_quantityController.text),
        prescribedDate: _selectedDate,
        doctorId: uuid.v4(),
        doctorName: _doctorNameController.text.trim(),
        pharmacy: _pharmacyController.text.trim(),
      );

      // Add prescription
      await context.read<PrescriptionProvider>().addPrescription(prescription);

      // Run analysis
      await _analyzePatient();

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _analyzePatient() async {
    final prescriptionProvider = context.read<PrescriptionProvider>();
    final alertProvider = context.read<AlertProvider>();
    final patientProvider = context.read<PatientProvider>();

    final prescriptions = prescriptionProvider.getPrescriptionsByPatient(widget.patientId);
    
    final ruleEngine = RuleBasedEngine();
    final inductiveEngine = InductiveReasoningEngine();

    // Run both engines
    final ruleAlerts = ruleEngine.analyzePatient(widget.patientId, prescriptions);
    final analysisResult = await inductiveEngine.analyzePatterns(widget.patientId, prescriptions);
    final patternAlerts = analysisResult.alerts;

    // Add new alerts
    await alertProvider.addAlerts([...ruleAlerts, ...patternAlerts]);

    // Recalculate risk score
    final allAlerts = alertProvider.getAlertsByPatient(widget.patientId);
    double riskScore = 0;
    
    for (var alert in allAlerts) {
      if (!alert.isResolved) {
        switch (alert.severity) {
          case AlertSeverity.low:
            riskScore += 5;
            break;
          case AlertSeverity.medium:
            riskScore += 15;
            break;
          case AlertSeverity.high:
            riskScore += 25;
            break;
          case AlertSeverity.critical:
            riskScore += 40;
            break;
        }
      }
    }
    
    riskScore = riskScore > 100 ? 100 : riskScore;
    await patientProvider.updateRiskScore(widget.patientId, riskScore);

    // Show status message
    if (mounted) {
      String message = 'Prescription added. ';
      if (analysisResult.mlRan) {
        message += 'AI Analysis complete.';
      } else {
        message += 'AI Analysis skipped: ${analysisResult.mlError ?? "Server offline"}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: analysisResult.mlRan ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Prescription'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Quick Select',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _commonDrugs.map((drug) {
                  return ActionChip(
                    label: Text(drug['name']!),
                    onPressed: () {
                      setState(() {
                        _drugNameController.text = drug['name']!;
                        _selectedDrugClass = drug['class']!;
                        _selectedSchedule = int.parse(drug['schedule']!);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _drugNameController,
                decoration: const InputDecoration(
                  labelText: 'Drug Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter drug name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDrugClass,
                decoration: const InputDecoration(
                  labelText: 'Drug Class',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _drugClasses.map((drugClass) {
                  return DropdownMenuItem(
                    value: drugClass,
                    child: Text(drugClass),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDrugClass = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedSchedule,
                decoration: const InputDecoration(
                  labelText: 'DEA Schedule',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shield),
                ),
                items: [1, 2, 3, 4, 5].map((schedule) {
                  return DropdownMenuItem(
                    value: schedule,
                    child: Text('Schedule $schedule'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSchedule = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage (mg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Prescribed Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doctorNameController,
                decoration: const InputDecoration(
                  labelText: 'Doctor Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter doctor name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pharmacyController,
                decoration: const InputDecoration(
                  labelText: 'Pharmacy',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_pharmacy),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter pharmacy';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _savePrescription,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Add Prescription & Analyze',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
