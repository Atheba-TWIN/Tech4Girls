# Configuration et Intégrations

## 1. Configuration Google Maps

### Obtenir une clé API

1. Aller sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créer un nouveau projet
3. Activer les APIs:
   - Google Maps Android API
   - Google Maps iOS SDK
4. Créer une clé API
5. Restreindre la clé aux apps Android/iOS

### Configuration Android

Ajouter la clé API dans `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <!-- Autre configuration -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE" />
</application>
```

Ou dans `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        manifestPlaceholders = [
            googleMapsApiKey: "YOUR_API_KEY_HERE"
        ]
    }
}
```

### Configuration iOS

Ajouter la clé API dans `ios/Runner/GeneratedPluginRegistrant.m`:

**Avant Flutter 3.0**:

```objc
[GoogleMapsPlugin registerWithRegistrar:[registry.registrar registrarForPlugin:@"GoogleMapsPlugin"]];
```

**À partir de Flutter 3.0**:

1. Ouvrir `ios/Runner.xcworkspace` dans Xcode
2. Ajouter dans `Info.plist`:

```xml
<key>com.google.ios.maps.API_KEY</key>
<string>YOUR_API_KEY_HERE</string>
```

## 2. Configuration des Permissions

### Android Permissions

Vérifier que `android/app/src/main/AndroidManifest.xml` contient:

```xml
<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Internet -->
<uses-permission android:name="android.permission.INTERNET" />
```

### Permissions Android 12+ (Niveau API 31+)

Pour Android 12+, vous devez demander les permissions au runtime. Le code est déjà intégré dans:

- `BluetoothProvider.startScan()`: Demande BLUETOOTH_SCAN
- `LocationProvider.initialize()`: Demande ACCESS_FINE_LOCATION
- `NotificationService.initialize()`: Demande POST_NOTIFICATIONS

### iOS Permissions

Ajouter dans `ios/Runner/Info.plist`:

```xml
<!-- Localisation -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Utilisé pour afficher votre position sur la carte et suivre vos déplacements</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Utilisé pour un suivi continu de votre position</string>

<!-- Bluetooth -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Utilisé pour se connecter à votre bracelet capteur</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>Utilisé pour se connecter à votre bracelet capteur pour recevoir les données de santé</string>

<!-- Background Modes (optionnel, pour suivi en arrière-plan) -->
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>location</string>
</array>
```

## 3. Configuration des Notifications

### Android - Notification Channels

Les canaux de notification sont automatiquement créés par `NotificationService`:

- **temperature_alert_channel**: Alertes de température
- **emergency_alert_channel**: Alertes d'urgence
- **info_channel**: Notifications d'information

### iOS - Notifications

Les notifications sont activées automatiquement via `flutter_local_notifications`.

S'assurer que les notifications sont activées dans les paramètres système iOS.

## 4. Configuration Hive Database

### Initialisation

La base de données est automatiquement initialisée dans `main.dart`:

```dart
final databaseService = DatabaseService();
await databaseService.initialize();
```

### Régénération des Adapters

Si vous modifiez les modèles `SensorData` ou `AlertSettings`, régénérez les adapters:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Emplacements des Fichiers

**Android**: `data/data/com.yourcompany.tech4girls/hive/`

**iOS**: `<App Documents>/hive/`

## 5. Configuration du Bracelet

### Appairage Bluetooth

1. Ouvrir l'écran "Rechercher un Bracelet"
2. Activer Bluetooth sur l'appareil
3. Activer le mode d'appairage sur le bracelet (généralement 10 secondes au démarrage)
4. Sélectionner le bracelet dans la liste
5. Confirmer la connexion

### Format de Données Attendu

Le bracelet doit envoyer des frames de 2 bytes:

```
Byte 0: Température = (°C * 2)
Byte 1: Signal d'urgence (0=non, 1=oui)
```

Voir `BRACELET_FIRMWARE_GUIDE.md` pour plus de détails.

## 6. Configuration de l'Application

### Fichier pubspec.yaml

Vérifier que tous les plugins sont déclarés:

```yaml
dependencies:
  flutter_blue_plus: ^1.31.8
  flutter_local_notifications: ^16.1.0
  geolocator: ^9.0.2
  google_maps_flutter: ^2.5.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  provider: ^6.1.0
  fl_chart: ^0.65.0
  intl: ^0.19.0
```

### Fichier analysis_options.yaml

Configuration optionnelle pour l'analyse du code:

```yaml
linter:
  rules:
    - camel_case_types
    - constant_identifier_names
    - empty_statements
    - avoid_empty_else
    - avoid_print
    - avoid_relative_import_paths
    - avoid_returning_null_for_future
    - avoid_slow_async_io
    - cancel_subscriptions
    - close_sinks
    - comment_references
    - control_flow_in_finally
    - empty_catches
    - hash_and_equals
    - invariant_booleans
    - iterable_contains_unrelated_type
    - list_remove_unrelated_type
    - literal_only_boolean_expressions
    - no_adjacent_strings_in_list
    - no_duplicate_case_values
    - prefer_void_to_null
    - throw_in_finally
    - unnecessary_statements
    - unrelated_type_equality_checks
```

## 7. Tests Recommandés

### Test de Connectivité Bluetooth

```dart
// Dans un test ou debug screen
void testBluetoothConnection() async {
  final btProvider = BluetoothProvider();
  await btProvider.startScan();

  await Future.delayed(Duration(seconds: 10));

  if (btProvider.devices.isNotEmpty) {
    await btProvider.connectToDevice(btProvider.devices.first.device);
    print("✓ Bluetooth connection successful");
  }
}
```

### Test de Localisation

```dart
void testLocation() async {
  final locationProvider = LocationProvider();
  await locationProvider.initialize();

  final location = await locationProvider.getLocation();
  print("✓ Location: ${location?.latitude}, ${location?.longitude}");
}
```

### Test des Notifications

```dart
void testNotifications() async {
  final notificationService = NotificationService();
  await notificationService.initialize();

  await notificationService.showTemperatureAlert(39.5);
  print("✓ Temperature notification sent");

  await notificationService.showEmergencyAlert();
  print("✓ Emergency notification sent");
}
```

## 8. Variables d'Environnement

### Fichier .env (optionnel)

Vous pouvez créer un fichier `.env` à la racine du projet pour les configurations sensibles:

```
GOOGLE_MAPS_API_KEY=YOUR_API_KEY
TEMPERATURE_ALERT_THRESHOLD=38.0
NOTIFICATION_ENABLED=true
LOG_LEVEL=info
```

Puis charger dans `main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Reste du code
}
```

Ajouter à `pubspec.yaml`:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0

flutter:
  assets:
    - .env
```

## 9. Déploiement

### Build Google Play

```bash
# Générer clé:
keytool -genkey -v -keystore ~/android_key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build AAB:
flutter build appbundle --release
```

### Build App Store (iOS)

```bash
flutter build ios --release
```

Puis utiliser Xcode ou xcrun pour upload sur App Store Connect.

## Checklist Pré-Lancement

- [ ] Clé API Google Maps configurée
- [ ] Permissions Android/iOS vérifiées
- [ ] Bracelet testé et fonctionnel
- [ ] Notifications testées
- [ ] Localisation testée
- [ ] Base de données Hive fonctionnelle
- [ ] Graphiques affichent correctement
- [ ] Tests d'alertes
- [ ] Performance testée sur appareil réel
- [ ] Batterie testée (autonomie)
- [ ] Conditions hors-ligne testées
- [ ] Permissions d'impression accordées

---

**Pour l'aide**: Consulter les documentations officielles de chaque plugin.
