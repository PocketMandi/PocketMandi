import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';

class DebugDataScreen extends StatefulWidget {
  const DebugDataScreen({Key? key}) : super(key: key);

  @override
  State<DebugDataScreen> createState() => _DebugDataScreenState();
}

class _DebugDataScreenState extends State<DebugDataScreen> {
  @override
  void initState() {
    super.initState();
    _printAllData();
  }

  Future<void> _printAllData() async {
    print('========================================');
    print('STARTING FIREBASE DATA DEBUG');
    print('========================================');

    await _printData('users');
    await _printData('allcrops');
    await _printData('addedcropsbyvyapari');
    await _printData('addedcropsbykissan');
    await _printData('saplingorders');
    await _printData('testrequests');
    await _printData('requestednewcropbyvyapari');

    print('========================================');
    print('FINISHED FIREBASE DATA DEBUG');
    print('========================================');
  }

  Future<void> _printData(String path) async {
    print('\n========================================');
    print('PATH: $path');
    print('========================================');

    try {
      final snapshot = await FirebaseDatabase.instance.ref(path).once();

      if (snapshot.snapshot.value == null) {
        print('❌ NO DATA FOUND');
        return;
      }

      var data = snapshot.snapshot.value;
      print('✅ DATA TYPE: ${data.runtimeType}');

      if (data is Map) {
        print('📊 COUNT: ${data.length} items');
        print('🔑 KEYS: ${data.keys.toList()}');
        print('\n--- FULL DATA ---');
        print(const JsonEncoder.withIndent('  ').convert(data));
      } else if (data is List) {
        print('📊 COUNT: ${data.where((e) => e != null).length} items');
        print('\n--- FULL DATA ---');
        print(const JsonEncoder.withIndent('  ').convert(data));
      } else {
        print('--- RAW DATA ---');
        print(data.toString());
      }
    } catch (e) {
      print('❌ ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Firebase Data'),
        backgroundColor: const Color(0xFF104f22),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bug_report,
              size: 80,
              color: Color(0xFF104f22),
            ),
            const SizedBox(height: 20),
            const Text(
              'Check Console/Logcat',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'All Firebase data has been printed to console',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _printAllData();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Print Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF104f22),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
