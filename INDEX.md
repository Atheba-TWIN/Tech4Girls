# 📖 Table des Matières - Application Suivi Drépanocytaire

## 🚀 Démarrage Rapide

### Pour les Nouveaux Développeurs

1. **[INITIALIZATION_CHECKLIST.md](INITIALIZATION_CHECKLIST.md)** - ⭐ COMMENCER ICI
   - ✅ Checklist complète à suivre
   - 🔧 Configuration étape par étape
   - 🧪 Tests pré-lancement

2. **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Guide Installation
   - 📋 Architecture du projet
   - 🛠️ Installation des dépendances
   - 📱 Configuration Android/iOS

3. **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Vue d'Ensemble
   - 🏗️ Structure complète
   - 🔄 Flux de données
   - 📚 Technologies utilisées

## 📚 Documentation Détaillée

### Configuration

- **[CONFIGURATION.md](CONFIGURATION.md)**
  - Google Maps API
  - Permissions Android/iOS
  - Notifications
  - Hive Database
  - Variables d'environnement
  - Checklist pré-lancement

### Développement du Bracelet

- **[BRACELET_FIRMWARE_GUIDE.md](BRACELET_FIRMWARE_GUIDE.md)**
  - Format de données Bluetooth
  - Implémentation Arduino
  - Implémentation MicroPython
  - Debugging avec nRF Connect
  - Capteurs recommandés

### Utilisation et Exemples

- **[USAGE_EXAMPLES.md](USAGE_EXAMPLES.md)**
  - Exemples BluetoothService
  - Exemples NotificationService
  - Exemples LocationService
  - Exemples DatabaseService
  - Patterns d'utilisation avancés
  - Tests unitaires

## 🗂️ Structure du Code

### Services (lib/services/)

#### BluetoothService

```dart
lib/services/bluetooth_service.dart
```

- Scan périphériques BLE
- Connexion/déconnexion
- Parsing données capteurs
- Gestion des streams

**Utilisation**:

```dart
final bt = BluetoothService();
await bt.startScan();
bt.devicesStream.listen((devices) {...});
await bt.connect(device);
```

#### NotificationService

```dart
lib/services/notification_service.dart
```

- Notifications locales
- Alertes température
- Alertes urgence
- Canaux Android

**Utilisation**:

```dart
final notifs = NotificationService();
await notifs.initialize();
await notifs.showTemperatureAlert(38.5);
await notifs.showEmergencyAlert();
```

#### LocationService

```dart
lib/services/location_service.dart
```

- Localisation GPS
- Suivi en temps réel
- Calcul distances
- Gestion permissions

**Utilisation**:

```dart
final location = LocationService();
await location.initialize();
final pos = await location.getCurrentLocation();
location.locationStream.listen((loc) {...});
```

#### DatabaseService

```dart
lib/services/database_service.dart
```

- Stockage Hive
- CRUD données
- Statistiques
- Nettoyage données

**Utilisation**:

```dart
final db = DatabaseService();
await db.initialize();
await db.saveSensorData(data);
final stats = db.getTemperatureStats(data);
```

### Providers (lib/providers/)

#### BluetoothProvider

```dart
lib/providers/bluetooth_provider.dart
```

- État connexion
- Liste appareils
- Erreurs

**Utilisation avec Consumer**:

```dart
Consumer<BluetoothProvider>(
  builder: (context, btProvider, _) {
    // Accès à btProvider.devices, isScanning, connectedDevice
  }
)
```

#### SensorDataProvider

```dart
lib/providers/sensor_data_provider.dart
```

- Données actuelles
- Historique
- Alertes
- Paramètres

**Utilisation**:

```dart
Consumer<SensorDataProvider>(
  builder: (context, sensorProvider, _) {
    final temp = sensorProvider.currentData?.temperature;
    final stats = sensorProvider.getTemperatureStatsToday();
  }
)
```

#### LocationProvider

```dart
lib/providers/location_provider.dart
```

- Position actuelle
- Erreurs localisation
- État chargement

**Utilisation**:

```dart
Consumer<LocationProvider>(
  builder: (context, locationProvider, _) {
    final pos = locationProvider.currentLocation;
  }
)
```

### Modèles (lib/models/)

#### SensorData

```dart
lib/models/sensor_data.dart
```

- Température
- Signal urgence
- Timestamp
- Latitude/Longitude

#### AlertSettings

```dart
lib/models/alert_settings.dart
```

- Seuil température
- Activations alertes
- État notifications

#### LocationData

```dart
lib/models/location_data.dart
```

- Latitude/Longitude
- Précision
- Timestamp

### Écrans (lib/screens/)

#### HomeScreen

```dart
lib/screens/home_screen.dart
```

**Affiche**:

- État Bluetooth
- Température actuelle
- Signal urgence
- Localisation GPS
- Carte Google Maps

**Actions**:

- Connect/Disconnect Bluetooth
- Naviguer vers autres écrans

#### HistoryScreen

```dart
lib/screens/history_screen.dart
```

**Affiche**:

- Graphique température
- Statistiques
- Sélecteur période
- Tableau données

#### SettingsScreen

```dart
lib/screens/settings_screen.dart
```

**Permet**:

- Configurer seuil alerte
- Activer/désactiver alertes
- Activer/désactiver notifications

#### BluetoothScanScreen

```dart
lib/screens/bluetooth_scan_screen.dart
```

**Affiche**:

- Appareils détectés
- Boutons connexion
- État recherche

## 🔄 Flux de Données

```
Bracelet → BluetoothService → SensorDataProvider
         → DatabaseService
         → NotificationService
         → UI Screens

GPS → LocationService → LocationProvider → Google Maps

User Input → Settings → AlertSettings → Database
```

## 📱 Screens Navigation

```
MainNavigation (BottomNavigationBar)
├── HomeScreen (Index 0)
│   ├── → BluetoothScanScreen (FAB)
│   └── → Google Maps
├── HistoryScreen (Index 1)
│   └── → Graphiques
└── SettingsScreen (Index 2)
    └── → Configuration
```

## 🎯 Cas d'Utilisation Courants

### 1. Ajouter une Nouvelle Métrique

1. Modifier modèle dans `lib/models/`
2. Mettre à jour BoxAdapter Hive
3. Modifier parsing dans `BluetoothService`
4. Ajouter Provider logic
5. Afficher dans les screens

### 2. Ajouter une Nouvelle Alerte

1. Ajouter logique `_checkAlerts()` dans `SensorDataProvider`
2. Créer method dans `NotificationService`
3. Appeler depuis le provider
4. Tester avec le bracelet

### 3. Ajouter un New Screen

1. Créer fichier dans `lib/screens/`
2. Ajouter route dans `main.dart`
3. Ajouter navigation
4. Utiliser Consumers pour Provider

### 4. Modifier l'Interface

1. Editer les fichiers `lib/screens/*.dart`
2. Utiliser Material Design 3
3. Respecter le thème (deepPurple)

## 🧪 Testing

### Unit Tests

```bash
flutter test test/
```

### Widget Tests

```bash
flutter test --verbose
```

### Integration Tests

```bash
flutter test integration_test/
```

## 🚀 Build et Déploiement

### Android

```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Web (Support Partiel)

```bash
flutter build web --release
```

## 📊 Métriques Performance

### Target

- **Compilation**: < 30s
- **Launch Time**: < 2s
- **Memory**: < 100MB
- **Battery**: < 5% par heure (en utilisation normale)

## 🐛 Dépannage Rapide

| Problème          | Cause                 | Solution                             |
| ----------------- | --------------------- | ------------------------------------ |
| Bluetooth failure | Service non init      | Vérifier `main.dart`                 |
| Carte vide        | API Key manquante     | Voir CONFIGURATION.md                |
| DB error          | Build files manquants | `flutter pub run build_runner build` |
| Notification fail | Permissions           | Vérifier AndroidManifest.xml         |
| GPS error         | Services désactivés   | Activer localisation + permissions   |

## 📞 Support et Ressources

### Documentation Officielle

- [Flutter.dev](https://flutter.dev)
- [Dart.dev](https://dart.dev)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus)
- [Hive Database](https://pub.dev/packages/hive)

### Communauté

- Stack Overflow: Tag `flutter`
- Flutter Reddit: r/Flutter
- GitHub Issues: Chaque package

## 📈 Roadmap Futures Suggestions

- [ ] Authentication utilisateur
- [ ] Cloud sync (Firebase/Supabase)
- [ ] Push notifications
- [ ] Export PDF/CSV
- [ ] Machine Learning
- [ ] Support Wearables supplémentaires
- [ ] Mode hors-ligne avancé
- [ ] Dark Mode
- [ ] i18n complet

## 📋 Fichiers Importants

| Fichier                                    | Rôle                |
| ------------------------------------------ | ------------------- |
| `lib/main.dart`                            | Point d'entrée      |
| `pubspec.yaml`                             | Dépendances         |
| `android/app/src/main/AndroidManifest.xml` | Permissions Android |
| `ios/Runner/Info.plist`                    | Config iOS          |
| `lib/services/`                            | Logique métier      |
| `lib/providers/`                           | Gestion état        |
| `lib/screens/`                             | Interface UI        |

## 🎓 Apprentissage Recommandé

1. **Flutter Basics** → Flutter.dev
2. **Provider Pattern** → pub.dev/packages/provider
3. **Hive Database** → pub.dev/packages/hive
4. **Bluetooth BLE** → flutter_blue_plus docs
5. **Google Maps** → google_maps_flutter docs

## ✨ Résumé Rapide

```
Projet:          Suivi Drépanocytaire
Framework:       Flutter + Dart
Architecture:    Service + Provider
Database:        Hive (local)
Connectivity:    Bluetooth + GPS
UI:              Material Design 3
Status:          ✅ Production Ready
Version:         1.0.0
```

---

**Pour Commencer**: 1️⃣ Ouvrir [INITIALIZATION_CHECKLIST.md](INITIALIZATION_CHECKLIST.md)

**Dernière Mise à Jour**: 2026
**Mainteneur**: Tech4Girls Team
