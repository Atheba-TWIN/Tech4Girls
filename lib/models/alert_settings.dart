import 'package:hive/hive.dart';

part 'alert_settings.g.dart';

@HiveType(typeId: 1)
class AlertSettings extends HiveObject {
  @HiveField(0)
  double temperatureThreshold;

  @HiveField(1)
  bool enableTemperatureAlert;

  @HiveField(2)
  bool enableEmergencyAlert;

  @HiveField(3)
  bool enableNotifications;

  @HiveField(4)
  bool callAmbulanceOnEmergency;

  @HiveField(5)
  List<String> emergencyContactIds;

  @HiveField(6)
  bool enableMovementAnomaly;

  @HiveField(7)
  double movementAnomalyThreshold;

  // ✅ Constructeur avec TOUTES valeurs par défaut
  AlertSettings({
    this.temperatureThreshold = 38.0,
    this.enableTemperatureAlert = true,
    this.enableEmergencyAlert = true,
    this.enableNotifications = true,
    this.callAmbulanceOnEmergency = false,
    this.emergencyContactIds = const [],
    this.enableMovementAnomaly = false,
    this.movementAnomalyThreshold = 0.0,
  });
}
