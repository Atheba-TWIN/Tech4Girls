import 'package:hive/hive.dart';

part 'alert_settings.g.dart';

@HiveType(typeId: 1)
class AlertSettings {
  @HiveField(0)
  double temperatureThreshold;

  @HiveField(1)
  bool enableTemperatureAlert;

  @HiveField(2)
  bool enableEmergencyAlert;

  @HiveField(3)
  bool enableNotifications;

  AlertSettings({
    this.temperatureThreshold = 38.0,
    this.enableTemperatureAlert = true,
    this.enableEmergencyAlert = true,
    this.enableNotifications = true,
  });

  @override
  String toString() =>
      'AlertSettings(tempThreshold: $temperatureThreshold°C, enabled: $enableNotifications)';
}
