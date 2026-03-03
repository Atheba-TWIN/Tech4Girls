import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tech4girls/providers/bluetooth_provider.dart';
import 'package:tech4girls/providers/sensor_data_provider.dart';
import 'package:tech4girls/providers/location_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi Drépanocytaire'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status Card
              _buildConnectionCard(),
              const SizedBox(height: 16),

              // Temperature Card
              _buildTemperatureCard(),
              const SizedBox(height: 16),

              // Emergency Status Card
              _buildEmergencyCard(),
              const SizedBox(height: 16),

              // Motion Status Card
              _buildMotionCard(),
              const SizedBox(height: 16),

              // Location Card
              _buildLocationCard(),
              const SizedBox(height: 16),

              // Map
              _buildMapCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildBluetoothFAB(),
    );
  }

  Widget _buildConnectionCard() {
    return Consumer<BluetoothProvider>(
      builder: (context, btProvider, _) {
        bool isConnected = btProvider.connectedDevice != null;
        return Card(
          elevation: 4,
          color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'État de Connexion',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        isConnected
                            ? 'Connecté: ${btProvider.connectedDevice?.platformName ?? 'Bracelet'}'
                            : 'Déconnecté',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemperatureCard() {
    return Consumer<SensorDataProvider>(
      builder: (context, sensorProvider, _) {
        final data = sensorProvider.currentData;
        final temp = data?.temperature ?? 0.0;
        final isAlert =
            temp >= sensorProvider.alertSettings.temperatureThreshold;

        return Card(
          elevation: 4,
          color: isAlert ? Colors.orange.shade50 : Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Température',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    if (isAlert)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Alerte',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${temp.toStringAsFixed(1)}°C',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: isAlert ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seuil d\'alerte: ${sensorProvider.alertSettings.temperatureThreshold}°C',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyCard() {
    return Consumer<SensorDataProvider>(
      builder: (context, sensorProvider, _) {
        final isEmergency =
            sensorProvider.currentData?.emergencySignal ?? false;

        return Card(
          elevation: 4,
          color: isEmergency ? Colors.red.shade50 : Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEmergency ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signal d\'Urgence',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        isEmergency ? 'ACTIVÉ' : 'Normal',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isEmergency ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMotionCard() {
    return Consumer<SensorDataProvider>(
      builder: (context, sensorProvider, _) {
        final motion = sensorProvider.currentData?.motionDetected ?? false;

        return Card(
          elevation: 4,
          color: motion ? Colors.blue.shade50 : Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  motion ? Icons.directions_walk : Icons.pan_tool,
                  color: motion ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mouvement',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        motion ? 'Détecté' : 'Aucun',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: motion ? Colors.blue : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationCard() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        final location = locationProvider.currentLocation;
        if (location == null) {
          return Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Localisation',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  if (locationProvider.isLoading)
                    const CircularProgressIndicator()
                  else if (locationProvider.error != null)
                    Text(
                      'Erreur: ${locationProvider.error}',
                      style: const TextStyle(color: Colors.red),
                    )
                  else
                    const Text('Localisation non disponible'),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Localisation GPS',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Latitude: ${location.latitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Longitude: ${location.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Précision: ${location.accuracy.toStringAsFixed(2)}m',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapCard() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        final location = locationProvider.currentLocation;
        if (location == null) {
          return Card(
            elevation: 4,
            child: SizedBox(
              height: 300,
              child: Center(
                child:
                    locationProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Localisation non disponible'),
              ),
            ),
          );
        }

        return Card(
          elevation: 4,
          child: SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(location.latitude, location.longitude),
                zoom: 15,
              ),
              onMapCreated: (controller) {},
              markers: {
                Marker(
                  markerId: const MarkerId('current_location'),
                  position: LatLng(location.latitude, location.longitude),
                  infoWindow: const InfoWindow(title: 'Ma position'),
                ),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBluetoothFAB() {
    return Consumer<BluetoothProvider>(
      builder: (context, btProvider, _) {
        bool isConnected = btProvider.connectedDevice != null;
        return FloatingActionButton(
          onPressed: () {
            if (isConnected) {
              btProvider.disconnectDevice();
            } else {
              // Navigate to scan screen
              Navigator.of(context).pushNamed('/scan');
            }
          },
          backgroundColor: isConnected ? Colors.red : Colors.blue,
          child: Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
          ),
        );
      },
    );
  }
}
