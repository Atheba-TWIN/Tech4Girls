# Projet Flutter - Suivi Drépanocytaire - Résumé Complet

## 📋 Contenu du Projet

Ce projet Flutter complet contient une application de suivi des patients atteints de drépanocytose avec intégration Bluetooth, notifications, localisation GPS et base de données locale.

## 🏗️ Architecture du Projet

```
lib/
├── main.dart                           # Point d'entrée principal
│   ├── MyApp (MaterialApp)
│   └── MainNavigation (Bottom Navigation)
│
├── models/                            # Modèles de données
│   ├── sensor_data.dart              # Données du bracelet
│   ├── sensor_data.g.dart            # Adapter Hive généré
│   ├── alert_settings.dart           # Paramètres d'alerte
│   ├── alert_settings.g.dart         # Adapter Hive généré
│   └── location_data.dart            # Données GPS
│
├── services/                         # Services métier (Business Logic)
│   ├── bluetooth_service.dart        # BLE scan, connect, data parsing
│   ├── notification_service.dart     # Notifications locales
│   ├── location_service.dart         # GPS et suivi de position
│   └── database_service.dart         # Stockage Hive
│
├── providers/                        # State Management (Provider)
│   ├── bluetooth_provider.dart       # État Bluetooth
│   ├── sensor_data_provider.dart     # État capteurs + logique alertes
│   └── location_provider.dart        # État localisation
│
└── screens/                          # Interfaces Utilisateur
    ├── home_screen.dart              # Écran principal
    ├── bluetooth_scan_screen.dart    # Scan et appairage
    ├── history_screen.dart           # Historique + graphiques
    └── settings_screen.dart          # Paramètres et configuration

Documentation/
├── SETUP_GUIDE.md                    # Guide d'installation complet
├── CONFIGURATION.md                  # Configuration détaillée
├── BRACELET_FIRMWARE_GUIDE.md       # Guide du bracelet/firmware
├── USAGE_EXAMPLES.md                 # Exemples d'utilisation
└── README.md                          # Projet Vue d'ensemble
```

## 🛠️ Technologies Utilisées

### Framework & Core

- **Flutter**: ^3.7.0 - Framework UI
- **Dart**: ^3.0.0 - Langage de programmation

### Connectivity & Hardware

- **flutter_blue_plus** (^1.31.8) - Bluetooth Low Energy
- **geolocator** (^9.0.2) - GPS et localisation

### UI & UX

- **Material Design 3** - Design system
- **fl_chart** (^0.65.0) - Graphiques
- **google_maps_flutter** (^2.5.0) - Affichage carte

### State Management & Data

- **provider** (^6.1.0) - Gestion d'état
- **hive** (^2.2.3) - Base de données locale
- **hive_flutter** (^1.1.0) - Intégration Flutter
- **intl** (^0.19.0) - Internationalization

### Notifications

- **flutter_local_notifications** (^16.1.0) - Notifications locales

## 🔄 Flux de Données

```
┌─────────────────────────────────────────────────────────────┐
│                    Bracelet Bluetooth                        │
│         (Température + Signal d'Urgence)                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │  BluetoothService      │
        │  - Scan               │
        │  - Connect            │
        │  - Parse Data         │
        └────────┬───────────────┘
                 │
         ┌───────▼──────────┐
         │   parseSensorData │
         │  [temp, urgency]  │
         └───────┬──────────┘
                 │
         ┌───────▼──────────────────┐
         │  SensorDataProvider      │
         │  - Stocke données        │
         │  - Vérifie alertes       │
         │  - Notifie UI            │
         └───────┬──────────────────┘
                 │
        ┌────────┼────────┬──────────┐
        │        │        │          │
        ▼        ▼        ▼          ▼
    Database  Notifs   Provider   Location
    (Hive)    Check     UI Update   GPS
```

## 🔐 Sécurité et Permissions

### Android Permissions

✅ **Déjà configurées dans AndroidManifest.xml**:

- Bluetooth: `BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`
- Location: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
- Notifications: `POST_NOTIFICATIONS`
- Internet: `INTERNET`

### iOS Permissions

⚠️ **À configurer dans Info.plist**:

- NSLocationWhenInUseUsageDescription
- NSBluetoothAlwaysUsageDescription
- NSBluetoothPeripheralUsageDescription

## 💾 Base de Données

### Structure Hive

**Box 1: sensor_data** (Type: 0)

```
SensorData:
  - temperature: double
  - emergencySignal: bool
  - timestamp: DateTime
  - latitude: double?
  - longitude: double?
```

**Box 2: alert_settings** (Type: 1)

```
AlertSettings:
  - temperatureThreshold: double (défaut: 38.0)
  - enableTemperatureAlert: bool
  - enableEmergencyAlert: bool
  - enableNotifications: bool
```

## 📱 Écrans de l'Application

### 1. Accueil (Home Screen)

- 🔷 État de connexion Bluetooth
- 🌡️ Température actuelle en temps réel
- 🚨 État du signal d'urgence
- 📍 Localisation GPS
- 🗺️ Carte Google Maps
- 🔵 FAB Bluetooth (Connect/Disconnect)

### 2. Historique (History Screen)

- 📊 Graphique de température (Jour/Semaine/Mois)
- 📈 Statistiques (Min/Max/Moyenne)
- 🟥 Compteur d'urgences
- 📋 Tableau détaillé des mesures
- 🎨 Code couleur pour les alertes

### 3. Paramètres (Settings Screen)

- 🌡️ Configuration seuil température
- ⚙️ Activer/Désactiver alertes
- 🔔 Activer/Désactiver notifications
- ℹ️ Informations application

### 4. Bluetooth Scan (Scan Screen)

- 🔍 Liste des périphériques trouvés
- 📱 Affichage nom et adresse MAC
- 🔗 Bouton connexion par appareil
- ⏳ Indicateur de recherche

## 📊 Données Bracelet

Format attendu: **2 Bytes**

```
Byte 0: Température = °C × 2
├─ 60  → 30°C (min)
├─ 76  → 38°C (normal)
├─ 80  → 40°C (alerte)
└─ 84  → 42°C (max)

Byte 1: Urgence
├─ 0 → Pas d'urgence
└─ 1 → Urgence activée
```

Voir `BRACELET_FIRMWARE_GUIDE.md` pour implémentation complète.

## ⚡ Alertes et Notifications

### Types de Notifications

| Alerte      | Condition   | Channel           | Vibration |
| ----------- | ----------- | ----------------- | --------- |
| Température | Temp ≥ 38°C | temperature_alert | Oui       |
| Urgence     | Signal = 1  | emergency_alert   | Oui       |
| Info        | Événements  | info_channel      | Non       |

## 🚀 Démarrage Rapide

### 1. Installation des Dépendances

```bash
cd tech4girls
flutter pub get
```

### 2. Configuration Google Maps

- Générer clé API Google Maps
- Ajouter dans `android/app/src/main/AndroidManifest.xml`

### 3. Générer les Adapters Hive

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Lancer l'App

```bash
flutter run              # Mode debug
flutter run --release   # Mode release
```

## 🧪 Tests Recommandés

```
1. Connectivité Bluetooth
   ✓ Scan des périphériques
   ✓ Connexion au bracelet
   ✓ Réception des données

2. Alertes
   ✓ Alerte température (≥38°C)
   ✓ Alerte urgence
   ✓ Notifications affichées

3. Localisation
   ✓ Permission requise
   ✓ Système GPS actif
   ✓ Carte Google affiche

4. Base de Données
   ✓ Données sauvegardées
   ✓ Historique accessible
   ✓ Statistiques correctes

5. Performance
   ✓ Pas lag UI
   ✓ Consommation batterie acceptable
   ✓ Mode hors-ligne fonctionne
```

## 📚 Documentation

| Document                   | Contenu                      |
| -------------------------- | ---------------------------- |
| SETUP_GUIDE.md             | Installation et architecture |
| CONFIGURATION.md           | Paramétrage détaillé         |
| BRACELET_FIRMWARE_GUIDE.md | Développement du bracelet    |
| USAGE_EXAMPLES.md          | Exemples de code             |
| README.md                  | Vue d'ensemble projet        |

## 🎯 Fonctionnalités Clés

### ✅ Implémentées Actuellement

- [x] Scan et connexion Bluetooth
- [x] Réception données bracelet en temps réel
- [x] Affichage température actualisé
- [x] Détection signal d'urgence
- [x] Notifications locales
- [x] Alertes configurables
- [x] Localisation GPS avec carte
- [x] Historique complet des données
- [x] Graphiques de température
- [x] Statistiques (min/max/moyenne)
- [x] Base de données locale (Hive)
- [x] État centralisé (Provider)
- [x] Interface multi-écrans

### 📋 Améliorations Futures

- [ ] Authentification utilisateur
- [ ] Synchronisation cloud
- [ ] Push notifications
- [ ] Export PDF/Excel
- [ ] Mode hors-ligne amélioré
- [ ] Alertes intelligentes
- [ ] Machine Learning prédictions
- [ ] Intégration wearables supplémentaires

## 🐛 Dépannage

### Bluetooth non fonctionne

```
R: Vérifier Bluetooth activé, permissions requises
```

### Carte ne s'affiche pas

```
R: Configurer clé API Google Maps
```

### Notifications ne fonctionnent pas

```
R: Vérifier permissions, initialiser NotificationService
```

### Base de données vidée

```
R: Utiliser clearAllSensorData() avec prudence
```

## 📞 Support Développement

Pour des questions spécifiques:

1. Consulter les guides (SETUP_GUIDE.md, etc.)
2. Vérifier les exemples (USAGE_EXAMPLES.md)
3. Voir commentaires dans le code
4. Consulter documentations officielles plugins

## 📄 Licence et Crédits

**Projet**: Tech4Girls - Suivi Drépanocytaire
**Version**: 1.0.0
**Date**: 2026
**Plateforme**: Android, iOS, Web (support partiel)

---

## Arborescence Fichiers Complète

```
tech4girls/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── alert_settings.dart
│   │   ├── alert_settings.g.dart
│   │   ├── location_data.dart
│   │   ├── sensor_data.dart
│   │   └── sensor_data.g.dart
│   ├── providers/
│   │   ├── bluetooth_provider.dart
│   │   ├── location_provider.dart
│   │   └── sensor_data_provider.dart
│   ├── screens/
│   │   ├── bluetooth_scan_screen.dart
│   │   ├── history_screen.dart
│   │   ├── home_screen.dart
│   │   └── settings_screen.dart
│   └── services/
│       ├── bluetooth_service.dart
│       ├── database_service.dart
│       ├── location_service.dart
│       └── notification_service.dart
├── android/
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/main/
│   │       ├── AndroidManifest.xml (✏️ UPDATED)
│   │       └── kotlin/com/example/tech4girls/
│   └── gradle/
├── ios/
│   ├── Runner/
│   │   ├── Info.plist (⚙️ À configurer)
│   │   └── Runner.xcodeproj/
│   └── RunnerTests/
├── web/
├── pubspec.yaml (✏️ UPDATED)
├── analysis_options.yaml
├── SETUP_GUIDE.md (📝 NEW)
├── CONFIGURATION.md (📝 NEW)
├── BRACELET_FIRMWARE_GUIDE.md (📝 NEW)
├── USAGE_EXAMPLES.md (📝 NEW)
└── README.md
```

**Fichiers Modifiés (✏️)**: pubspec.yaml, AndroidManifest.xml, main.dart
**Fichiers Créés (📝)**: Tous les autres dans lib/

---

**🎉 Le projet est complètement opérationnel!**

Pour commencer:

1. `flutter pub get`
2. Configurer Google Maps
3. `flutter pub run build_runner build`
4. `flutter run`
