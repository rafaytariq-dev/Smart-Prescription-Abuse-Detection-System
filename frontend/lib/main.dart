import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/patient_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/alert_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/alerts_screen.dart';
import 'utils/sample_data.dart';
import 'services/rule_based_engine.dart';
import 'services/inductive_reasoning_engine.dart';
import 'models/alert.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
      ],
      child: MaterialApp(
        title: 'Prescription Abuse Detector',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PatientsScreen(),
    const AlertsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final patientProvider = context.read<PatientProvider>();
    final prescriptionProvider = context.read<PrescriptionProvider>();
    final alertProvider = context.read<AlertProvider>();

    // Load data from storage
    await patientProvider.loadFromStorage();
    await prescriptionProvider.loadFromStorage();
    await alertProvider.loadFromStorage();

    // If no data exists, load sample data
    if (patientProvider.patients.isEmpty) {
      final samplePatients = SampleData.generateSamplePatients();
      final samplePrescriptions = SampleData.generateSamplePrescriptions();

      patientProvider.setPatients(samplePatients);
      prescriptionProvider.setPrescriptions(samplePrescriptions);

      // Run analysis on sample data
      await _analyzeAllPatients();
    }

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _analyzeAllPatients() async {
    final patientProvider = context.read<PatientProvider>();
    final prescriptionProvider = context.read<PrescriptionProvider>();
    final alertProvider = context.read<AlertProvider>();

    final ruleEngine = RuleBasedEngine();
    final inductiveEngine = InductiveReasoningEngine();

    for (var patient in patientProvider.patients) {
      final prescriptions = prescriptionProvider.getPrescriptionsByPatient(patient.id);
      
      // Run rule-based analysis
      final ruleAlerts = ruleEngine.analyzePatient(patient.id, prescriptions);
      
      // Run inductive reasoning analysis
      final analysisResult = await inductiveEngine.analyzePatterns(patient.id, prescriptions);
      final patternAlerts = analysisResult.alerts;
      
      // Add all alerts
      await alertProvider.addAlerts([...ruleAlerts, ...patternAlerts]);
      
      // Calculate risk score based on alerts
      final patientAlerts = alertProvider.getAlertsByPatient(patient.id);
      double riskScore = 0;
      
      for (var alert in patientAlerts) {
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
      
      // Cap at 100
      riskScore = riskScore > 100 ? 100 : riskScore;
      await patientProvider.updateRiskScore(patient.id, riskScore);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
