# Guide d'Utilisation et Exemples de Code

## Vue d'ensemble

Ce guide contient des exemples d'utilisation des services et providers de l'application.

## Services

### 1. BluetoothService

#### Démarrer la recherche de périphériques

```dart
final bluetoothService = BluetoothService();

// Lancer la recherche
await bluetoothService.startScan(timeout: Duration(seconds: 15));

// Écouter les appareils trouvés
bluetoothService.devicesStream.listen((devices) {
  for (var device in devices) {
    print('Trouvé: ${device.device.platformName}');
  }
});
```

#### Se connecter à un appareil

```dart
final device = devices.first.device;

try {
  await bluetoothService.connect(device);
  print('Connecté à ${device.platformName}');
} catch (e) {
  print('Erreur de connexion: $e');
}
```

#### Écouter les données

```dart
bluetoothService.dataStream.listen((data) {
  final parsed = bluetoothService.parseSensorData(data);
  double temperature = parsed['temperature'];
  bool emergency = parsed['emergencySignal'];

  print('Température: ${temperature}°C');
  print('Urgence: $emergency');
});
```

#### Arrêter et déconnecter

```dart
// Arrêter la recherche
await bluetoothService.stopScan();

// Se déconnecter
await bluetoothService.disconnect();

// Libérer les ressources
await bluetoothService.dispose();
```

### 2. NotificationService

#### Initialiser le service

```dart
final notificationService = NotificationService();
await notificationService.initialize();
```

#### Afficher une alerte de température

```dart
await notificationService.showTemperatureAlert(38.5);
// Affiche: "Alerte Température - Température élevée détectée: 38.5°C"
```

#### Afficher une alerte d'urgence

```dart
await notificationService.showEmergencyAlert();
// Affiche: "Alerte Urgence - Signal d'urgence activé!"
```

#### Afficher une notification personnalisée

```dart
await notificationService.showInfoNotification(
  'Message Important',
  'Contenu de la notification'
);
```

#### Annuler une notification

```dart
await notificationService.cancel(1); // Annuler température
await notificationService.cancel(2); // Annuler urgence
await notificationService.cancelAll(); // Annuler tout
```

### 3. LocationService

#### Initialiser le service

```dart
final locationService = LocationService();
await locationService.initialize();
// Demande les permissions automatiquement

// Écouter les mises à jour de localisation
locationService.locationStream.listen((location) {
  print('Position: ${location.latitude}, ${location.longitude}');
  print('Précision: ${location.accuracy}m');
});
```

#### Obtenir la position actuelle

```dart
try {
  final location = await locationService.getCurrentLocation();
  print('Latitude: ${location.latitude}');
  print('Longitude: ${location.longitude}');
  print('Accuracy: ${location.accuracy} mètres');
} catch (e) {
  print('Erreur: $e');
}
```

#### Calculer la distance entre deux points

```dart
double distanceInMeters = LocationService.calculateDistance(
  48.8566, // Latitude Paris
  2.3522,  // Longitude Paris
  51.5074, // Latitude Londres
  -0.1278  // Longitude Londres
);
print('Distance: ${distanceInMeters / 1000} km');
```

#### Arrêter le suivi

```dart
await locationService.stopTracking();
await locationService.dispose();
```

### 4. DatabaseService

#### Initialiser la base de données

```dart
final databaseService = DatabaseService();
await databaseService.initialize();
```

#### Sauvegarder une mesure

```dart
final sensorData = SensorData(
  temperature: 37.5,
  emergencySignal: false,
  timestamp: DateTime.now(),
);

int id = await databaseService.saveSensorData(sensorData);
print('Mesure sauvegardée avec ID: $id');
```

#### Récupérer les données

```dart
// Toutes les données
List<SensorData> allData = databaseService.getAllSensorData();

// Données des 24 dernières heures
List<SensorData> todayData = databaseService.getSensorDataToday();

// Données des 7 derniers jours
List<SensorData> weekData = databaseService.getSensorDataLastNHours(24 * 7);

// Données personnalisées
final cutoff = DateTime.now().subtract(Duration(hours: 12));
List<SensorData> custom = databaseService.sensorDataBox.values
  .where((d) => d.timestamp.isAfter(cutoff))
  .toList();
```

#### Statistiques

```dart
final data = databaseService.getSensorDataToday();
final stats = databaseService.getTemperatureStats(data);

double minTemp = stats['min']!;
double maxTemp = stats['max']!;
double avgTemp = stats['average']!;

print('Min: $minTemp°C');
print('Max: $maxTemp°C');
print('Moyenne: $avgTemp°C');
```

#### Gérer les paramètres d'alerte

```dart
// Récupérer les paramètres actuels
AlertSettings settings = databaseService.getAlertSettings();

// Modifier les paramètres
final newSettings = AlertSettings(
  temperatureThreshold: 39.0,
  enableTemperatureAlert: true,
  enableEmergencyAlert: true,
  enableNotifications: true,
);

// Sauvegarder
await databaseService.saveAlertSettings(newSettings);
```

#### Supprimer les données anciennes

```dart
// Supprimer les données de plus de 30 jours
await databaseService.deleteOldSensorData(30);

// Supprimer toutes les données
await databaseService.clearAllSensorData();
```

## Providers (State Management)

### 1. BluetoothProvider

#### Utiliser dans un Widget

```dart
Consumer<BluetoothProvider>(
  builder: (context, btProvider, child) {
    return Column(
      children: [
        Text('Scanning: ${btProvider.isScanning}'),
        Text('Connected: ${btProvider.connectedDevice != null}'),
        if (btProvider.error != null)
          Text('Error: ${btProvider.error}', style: TextStyle(color: Colors.red)),
        ListView.builder(
          itemCount: btProvider.devices.length,
          itemBuilder: (context, index) {
            final device = btProvider.devices[index];
            return ListTile(
              title: Text(device.device.platformName),
              subtitle: Text(device.device.remoteId.toString()),
              onTap: () => btProvider.connectToDevice(device.device),
            );
          },
        ),
      ],
    );
  },
)
```

#### Contrôler le scanning

```dart
final btProvider = context.read<BluetoothProvider>();

// Démarrer
await btProvider.startScan();

// Arrêter
await btProvider.stopScan();

// Connecter
await btProvider.connectToDevice(device);

// Déconnecter
await btProvider.disconnectDevice();

// Effacer la liste
btProvider.clearDevices();
```

### 2. SensorDataProvider

#### Obtenir les données actuelles

```dart
Consumer<SensorDataProvider>(
  builder: (context, sensorProvider, _) {
    final currentData = sensorProvider.currentData;

    if (currentData == null) {
      return Text('En attente de données...');
    }

    return Column(
      children: [
        Text('Température: ${currentData.temperature}°C'),
        Text('Urgence: ${currentData.emergencySignal ? "OUI" : "NON"}'),
        Text('Heure: ${currentData.timestamp}'),
      ],
    );
  },
)
```

#### Historique et statistiques

```dart
final sensorProvider = context.read<SensorDataProvider>();

// Historique complet
List<SensorData> history = sensorProvider.sensorHistory;

// Statistiques du jour
Map<String, double> stats = sensorProvider.getTemperatureStatsToday();
print('Moyenne: ${stats['average']}°C');
```

#### Paramètres d'alerte

```dart
final settings = sensorProvider.alertSettings;

// Modifier et sauvegarder
final newSettings = AlertSettings(
  temperatureThreshold: 39.0,
  enableTemperatureAlert: true,
  enableEmergencyAlert: true,
  enableNotifications: true,
);

await sensorProvider.updateAlertSettings(newSettings);
```

### 3. LocationProvider

#### Obtenir la position actuelle

```dart
Consumer<LocationProvider>(
  builder: (context, locationProvider, _) {
    if (locationProvider.isLoading) {
      return CircularProgressIndicator();
    }

    if (locationProvider.error != null) {
      return Text('Erreur: ${locationProvider.error}');
    }

    final location = locationProvider.currentLocation;
    if (location == null) {
      return Text('Localisation non disponible');
    }

    return Column(
      children: [
        Text('Latitude: ${location.latitude}'),
        Text('Longitude: ${location.longitude}'),
        Text('Précision: ${location.accuracy}m'),
      ],
    );
  },
)
```

#### Demander une localisation

```dart
final locationProvider = context.read<LocationProvider>();
final location = await locationProvider.getLocation();

if (location != null) {
  print('Latitude: ${location.latitude}');
  print('Longitude: ${location.longitude}');
}
```

## Patterns d'Utilisation

### Pattern 1: Alerte en Temps Réel

```dart
class TemperatureAlerter {
  final SensorDataProvider sensorProvider;
  final NotificationService notificationService;
  bool previouslyAlerting = false;

  TemperatureAlerter({
    required this.sensorProvider,
    required this.notificationService,
  });

  void checkAlerts() {
    final data = sensorProvider.currentData;
    if (data == null) return;

    final threshold = sensorProvider.alertSettings.temperatureThreshold;

    if (data.temperature >= threshold && !previouslyAlerting) {
      notificationService.showTemperatureAlert(data.temperature);
      previouslyAlerting = true;
    } else if (data.temperature < threshold && previouslyAlerting) {
      previouslyAlerting = false;
    }

    if (data.emergencySignal) {
      notificationService.showEmergencyAlert();
    }
  }
}
```

### Pattern 2: Export de Données

```dart
String exportToCsv(List<SensorData> data) {
  StringBuffer csv = StringBuffer();
  csv.writeln('Timestamp,Temperature,Emergency');

  for (var reading in data) {
    csv.writeln(
      '${reading.timestamp},${reading.temperature},${reading.emergencySignal}'
    );
  }

  return csv.toString();
}

Future<void> shareDataAsCsv(BuildContext context) async {
  final databaseService = DatabaseService();
  final data = databaseService.getSensorDataToday();
  final csv = exportToCsv(data);

  // Utiliser share ou file_picker pour exporter
}
```

### Pattern 3: Synchronisation Nuage

```dart
class CloudSyncService {
  final DatabaseService database;
  final String apiEndpoint;

  CloudSyncService({
    required this.database,
    required this.apiEndpoint,
  });

  Future<void> syncToCloud() async {
    final data = database.sensorDataBox.values.toList();

    try {
      final response = await http.post(
        Uri.parse('$apiEndpoint/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': data.map((d) => {
            'temperature': d.temperature,
            'emergencySignal': d.emergencySignal,
            'timestamp': d.timestamp.toIso8601String(),
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        print('✓ Data synced successfully');
      }
    } catch (e) {
      print('✗ Sync failed: $e');
    }
  }
}
```

### Pattern 4: Graphiques Avancés

```dart
class TemperatureChartData {
  final List<FlSpot> spots;
  final double minTemp;
  final double maxTemp;
  final double avgTemp;

  TemperatureChartData({
    required this.spots,
    required this.minTemp,
    required this.maxTemp,
    required this.avgTemp,
  });

  factory TemperatureChartData.fromSensorData(List<SensorData> data) {
    if (data.isEmpty) {
      return TemperatureChartData(
        spots: [],
        minTemp: 0,
        maxTemp: 0,
        avgTemp: 0,
      );
    }

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.temperature);
    }).toList();

    double minTemp = data[0].temperature;
    double maxTemp = data[0].temperature;
    double sum = 0;

    for (var d in data) {
      if (d.temperature < minTemp) minTemp = d.temperature;
      if (d.temperature > maxTemp) maxTemp = d.temperature;
      sum += d.temperature;
    }

    return TemperatureChartData(
      spots: spots,
      minTemp: minTemp,
      maxTemp: maxTemp,
      avgTemp: sum / data.length,
    );
  }
}
```

### Pattern 5: Gestion d'Erreur

```dart
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'Erreur de connectivité réseau';
    } else if (error is TimeoutException) {
      return 'Délai d\'attente dépassé';
    } else if (error is Exception) {
      return error.toString();
    }
    return 'Erreur inconnue';
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(error)),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

## Tests Unitaires

### Test du Service Bluetooth

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BluetoothService', () {
    late BluetoothService bluetoothService;

    setUp(() {
      bluetoothService = BluetoothService();
    });

    test('Parse sensor data correctly', () {
      final data = [76, 0]; // 38°C, no emergency
      final parsed = bluetoothService.parseSensorData(data);

      expect(parsed['temperature'], 38.0);
      expect(parsed['emergencySignal'], false);
    });

    test('Parse emergency signal', () {
      final data = [76, 1]; // 38°C, emergency
      final parsed = bluetoothService.parseSensorData(data);

      expect(parsed['emergencySignal'], true);
    });
  });
}
```

### Test de la Base de Données

```dart
void main() {
  group('DatabaseService', () {
    late DatabaseService databaseService;

    setUpAll(() async {
      databaseService = DatabaseService();
      await databaseService.initialize();
    });

    test('Save and retrieve sensor data', () async {
      final data = SensorData(
        temperature: 37.5,
        emergencySignal: false,
        timestamp: DateTime.now(),
      );

      await databaseService.saveSensorData(data);
      final allData = databaseService.getAllSensorData();

      expect(allData, isNotEmpty);
      expect(allData.last.temperature, 37.5);
    });

    tearDownAll(() async {
      await databaseService.close();
    });
  });
}
```

---

**Version**: 1.0.0  
**Dernier mise à jour**: 2026
