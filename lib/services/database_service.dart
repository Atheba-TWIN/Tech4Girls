import 'package:hive_flutter/hive_flutter.dart';
import 'package:tech4girls/models/sensor_data.dart';
import 'package:tech4girls/models/alert_settings.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  late Box<SensorData> _sensorDataBox;
  late Box<AlertSettings> _alertSettingsBox;

  Box<SensorData> get sensorDataBox => _sensorDataBox;
  Box<AlertSettings> get alertSettingsBox => _alertSettingsBox;

  /// Initialize the Hive database
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(SensorDataAdapter());
    Hive.registerAdapter(AlertSettingsAdapter());

    // Open boxes
    _sensorDataBox = await Hive.openBox<SensorData>('sensor_data');
    _alertSettingsBox = await Hive.openBox<AlertSettings>('alert_settings');

    // Initialize default alert settings if not exists
    if (_alertSettingsBox.isEmpty) {
      await _alertSettingsBox.put('settings', AlertSettings());
    }
  }

  /// Save sensor data
  Future<int> saveSensorData(SensorData data) async {
    return await _sensorDataBox.add(data);
  }

  /// Get all sensor data
  List<SensorData> getAllSensorData() {
    return _sensorDataBox.values.toList();
  }

  /// Get sensor data for the last N hours
  List<SensorData> getSensorDataLastNHours(int hours) {
    final now = DateTime.now();
    final cutoffTime = now.subtract(Duration(hours: hours));

    return _sensorDataBox.values
        .where((data) => data.timestamp.isAfter(cutoffTime))
        .toList();
  }

  /// Get sensor data for today
  List<SensorData> getSensorDataToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _sensorDataBox.values
        .where((data) => data.timestamp.isAfter(today))
        .toList();
  }

  /// Get temperature statistics
  Map<String, double> getTemperatureStats(List<SensorData> data) {
    if (data.isEmpty) {
      return {'min': 0.0, 'max': 0.0, 'average': 0.0};
    }

    double min = data[0].temperature;
    double max = data[0].temperature;
    double sum = 0;

    for (var reading in data) {
      if (reading.temperature < min) min = reading.temperature;
      if (reading.temperature > max) max = reading.temperature;
      sum += reading.temperature;
    }

    return {'min': min, 'max': max, 'average': sum / data.length};
  }

  /// Save alert settings
  Future<void> saveAlertSettings(AlertSettings settings) async {
    await _alertSettingsBox.put('settings', settings);
  }

  /// Get alert settings
  AlertSettings getAlertSettings() {
    return _alertSettingsBox.get('settings') ?? AlertSettings();
  }

  /// Delete all sensor data
  Future<void> clearAllSensorData() async {
    await _sensorDataBox.clear();
  }

  /// Delete sensor data older than N days
  Future<void> deleteOldSensorData(int days) async {
    final cutoffTime = DateTime.now().subtract(Duration(days: days));

    final keysToDelete = <dynamic>[];
    _sensorDataBox.toMap().forEach((key, value) {
      if (value.timestamp.isBefore(cutoffTime)) {
        keysToDelete.add(key);
      }
    });

    for (var key in keysToDelete) {
      await _sensorDataBox.delete(key);
    }
  }

  /// Close database
  Future<void> close() async {
    await Hive.close();
  }
}
