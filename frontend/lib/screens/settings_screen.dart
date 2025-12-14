import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ml_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _mlService = MLService();
  bool _isLoading = false;
  String? _statusMessage;
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('ml_backend_url') ?? 'http://10.120.140.187:5000';
    setState(() {
      _urlController.text = url;
    });
  }

  Future<void> _saveUrl() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing connection...';
      _statusColor = Colors.blue;
    });

    final url = _urlController.text.trim();
    
    // Validate URL format
    if (!url.startsWith('http')) {
      setState(() {
        _statusMessage = 'URL must start with http:// or https://';
        _statusColor = Colors.red;
        _isLoading = false;
      });
      return;
    }

    // Test connection
    final isConnected = await _mlService.testConnection(url);

    if (isConnected) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ml_backend_url', url);
      
      if (mounted) {
        setState(() {
          _statusMessage = 'Connected & Saved!';
          _statusColor = Colors.green;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backend URL updated successfully')),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _statusMessage = 'Connection failed. Check IP and ensure server is running.';
          _statusColor = Colors.red;
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ML Backend Configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the IP address of your computer running the Python backend.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'http://192.168.1.x:5000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _statusColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusColor == Colors.green ? Icons.check_circle : Icons.error,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Test & Save Connection'),
              ),
            ),
            const Spacer(),
            const Center(
              child: Text(
                'How to find your IP:\nRun "ipconfig" in terminal on Windows',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
