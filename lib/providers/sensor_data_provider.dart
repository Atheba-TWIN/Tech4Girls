import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tech4girls/models/sensor_data.dart';
import 'package:tech4girls/models/alert_settings.dart';
import 'package:tech4girls/services/bluetooth_service.dart';
import 'package:tech4girls/services/notification_service.dart';
import 'package:tech4girls/services/database_service.dart';

class SensorDataProvider extends ChangeNotifier {
  final BleService _bluetoothService = BleService();
  final NotificationService _notificationService = NotificationService();
  final DatabaseService _databaseService = DatabaseService();

  SensorData? _currentData;
  List<SensorData> _sensorHistory = [];
  AlertSettings _alertSettings = AlertSettings();
  bool _isConnected = false;
  String? _connectedDeviceName;

  late StreamSubscription<List<int>> _dataSubscription;
  late StreamSubscription<dynamic> _connectionSubscription;

  SensorData? get currentData => _currentData;
  List<SensorData> get sensorHistory => _sensorHistory;
  AlertSettings get alertSettings => _alertSettings;
  bool get isConnected => _isConnected;
  String? get connectedDeviceName => _connectedDeviceName;

  Future<void> initialize() async {
    // Load alert settings from database
    _alertSettings = _databaseService.getAlertSettings();

    // Load historical data
    _sensorHistory = _databaseService.getAllSensorData();

    // Subscribe to Bluetooth data
    _dataSubscription = _bluetoothService.dataStream.listen((data) async {
      final parsedData = _bluetoothService.parseSensorData(data);
      final temperature = parsedData['temperature'] as double;
      final emergencySignal = parsedData['emergencySignal'] as bool;
      final motionDetected = parsedData['motionDetected'] as bool? ?? false;

      // Create sensor data with current timestamp
      _currentData = SensorData(
        temperature: temperature,
        emergencySignal: emergencySignal,
        motionDetected: motionDetected,
        timestamp: DateTime.now(),
      );

      // Save to database
      await _databaseService.saveSensorData(_currentData!);
      _sensorHistory.add(_currentData!);

      // Check for alerts
      _checkAlerts(_currentData!);

      notifyListeners();
    });

    // Subscribe to connection state changes
    _connectionSubscription = _bluetoothService.connectionStateStream.listen((
      state,
    ) {
      _isConnected = state.index == 2; // BluetoothConnectionState.connected = 2
      notifyListeners();
    });

    notifyListeners();
  }

  /// Check for temperature and emergency alerts
  void _checkAlerts(SensorData data) {
    if (!_alertSettings.enableNotifications) return;

    // Check temperature alert
    if (_alertSettings.enableTemperatureAlert &&
        data.temperature >= _alertSettings.temperatureThreshold) {
      _notificationService.showTemperatureAlert(data.temperature);
    }

    // Check emergency alert
    if (_alertSettings.enableEmergencyAlert && data.emergencySignal) {
      _notificationService.showEmergencyAlert();
    }
  }

  /// Update alert settings
  Future<void> updateAlertSettings(AlertSettings settings) async {
    _alertSettings = settings;
    await _databaseService.saveAlertSettings(settings);
    notifyListeners();
  }

  /// Get temperature statistics for today
  Map<String, double> getTemperatureStatsToday() {
    final todayData = _databaseService.getSensorDataToday();
    return _databaseService.getTemperatureStats(todayData);
  }

  @override
  Future<void> dispose() async {
    await _dataSubscription.cancel();
    await _connectionSubscription.cancel();
    super.dispose();
  }
}
