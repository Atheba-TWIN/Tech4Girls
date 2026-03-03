import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static final BleService _instance = BleService._internal();

  factory BleService() {
    return _instance;
  }

  BleService._internal();

  late StreamSubscription<List<ScanResult>> _scanSubscription;
  late StreamSubscription<BluetoothConnectionState> _connectionSubscription;

  final StreamController<List<ScanResult>> _devicesController =
      StreamController<List<ScanResult>>.broadcast();
  final StreamController<BluetoothConnectionState> _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  final StreamController<List<int>> _dataController =
      StreamController<List<int>>.broadcast();

  Stream<List<ScanResult>> get devicesStream => _devicesController.stream;
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<List<int>> get dataStream => _dataController.stream;

  BluetoothDevice? _connectedDevice;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Start scanning for Bluetooth devices
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Check if Bluetooth is supported
      if (!await FlutterBluePlus.isSupported) {
        throw Exception('Bluetooth not supported on this device');
      }

      // Turn on Bluetooth if needed
      if (!(await FlutterBluePlus.isOn)) {
        throw Exception('Bluetooth is not turned on');
      }

      await FlutterBluePlus.startScan(timeout: timeout);

      _scanSubscription = FlutterBluePlus.scanResults.listen((
        List<ScanResult> results,
      ) {
        _devicesController.add(results);
      });
    } catch (e) {
      print('Error starting scan: $e');
      rethrow;
    }
  }

  /// Stop scanning for devices
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription.cancel();
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  /// Connect to a specific device
  Future<void> connect(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;

      // Listen to connection state changes
      _connectionSubscription = device.connectionState.listen((
        BluetoothConnectionState state,
      ) {
        _connectionStateController.add(state);
      });

      // Discover services and characteristics
      final services = await device.discoverServices();

      // Look for UART or similar service (typical for sensor bracelets)
      for (var service in services) {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.properties.notify) {
            await c.setNotifyValue(true);

            // Listen to notifications from the device
            c.onValueReceived.listen((List<int> value) {
              _dataController.add(value);
            });
          }
        }
      }

      print('Connected to ${device.remoteId}');
    } catch (e) {
      print('Error connecting to device: $e');
      rethrow;
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
      }
      await _connectionSubscription.cancel();
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  /// Parse sensor data from Bluetooth bytes
  ///
  /// Expected format (expandable):
  ///   [temperature_byte, emergency_bit, motion_bit]
  ///
  /// - temperature_byte: value*2 (so 98 -> 49.0°C)
  /// - emergency_bit: 1 = emergency active, 0 = normal
  /// - motion_bit: 1 = movement detected, 0 = still
  ///
  /// Example: [98, 0, 1] -> 49.0°C, no emergency, movement detected
  Map<String, dynamic> parseSensorData(List<int> data) {
    if (data.length < 2) {
      return {
        'temperature': 0.0,
        'emergencySignal': false,
        'motionDetected': false,
      };
    }

    // Parse temperature (assuming first byte is temperature * 2)
    double temperature = data[0] / 2.0;

    // Parse emergency signal (second byte: 1 = active, 0 = inactive)
    bool emergencySignal = data[1] == 1;

    // Parse motion detection (third byte if present)
    bool motionDetected = false;
    if (data.length >= 3) {
      motionDetected = data[2] == 1;
    }

    return {
      'temperature': temperature,
      'emergencySignal': emergencySignal,
      'motionDetected': motionDetected,
    };
  }

  /// Check if a device is connected
  bool get isConnected => _connectedDevice != null;

  /// Dispose resources
  Future<void> dispose() async {
    await stopScan();
    await disconnect();
    await _devicesController.close();
    await _connectionStateController.close();
    await _dataController.close();
  }
}
