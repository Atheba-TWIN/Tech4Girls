import 'package:hive/hive.dart';

part 'emergency_contact.g.dart';

@HiveType(typeId: 2)
class EmergencyContact {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final String? email;

  @HiveField(4)
  final String? relationship; // "parent", "ami", "autre"

  @HiveField(5)
  final bool notifyOnTemperatureAlert;

  @HiveField(6)
  final bool notifyOnEmergencyAlert;

  @HiveField(7)
  final bool notifyOnMovementAnomaly;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.relationship,
    this.notifyOnTemperatureAlert = true,
    this.notifyOnEmergencyAlert = true,
    this.notifyOnMovementAnomaly = false,
  });

  @override
  String toString() => 'EmergencyContact(name: $name, phone: $phoneNumber)';
}
