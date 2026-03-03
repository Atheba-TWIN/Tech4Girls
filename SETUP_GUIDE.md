# Application de Suivi Drépanocytaire

Une application Flutter complète pour le suivi des patients atteints de drépanocytose, avec connexion Bluetooth à un bracelet capteur, suivi en temps réel de la température corporelle, gestion des alertes, localisation GPS et historique des données.

## Caractéristiques

### 1. Connectivity Bluetooth

- **Service**: `BluetoothService` (lib/services/bluetooth_service.dart)
- Scan et connexion aux périphériques Bluetooth
- Réception en temps réel des données du bracelet (température, signal d'urgence)
- Utilise le plugin `flutter_blue_plus`

### 2. Suivi de la Température

- Réception en temps réel de la température corporelle
- Affichage de la température actuelle avec code couleur
- Alertes automatiques si la température dépasse 38°C (configurable)
- Historique complet des mesures

### 3. Signal d'Urgence

- Détection du signal d'urgence du bracelet
- Notification immédiate si le signal est activé
- Affichage de l'état d'urgence sur l'écran principal

### 4. Localisation GPS

- **Service**: `LocationService` (lib/services/location_service.dart)
- Obtention de la position GPS actuelle
- Suivi en temps réel de la localisation
- Affichage sur une carte avec `google_maps_flutter`
- Précision et coordonnées affichées

### 5. Notifications Locales

- **Service**: `NotificationService` (lib/services/notification_service.dart)
- Notifications pour les alertes de température
- Notifications pour les signaux d'urgence
- Notifications d'information
- Utilise `flutter_local_notifications`

### 6. Stockage Local des Données

- **Service**: `DatabaseService` (lib/services/database_service.dart)
- Stockage avec `Hive` (base de données locale)
- Sauvegarde automatique de chaque mesure
- Historique interrogeable
- Statistiques (min, max, moyenne)

### 7. Interface Utilisateur

#### Écran Accueil (HomeScreen)

- État de la connexion Bluetooth
- Affichage actualisé de la température
- État du signal d'urgence
- Localisation GPS actuelle
- Carte Google Maps
- Bouton Floating Action (Bluetooth connect/disconnect)
- Navigation vers les autres écrans

#### Écran Historique (HistoryScreen)

- Graphique de l'évolution de la température
- Sélection de période (aujourd'hui, semaine, mois)
- Statistiques (min, max, moyenne)
- Tableau détaillé des mesures
- Mise en avant des alertes

#### Écran Paramètres (SettingsScreen)

- Configuration du seuil de température d'alerte
- Activation/désactivation des alertes
- Activation/désactivation des notifications
- Informations de l'application

#### Écran de Scan Bluetooth (BluetoothScanScreen)

- Liste des périphériques Bluetooth détectés
- Nom et adresse du périphérique
- Bouton pour se connecter à un périphérique

## Architecture

### Structure des Dossiers

```
lib/
├── main.dart                    # Point d'entrée principal
├── models/                      # Modèles de données
│   ├── sensor_data.dart        # Données des capteurs
│   ├── sensor_data.g.dart      # Adapter Hive généré
│   ├── alert_settings.dart     # Paramètres d'alerte
│   ├── alert_settings.g.dart   # Adapter Hive généré
│   └── location_data.dart      # Données GPS
├── services/                    # Services métier
│   ├── bluetooth_service.dart   # Gestion Bluetooth
│   ├── notification_service.dart # Gestion notifications
│   ├── location_service.dart    # Gestion localisation
│   └── database_service.dart    # Gestion base de données
├── providers/                   # État et logique (Provider)
│   ├── bluetooth_provider.dart
│   ├── sensor_data_provider.dart
│   └── location_provider.dart
└── screens/                     # Écrans UI
    ├── home_screen.dart
    ├── bluetooth_scan_screen.dart
    ├── history_screen.dart
    └── settings_screen.dart
```

### Pattern d'État

L'application utilise **Provider** pour la gestion de l'état:

- **BluetoothProvider**: Gère l'état de connexion Bluetooth et l'appairage
- **SensorDataProvider**: Gère les données des capteurs et les alertes
- **LocationProvider**: Gère la position GPS actuelle

## Installation et Configuration

### 1. Dépendances Flutter

```bash
flutter pub get
```

### 2. Configuration Android

Les permissions suivantes sont déjà configurées dans `AndroidManifest.xml`:

```xml
<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>

<!-- Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

<!-- Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Internet -->
<uses-permission android:name="android.permission.INTERNET"/>
```

### 3. Configuration Google Maps (Android)

Ajouter votre clé API Google Maps dans `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE"/>
</application>
```

### 3. Configuration Google Maps (iOS)

Ajouter votre clé API dans `ios/Runner/GeneratedPluginRegistrant.m`:

```
[google_maps_flutter_ios GooglemapsflutterIosPlugin registerWithRegistrar:registry];
```

### 4. Configuration iOS

Si vous supportez iOS, assurez-vous que les permissions sont configurées dans `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Utilisé pour afficher votre position sur la carte</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Utilisé pour un suivi continu de position</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Utilisé pour se connecter au bracelet capteur</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Utilisé pour se connecter au bracelet capteur</string>
```

## Flux de Données

```
Bracelet Bluetooth
       ↓
BluetoothService (scan/connect)
       ↓
Parse Sensor Data (temp, emergency)
       ↓
SensorDataProvider
       ↓
├─ Sauvegarde (DatabaseService/Hive)
├─ Alerte (NotificationService)
└─ Mise à jour UI
```

## Format des Données Bluetooth

Le bracelet doit envoyer des données au format:

- **Byte 0**: Température (valeur \* 2) - Ex: 76 = 38°C, 78 = 39°C
- **Byte 1**: Signal d'urgence (1 = actif, 0 = inactif)

Exemple: `[76, 0]` = 38°C, pas d'urgence

## Utilisation

### Démarrer l'application

```bash
flutter run
```

### Build APK

```bash
flutter build apk --release
```

### Build AAB (Google Play)

```bash
flutter build appbundle --release
```

## Dépendances Clés

- **flutter_blue_plus** (^1.31.8): Gestion Bluetooth
- **flutter_local_notifications** (^16.1.0): Notifications locales
- **geolocator** (^9.0.2): Localisation GPS
- **google_maps_flutter** (^2.5.0): Affichage carte
- **hive** (^2.2.3): Base de données locale
- **hive_flutter** (^1.1.0): Intégration Hive Flutter
- **provider** (^6.1.0): Gestion d'état
- **fl_chart** (^0.65.0): Graphiques
- **intl** (^0.19.0): Formatage internationalisé

## Adapters Hive Générés

Pour régénérer les adapters Hive après modification des modèles:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Points d'Amélioration Futurs

1. **Authentification**: Ajouter connexion utilisateur
2. **Cloud Sync**: Synchronisation avec un serveur cloud
3. **Alertes Avancées**: Patterns de température, historique d'urgence
4. **Push Notifications**: Notifications serveur pour les proches
5. **Graphiques Avancés**: Plus de types de graphiques, export PDF
6. **Paramètres Médicaux**: Intégration données médicales patient
7. **Mode Hors Ligne**: Support amélioré sans connexion
8. **i18n**: Support multi-langue complet

## Dépannage

### Bluetooth non détecté

- Vérifier que Bluetooth est activé sur l'appareil
- Vérifier les permissions Bluetooth
- S'assurer que le bracelet est en mode de recherche

### Localisation ne fonctionne pas

- Vérifier que les services de localisation sont activés
- Vérifier les permissions d'accès à la localisation
- S'assurer que Google Play Services est à jour

### Google Maps ne s'affiche pas

- Vérifier la clé API Google Maps
- Vérifier les permissions Internet

## Support et Contribution

Pour des questions ou contributions, veuillez contacter l'équipe Tech4Girls.

---

**Version**: 1.0.0  
**Date**: 2026  
**Plateforme**: Android, iOS, Web
