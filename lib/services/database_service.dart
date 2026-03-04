import 'package:hive_flutter/hive_flutter.dart';
import 'package:tech4girls/models/sensor_data.dart';
import 'package:tech4girls/models/alert_settings.dart';
import 'package:tech4girls/models/emergency_contact.dart';
import 'package:tech4girls/models/user_profile.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Box<SensorData>? _sensorDataBox;
  Box<AlertSettings>? _alertSettingsBox;
  Box<EmergencyContact>? _emergencyContactBox;
  Box<Map>? _emergencyLogsBox;
  Box<bool>? _prefsBox;
  Box<UserProfile>? _userProfileBox;
  Box<dynamic>? _appStateBox;

  Box<SensorData>? get sensorDataBox => _sensorDataBox;
  Box<AlertSettings>? get alertSettingsBox => _alertSettingsBox;
  Box<EmergencyContact>? get emergencyContactBox => _emergencyContactBox;
  Box<UserProfile>? get userProfileBox => _userProfileBox;

  /// Initialize the Hive database
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(SensorDataAdapter());
    Hive.registerAdapter(AlertSettingsAdapter());
    Hive.registerAdapter(EmergencyContactAdapter());
    Hive.registerAdapter(UserProfileAdapter());

    // Open boxes
    _sensorDataBox = await Hive.openBox<SensorData>('sensor_data');
    _alertSettingsBox = await Hive.openBox<AlertSettings>('alert_settings');
    _emergencyContactBox = await Hive.openBox<EmergencyContact>(
      'emergency_contacts',
    );
    _emergencyLogsBox = await Hive.openBox<Map>('emergency_logs');
    _prefsBox = await Hive.openBox<bool>('prefs');
    _userProfileBox = await Hive.openBox<UserProfile>('user_profiles');
    _appStateBox = await Hive.openBox<dynamic>('app_state');

    // Initialize default alert settings if not exists
    if (_alertSettingsBox != null && _alertSettingsBox!.isEmpty) {
      await _alertSettingsBox!.put('settings', AlertSettings());
    }

  }

  /// Save sensor data
  Future<int> saveSensorData(SensorData data) async {
    if (_sensorDataBox == null) return -1;
    return await _sensorDataBox!.add(data);
  }

  /// Get all sensor data
  List<SensorData> getAllSensorData() {
    if (_sensorDataBox == null) return [];
    return _sensorDataBox!.values.toList();
  }

  /// Get sensor data for the last N hours
  List<SensorData> getSensorDataLastNHours(int hours) {
    if (_sensorDataBox == null) return [];
    final now = DateTime.now();
    final cutoffTime = now.subtract(Duration(hours: hours));

    return _sensorDataBox!.values
        .where((data) => data.timestamp.isAfter(cutoffTime))
        .toList();
  }

  /// Get sensor data for today
  List<SensorData> getSensorDataToday() {
    if (_sensorDataBox == null) return [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _sensorDataBox!.values
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
    if (_alertSettingsBox != null) {
      await _alertSettingsBox!.put('settings', settings);
    }
  }

  /// Get alert settings
  AlertSettings getAlertSettings() {
    if (_alertSettingsBox == null) return AlertSettings();
    return _alertSettingsBox!.get('settings') ?? AlertSettings();
  }

  /// Delete all sensor data
  Future<void> clearAllSensorData() async {
    if (_sensorDataBox != null) {
      await _sensorDataBox!.clear();
    }
  }

  /// Delete sensor data older than N days
  Future<void> deleteOldSensorData(int days) async {
    if (_sensorDataBox == null) return;
    final cutoffTime = DateTime.now().subtract(Duration(days: days));

    final keysToDelete = <dynamic>[];
    _sensorDataBox!.toMap().forEach((key, value) {
      if (value.timestamp.isBefore(cutoffTime)) {
        keysToDelete.add(key);
      }
    });

    for (var key in keysToDelete) {
      await _sensorDataBox!.delete(key);
    }
  }

  // === Emergency Contacts Management ===

  /// Save or update emergency contact
  Future<void> saveEmergencyContact(EmergencyContact contact) async {
    if (_emergencyContactBox != null) {
      await _emergencyContactBox!.put(contact.id, contact);
    }
  }

  /// Get all emergency contacts
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    if (_emergencyContactBox == null) return [];
    return _emergencyContactBox!.values.toList();
  }

  /// Get emergency contact by ID
  Future<EmergencyContact?> getEmergencyContact(String contactId) async {
    if (_emergencyContactBox == null) return null;
    return _emergencyContactBox!.get(contactId);
  }

  /// Delete emergency contact
  Future<void> deleteEmergencyContact(String contactId) async {
    if (_emergencyContactBox != null) {
      await _emergencyContactBox!.delete(contactId);
    }
  }

  /// Update contact notification preferences
  Future<void> updateContactPreferences(
    String contactId,
    bool notifyTemp,
    bool notifyEmergency,
    bool notifyMovement,
  ) async {
    final contact = await getEmergencyContact(contactId);
    if (contact != null) {
      final updated = EmergencyContact(
        id: contact.id,
        name: contact.name,
        phoneNumber: contact.phoneNumber,
        email: contact.email,
        relationship: contact.relationship,
        notifyOnTemperatureAlert: notifyTemp,
        notifyOnEmergencyAlert: notifyEmergency,
        notifyOnMovementAnomaly: notifyMovement,
      );
      await saveEmergencyContact(updated);
    }
  }

  // === Emergency Notification Logs ===

  /// Log an emergency notification sent
  Future<void> logEmergencyNotification({
    required String contactId,
    required String contactName,
    required String messageType,
    required DateTime timestamp,
  }) async {
    if (_emergencyLogsBox == null) return;
    final logId = '${timestamp.millisecondsSinceEpoch}_$contactId';
    await _emergencyLogsBox!.put(logId, {
      'contactId': contactId,
      'contactName': contactName,
      'messageType': messageType,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  /// Get emergency notification logs
  Future<List<Map<String, dynamic>>> getEmergencyLogs({Duration? since}) async {
    final logs = <Map<String, dynamic>>[];
    if (_emergencyLogsBox == null) return logs;
    final cutoffTime = since != null ? DateTime.now().subtract(since) : null;

    _emergencyLogsBox!.toMap().forEach((key, value) {
      final timestamp = DateTime.parse(value['timestamp'] as String);
      if (cutoffTime == null || timestamp.isAfter(cutoffTime)) {
        logs.add({...value, 'timestamp': timestamp});
      }
    });

    // Sort by timestamp descending
    logs.sort(
      (a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
    );
    return logs;
  }

  /// Clear all emergency logs
  Future<void> clearEmergencyLogs() async {
    if (_emergencyLogsBox == null) return;
    await _emergencyLogsBox!.clear();
  }

  /// Return whether onboarding has been completed
  bool isOnboardingComplete() {
    if (_prefsBox == null) return false;
    return _prefsBox!.get('onboardingComplete', defaultValue: false) ?? false;
  }

  /// Mark onboarding as finished
  Future<void> setOnboardingComplete(bool value) async {
    if (_prefsBox != null) {
      await _prefsBox!.put('onboardingComplete', value);
    }
  }

  // === Home UI State ===

  /// Save taken medication reminder indexes
  Future<void> saveTakenMedicationIndexes(List<int> indexes) async {
    if (_appStateBox == null) return;
    await _appStateBox!.put('takenMedicationIndexes', indexes);
  }

  /// Get taken medication reminder indexes
  List<int> getTakenMedicationIndexes() {
    if (_appStateBox == null) return [];
    final raw = _appStateBox!.get('takenMedicationIndexes');
    if (raw is List) {
      return raw
          .whereType<dynamic>()
          .map((e) => e is int ? e : int.tryParse('$e'))
          .whereType<int>()
          .toList();
    }
    return [];
  }

  /// Save medication reminders list
  Future<void> saveMedicationReminders(List<Map<String, String>> reminders) async {
    if (_appStateBox == null) return;
    await _appStateBox!.put('medicationReminders', reminders);
  }

  /// Get medication reminders list
  List<Map<String, String>> getMedicationReminders() {
    if (_appStateBox == null) return [];
    final raw = _appStateBox!.get('medicationReminders');
    if (raw is List) {
      return raw
          .whereType<dynamic>()
          .map((item) => Map<String, String>.from(item as Map))
          .toList();
    }
    return [];
  }

  // === User Profile Management ===

  /// Save or update user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    if (_userProfileBox != null) {
      await _userProfileBox!.put(profile.userId, profile);
    }
  }

  /// Get user profile by ID
  UserProfile? getUserProfile(String userId) {
    if (_userProfileBox == null) return null;
    return _userProfileBox!.get(userId);
  }

  /// Get all user profiles
  List<UserProfile> getAllUserProfiles() {
    if (_userProfileBox == null) return [];
    return _userProfileBox!.values.toList();
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    if (_userProfileBox != null) {
      await _userProfileBox!.delete(userId);
    }
  }

  /// Close database
  Future<void> close() async {
    await Hive.close();
  }
}
