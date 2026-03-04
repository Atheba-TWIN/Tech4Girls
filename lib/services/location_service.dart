import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
import 'package:tech4girls/models/location_data.dart';

final _log = Logger('LocationService');

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  final StreamController<LocationData> _locationController =
      StreamController<LocationData>.broadcast();

  Stream<LocationData> get locationStream => _locationController.stream;

  LocationData? _currentLocation;

  LocationData? get currentLocation => _currentLocation;

  StreamSubscription<Position>? _positionStreamSubscription;

  /// Initialize location service
  Future<void> initialize() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Start real-time location updates (use defaults)
    _positionStreamSubscription = Geolocator.getPositionStream().listen((
      Position position,
    ) {
      final ts = position.timestamp;
      _currentLocation = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: ts,
      );
      _locationController.add(_currentLocation!);
    });
  }

  /// Get current location once
  Future<LocationData> getCurrentLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLocation = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );

      return _currentLocation!;
    } catch (e) {
      _log.shout('Error getting current location: $e');
      rethrow;
    }
  }

  /// Calculate distance between two coordinates (in meters)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopTracking();
    await _locationController.close();
  }
}
