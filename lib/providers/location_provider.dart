import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tech4girls/models/location_data.dart';
import 'package:tech4girls/services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  LocationData? _currentLocation;
  bool _isLoading = false;
  String? _error;

  late StreamSubscription<LocationData> _locationSubscription;

  LocationData? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _locationService.initialize();

      // Get initial location
      _currentLocation = await _locationService.getCurrentLocation();

      // Subscribe to location updates
      _locationSubscription = _locationService.locationStream.listen((
        location,
      ) {
        _currentLocation = location;
        _error = null;
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Request a single location update
  Future<LocationData?> getLocation() async {
    try {
      _isLoading = true;
      notifyListeners();

      final location = await _locationService.getCurrentLocation();
      _currentLocation = location;
      _error = null;

      _isLoading = false;
      notifyListeners();

      return location;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    await _locationSubscription.cancel();
    await _locationService.dispose();
    super.dispose();
  }
}
