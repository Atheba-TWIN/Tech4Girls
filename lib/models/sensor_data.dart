import 'package:hive/hive.dart';

part 'sensor_data.g.dart';

@HiveType(typeId: 0)
class SensorData {
  @HiveField(0)
  final double temperature;

  @HiveField(1)
  final bool emergencySignal;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final double? latitude;

  @HiveField(4)
  final double? longitude;

  // new field: motion detection flag coming from the wearable
  @HiveField(5)
  final bool motionDetected;

  SensorData({
    required this.temperature,
    required this.emergencySignal,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.motionDetected = false,
  });

  @override
  String toString() =>
      'SensorData(temp: $temperature°C, emergency: $emergencySignal, motion: $motionDetected, at: $timestamp)';
}
