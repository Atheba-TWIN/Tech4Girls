import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:tech4girls/services/bluetooth_service.dart';

class BluetoothProvider extends ChangeNotifier {
  final BleService _bluetoothService = BleService();

  List<ScanResult> _devices = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  String? _error;

  late StreamSubscription<List<ScanResult>> _devicesSubscription;
  late StreamSubscription<BluetoothConnectionState> _connectionSubscription;

  List<ScanResult> get devices => _devices;
  bool get isScanning => _isScanning;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String? get error => _error;

  /// Start scanning for devices
  Future<void> startScan() async {
    try {
      _isScanning = true;
      _error = null;
      notifyListeners();

      await _bluetoothService.startScan();

      _devicesSubscription = _bluetoothService.devicesStream.listen((devices) {
        _devices = devices;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    try {
      await _bluetoothService.stopScan();
      _isScanning = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Connect to a device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _error = null;
      notifyListeners();

      await _bluetoothService.connect(device);
      _connectedDevice = device;

      // Stop scanning after connecting
      await stopScan();

      // Listen to connection state changes
      _connectionSubscription = _bluetoothService.connectionStateStream.listen((
        state,
      ) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
        }
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Disconnect from device
  Future<void> disconnectDevice() async {
    try {
      await _bluetoothService.disconnect();
      _connectedDevice = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear devices list
  void clearDevices() {
    _devices = [];
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    try {
      await _devicesSubscription.cancel();
      await _connectionSubscription.cancel();
    } catch (e) {
      // Already cancelled
    }
    await _bluetoothService.dispose();
    super.dispose();
  }
}
