import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 3)
class UserProfile {
  @HiveField(0)
  final String userId; // Firebase UID

  @HiveField(1)
  final String firstName;

  @HiveField(2)
  final String lastName;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final DateTime dateOfBirth;

  @HiveField(5)
  final String gender; // "M", "F"

  @HiveField(6)
  final String phoneNumber;

  @HiveField(7)
  final List<String> emergencyContacts; // phone numbers

  @HiveField(8)
  final double? weight; // in kg, optional

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
    required this.phoneNumber,
    required this.emergencyContacts,
    this.weight,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  String toString() =>
      'UserProfile(name: $firstName $lastName, email: $email, phone: $phoneNumber)';
}
