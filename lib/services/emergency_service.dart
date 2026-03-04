import 'package:tech4girls/models/emergency_contact.dart';
import 'package:tech4girls/models/sensor_data.dart';
import 'package:tech4girls/services/database_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

final _log = Logger('EmergencyService');

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();

  factory EmergencyService() {
    return _instance;
  }

  EmergencyService._internal();

  final DatabaseService _databaseService = DatabaseService();
  static const MethodChannel _smsChannel = MethodChannel('tech4girls/sms');

  /// Send emergency alerts to all configured contacts
  Future<void> notifyEmergencyContacts({
    required List<String> contactIds,
    required SensorData sensorData,
    required String messageType, // "temperature", "emergency", "movement"
  }) async {
    try {
      final contacts = await _loadContacts(contactIds);

      for (final contact in contacts) {
        // Check notification preferences based on alert type
        bool shouldNotify = false;
        String messageBody = '';

        switch (messageType) {
          case 'temperature':
            shouldNotify = contact.notifyOnTemperatureAlert;
            messageBody =
                'Alerte température: ${sensorData.temperature.toStringAsFixed(1)}°C';
            break;
          case 'emergency':
            shouldNotify = contact.notifyOnEmergencyAlert;
            messageBody = 'ALERTE URGENCE: Signal d\'urgence activé!';
            break;
          case 'movement':
            shouldNotify = contact.notifyOnMovementAnomaly;
            messageBody =
                'Anomalie de mouvement détectée à ${sensorData.timestamp}';
            break;
        }

        if (shouldNotify) {
          // Send SMS via tel: URL (opens dialer)
          await _sendSMS(contact.phoneNumber, messageBody);

          // Send email if available
          if (contact.email != null) {
            await _sendEmail(
              contact.email!,
              'Alerte Santé - Tech4Girls',
              messageBody,
              sensorData,
            );
          }

          // Log the notification
          await _databaseService.logEmergencyNotification(
            contactId: contact.id,
            contactName: contact.name,
            messageType: messageType,
            timestamp: DateTime.now(),
          );
        }
      }
    } catch (e) {
      _log.shout('Error notifying emergency contacts: $e');
    }
  }

  /// Call the nearest ambulance (placeholder - requires API integration)
  Future<void> callNearestAmbulance({
    required SensorData sensorData,
    required String patientName,
  }) async {
    try {
      // This is a placeholder. In production, you would:
      // 1. Get the call center's phone number for your region
      // 2. Use a real emergency API (e.g., Google Maps Emergency API)
      // 3. Send location data automatically

      // For now, prompt user to make emergency call
      String emergencyNumber = '15'; // SAMU in France
      String message =
          'Appel ambulance - Patient: $patientName, Position: ${sensorData.latitude}, ${sensorData.longitude}';

      await _sendSMS(emergencyNumber, message);

      _log.info('Emergency call initiated to $emergencyNumber');
    } catch (e) {
      _log.shout('Error calling ambulance: $e');
    }
  }

  /// Find nearest ambulances using location data (placeholder)
  Future<List<Map<String, dynamic>>> findNearestAmbulances({
    required double latitude,
    required double longitude,
  }) async {
    // This would integrate with a real emergency services API
    // For now, returning empty list
    // In production: use Google Maps Places API or local emergency service API
    return [];
  }

  /// Send SMS. On Android, tries direct send first, then falls back to composer.
  Future<void> _sendSMS(String phoneNumber, String message) async {
    final sentSilently = await _trySendSmsSilently(phoneNumber, message);
    if (sentSilently) return;

    await _openSmsComposer(phoneNumber, message);
  }

  Future<bool> _trySendSmsSilently(String phoneNumber, String message) async {
    try {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        return false;
      }

      final status = await Permission.sms.request();
      if (!status.isGranted) {
        _log.warning('SMS permission denied.');
        return false;
      }

      final result = await _smsChannel.invokeMethod<bool>('sendSms', {
        'phoneNumber': phoneNumber,
        'message': message,
      });
      return result ?? false;
    } catch (e) {
      _log.shout('Error sending SMS silently: $e');
      return false;
    }
  }

  Future<void> _openSmsComposer(String phoneNumber, String message) async {
    try {
      final smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        _log.warning('Could not launch SMS composer to $phoneNumber');
      }
    } on PlatformException catch (e) {
      _log.shout('SMS composer platform error: ${e.message}');
    } catch (e) {
      _log.shout('Error launching SMS composer: $e');
    }
  }

  /// Send email using mailto: schema
  Future<void> _sendEmail(
    String email,
    String subject,
    String body,
    SensorData sensorData,
  ) async {
    try {
      final emailBody = '''
$body

---
Heure: ${sensorData.timestamp}
Température: ${sensorData.temperature.toStringAsFixed(1)}°C
Signal d'urgence: ${sensorData.emergencySignal ? 'OUI' : 'NON'}
Mouvement: ${sensorData.motionDetected ? 'Détecté' : 'Aucun'}
${sensorData.latitude != null ? 'Position: ${sensorData.latitude}, ${sensorData.longitude}' : 'Position: Non disponible'}
      ''';

      final mailtoUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {'subject': subject, 'body': emailBody},
      );

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
      }
    } catch (e) {
      _log.shout('Error launching email: $e');
    }
  }

  /// Load emergency contacts from database
  Future<List<EmergencyContact>> _loadContacts(List<String> contactIds) async {
    final allContacts = await _databaseService.getEmergencyContacts();
    return allContacts.where((c) => contactIds.contains(c.id)).toList();
  }

  /// Get all emergency contacts
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    return _databaseService.getEmergencyContacts();
  }

  /// Save emergency contact
  Future<void> saveEmergencyContact(EmergencyContact contact) async {
    await _databaseService.saveEmergencyContact(contact);
  }

  /// Delete emergency contact
  Future<void> deleteEmergencyContact(String contactId) async {
    await _databaseService.deleteEmergencyContact(contactId);
  }
}
