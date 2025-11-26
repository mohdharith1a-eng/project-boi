import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'firebase_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  double _safeDouble(Map data, String key) => (data[key] as num? ?? 0).toDouble();
  int _safeInt(Map data, String key) => (data[key] as num? ?? 0).toInt();
  String _safeString(Map data, String key) => (data[key] as String? ?? 'N/A');

  bool _safeBool(Map data, String key) {
    final value = data[key];
    if (value is bool) return value;
    if (value is num) return value == 1;
    return false;
  }

  Widget _sensorCard(
    IconData icon,
    Color color,
    String title,
    String value, {
    Color? bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor ?? color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _relayToggle(String title, String dbKey, bool value, FirebaseService firebase) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Switch(
          value: value,
          onChanged: (newValue) {
            firebase.controlManualRef().update({dbKey: newValue ? 1 : 0});
          },
          activeColor: Colors.teal,
          inactiveThumbColor: Colors.grey.shade300,
        ),
      ],
    );
  }

  Widget _modeToggle(String currentMode, FirebaseService firebase) {
    final bool isAuto = currentMode == 'Auto';
    return Column(
      children: [
        const Text(
          "System Mode Switch",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Manual", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Switch(
              value: isAuto,
              onChanged: (newValue) {
                final String newMode = newValue ? 'Auto' : 'Manual';
                firebase.controlModeRef().update({'mode': newMode});
              },
              activeColor: Colors.green,
              inactiveThumbColor: Colors.red,
            ),
            const Text("Auto", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        Text(
          "Current: ${isAuto ? 'AUTOMATIC' : 'MANUAL'}",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isAuto ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSensorSection(Map<dynamic, dynamic>? sensorData) {
    double temperature = 0;
    double humidity = 0;
    int distance = 0;
    int gas = 0;
    String systemMode = 'N/A';
    Color modeColor = Colors.grey;

    if (sensorData != null) {
      temperature = _safeDouble(sensorData, "temperature");
      humidity = _safeDouble(sensorData, "humidity");
      distance = _safeInt(sensorData, "distance");
      gas = _safeInt(sensorData, "gas");
      systemMode = _safeString(sensorData, "mode");
      modeColor = systemMode == 'Auto' ? Colors.green : Colors.red;
    }

    return Column(
      children: [
        _sensorCard(
          systemMode == 'Auto' ? Icons.settings_power : Icons.pan_tool_alt,
          modeColor,
          "System Mode",
          systemMode.toUpperCase(),
          bgColor: modeColor.withOpacity(0.2),
        ),
        _sensorCard(Icons.thermostat, Colors.red.shade600, "Temperature", "$temperature °C"),
        _sensorCard(Icons.opacity, Colors.blue.shade600, "Humidity", "$humidity %"),
        _sensorCard(Icons.square_foot, Colors.green.shade600, "Distance", "$distance cm"),
        _sensorCard(Icons.local_fire_department, Colors.orange.shade600, "Gas Level", gas.toString()),
      ],
    );
  }

  Widget _buildRelayStream(BuildContext context, FirebaseService firebase, String systemMode) {
    if (systemMode != 'Manual') {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "Manual Control is disabled. Switch to MANUAL mode to control relays.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: firebase.controlManualRef().onValue,
      builder: (context, snapshot) {
        bool ledOn = false;
        bool buzzerOn = false;

        final data = snapshot.data?.snapshot.value;
        Map<dynamic, dynamic>? relayData;
        if (data is Map) {
          relayData = data;
        }

        if (relayData != null) {
          ledOn = _safeBool(relayData, "led");
          buzzerOn = _safeBool(relayData, "buzzer");
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _relayToggle("LED", "led", ledOn, firebase),
            _relayToggle("Buzzer", "buzzer", buzzerOn, firebase),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebase = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Smart System Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => firebase.logout(),
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: firebase.sensorRef().onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: Colors.teal),
              ),
            );
          }

          Map<dynamic, dynamic>? sensorData;
          String currentMode = 'N/A';
          final data = snapshot.data?.snapshot.value;
          if (data is Map) {
            sensorData = data;
            currentMode = _safeString(sensorData, "mode");
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _modeToggle(currentMode, firebase),
                ),
                const SizedBox(height: 30),
                const Text(
                  "LIVE SENSOR DATA",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.teal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Divider(color: Colors.teal, thickness: 2, indent: 50, endIndent: 50),
                _buildSensorSection(sensorData),
                const SizedBox(height: 30),
                const Text(
                  "RELAY CONTROL (MANUAL MODE)",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Divider(color: Colors.deepPurple, thickness: 2, indent: 50, endIndent: 50),
                _buildRelayStream(context, firebase, currentMode),
              ],
            ),
          );
        },
      ),
    );
  }
}