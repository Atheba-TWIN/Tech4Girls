# 🔧 Guide de Dépannage - Troubleshooting

## 📋 Table des Matières

1. [Installation et Configuration](#installation-et-configuration)
2. [Bluetooth](#bluetooth)
3. [Notifications](#notifications)
4. [Localisation et Cartes](#localisation-et-cartes)
5. [Base de Données](#base-de-données)
6. [Performance](#performance)
7. [Problèmes de Build](#problèmes-de-build)

---

## Installation et Configuration

### ❌ "flutter doctor" échoue

**Symptôme**: `flutter doctor` montre des erreurs rouge ou orange

**Solutions**:

```bash
# Afficher les détails
flutter doctor -v

# Installer les composants manquants
flutter doctor --android-licenses

# Mettre à jour Flutter
flutter channel stable
flutter upgrade
```

### ❌ Les dépendances ne se téléchargent pas

**Symptôme**: Erreur lors de `flutter pub get`

**Solutions**:

```bash
# Effacer le cache
flutter pub cache clean

# Réessayer
flutter pub get

# Ou avec verbose
flutter pub get -v

# Vérifier connexion internet
ping pub.dev
```

### ❌ Version Dart incompatible

**Symptôme**: "The current Dart SDK version is..."

**Solutions**:

```bash
# Vérifier version
dart --version
flutter --version

# Utiliser version compatible
flutter channel stable  # Ou beta/master

# Purger et réinstaller
rm -rf .dart_tool pubspec.lock
flutter pub get
```

---

## Bluetooth

### ❌ "Bluetooth not supported on this device"

**Symptôme**: Erreur lors du scan

**Causes et Solutions**:

```
📱 Appareil n'a pas de Bluetooth
  → Utiliser un appareil plus récent

💻 Émulateur sans BLE
  → Utiliser appareil physique
  → Ou émulateur Google Play

🔌 Bluetooth USB (sur PC)
  → Installer le stick Bluetooth
```

### ❌ Bluetooth désactivé

**Symptôme**: "Bluetooth is not turned on"

**Solutions**:

```
Android:
1. Paramètres → Bluetooth → Activer
2. Ou demander permission à l'app

iOS:
1. Paramètres → Bluetooth → Activer
2. Ou Control Center
```

### ❌ App ne détecte pas le bracelet

**Symptôme**: Liste vide après 15s de scan

**Diagnostic**:

```bash
flutter logs | grep -i bluetooth
```

**Solutions**:

```
1. Vérifier le bracelet:
   ✓ Bracelet allumé
   ✓ Mode broadcast activé
   ✓ Batterie suffisante

2. Vérifier l'app:
   ✓ Bluetooth de l'appareil ON
   ✓ Permissions accordées
   ✓ Relancer l'app

3. Vérifier permissions:
   Paramètres → Tech4Girls → Localisation: ON

4. Tester avec d'autres appareils BLE:
   Utiliser nRF Connect (app gratuite)
```

### ❌ Déconnexion fréquente ou aléatoire

**Symptôme**: "Disconnected" toutes les 30s

**Causes**:

- Interférences radio (WiFi, micro-ondes)
- Distance Bluetooth trop grande
- Batterie bracelet faible
- Bug firmware bracelet

**Solutions**:

```
1. Réduire la distance (<10m)
2. Éloigner des sources d'interférence
3. Redémarrer bracelet et app
4. Vérifier firmware bracelet à jour
5. Augmenter puissance TX sur bracelet

// Code pour augmenter retry:
await device.connect(timeout: Duration(seconds: 30));

// Au lieu de:
await device.connect(timeout: Duration(seconds: 10));
```

### ❌ Données corrompues reçues

**Symptôme**: "Valeurs impossibles" (150°C, etc)

**Solutions**:

```dart
// Ajouter validation dans bluetoothService.parseSensorData()
Map<String, dynamic> parseSensorData(List<int> data) {
  if (data.length < 2) {
    return {'temperature': 0.0, 'emergencySignal': false};
  }

  final temp = data[0] / 2.0;

  // Validation
  if (temp < 30 || temp > 45) {
    print('⚠️ Temperature out of range: $temp');
    return {'temperature': 0.0, 'emergencySignal': false};
  }

  return {
    'temperature': temp,
    'emergencySignal': data[1] == 1,
  };
}
```

---

## Notifications

### ❌ Notifications ne s'affichent pas

**Symptôme**: Aucune alerte malgré température élevée

**Vérifier**:

```bash
# 1. Notifications activées dans paramètres
flutter logs | grep -i notif

# 2. Permissions accordées
adb shell pm list permissions-app com.example.tech4girls
```

**Android - Solutions**:

```
Paramètres → Applications → Tech4Girls
  ✓ Notifications: ON
  ✓ Permission Notifications accordée

Ou en code:
notificationService.initialize();  // Dans main()
```

**iOS - Solutions**:

```
Paramètres → Notifications → Tech4Girls
  ✓ Autoriser notifications: ON
  ✓ Sons et vibrations: ON

Dans Info.plist:
<key>UIUserInterfaceStyle</key>
<string>Light</string>
```

### ❌ Notifications sans son ni vibration

**Symptôme**: Notifications silencieuses

**Solutions Android**:

```dart
const AndroidNotificationDetails details = AndroidNotificationDetails(
  'temperature_alert_channel',
  'Temperature Alerts',
  importance: Importance.max,          // ← Ajouter
  priority: Priority.high,             // ← Ajouter
  sound: RawResourceAndroidNotificationSound('notification_sound'),
  enableVibration: true,               // ← Ajouter
);
```

Ajouter fichier son dans `android/app/src/main/res/raw/notification_sound.mp3`

### ❌ "Channel not found" erreur

**Symptôme**: Erreur notification sur Android 8+

**Cause**: Channels non créés
**Solution**:

```dart
// Dans NotificationService.initialize()
await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannels([
      AndroidNotificationChannel(
        id: 'temperature_alert_channel',
        name: 'Temperature Alerts',
        importance: Importance.max,
      ),
      // ... autres channels
    ]);
```

---

## Localisation et Cartes

### ❌ "Location services are disabled"

**Symptôme**: Erreur lors de `initialize()`

**Solutions**:

```
Android:
Paramètres → Localisation → Activer

iOS:
Paramètres → Confidentialité → Localisation
  → Tech4Girls: While Using
```

### ❌ Permission localisation refusée

**Symptôme**: "Location permissions are denied"

**Solutions**:

```
Android:
Paramètres → Applications → Tech4Girls
  → Permissions → Localisation: Autoriser

iOS:
Paramètres → Confidentialité → Localisation
  → Tech4Girls: During App Use

Code de fallback:
try {
  final location = await locationService.getCurrentLocation();
} catch (e) {
  if (e.toString().contains('denied')) {
    // Demander à nouveau
    await Geolocator.openLocationSettings();
  }
}
```

### ❌ Carte Google Maps vide

**Symptôme**: Écran gris sans carte

**Causes possibles**:

1. **Clé API manquante**:

```xml
<!-- Vérifier dans AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_KEY_HERE" />
```

2. **Clé API invalide**:

```bash
# Vérifier sur Google Cloud Console
# - API activée: Maps SDK for Android
# - Clé non expirée
# - IP/domain autorisé
```

3. **Permissions manquantes**:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

4. **No internet connection**:

```bash
# Vérifier
adb shell getprop net.change
```

**Solutions complètes**:

```gradle
// build.gradle
android {
    compileSdkVersion 33

    defaultConfig {
        targetSdkVersion 33
        minSdkVersion 21
    }
}
```

### ❌ Carte très lente ou gelée

**Symptôme**: Carte ne se charge pas vite

**Solutions**:

```dart
// Limiter updates de caméra
if (_lastUpdate == null ||
    DateTime.now().difference(_lastUpdate!).inSeconds > 2) {
  _mapController?.animateCamera(
    CameraUpdate.newCameraPosition(newPosition)
  );
  _lastUpdate = DateTime.now();
}

// Réduire nombre de markers
if (markers.length > 100) {
  markers = markers.take(100).toSet();
}
```

### ❌ Position affichée loin de réalité

**Symptôme**: GPS très imprécis

**Causes**:

- À l'intérieur (GPS faible)
- Mauvais signal satellite
- Délai avant synchronisation
- Bug du capteur

**Solutions**:

```dart
// Attendre position précise
final location = await locationService.getCurrentLocation();
if (location.accuracy > 100) {  // > 100m
  print('⚠️ Mauvaise précision');
  // Attendre nouvelle mesure
}

// Moyenne mobile
List<double> latitudes = [];
latitudes.add(location.latitude);
if (latitudes.length > 5) {
  latitudes.removeAt(0);
  final avgLat = latitudes.reduce((a, b) => a + b) / latitudes.length;
}
```

---

## Base de Données

### ❌ "The type 'SensorDataAdapter' must be defined"

**Symptôme**: Erreur Hive à la compilation

**Cause**: Adapter non généré
**Solution**:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### ❌ Données disparues après redémarrage

**Symptôme**: Historique vidé (tous les données perdues)

**Causes possibles**:

- `deleteAllSensorData()` appelé par erreur
- Base corrompue
- Permissions disque insuffisantes

**Solutions**:

```bash
# Vérifier les permissions
ls -la /data/data/com.example.tech4girls/

# Vérifier fichiers Hive
find ~/Library -name "*.hive" 2>/dev/null  # macOS
find ~/.../hive -type f 2>/dev/null       # Linux
```

**Recovery**:

```dart
// Si base vide, laisser l'app créer nouvelles données
// Aucune récupération possible (pas de cloud backup)

// À l'avenir, utiliser:
// - Firebase Firestore
// - Supabase
// - Cloud personnalisé
```

### ❌ Base de données très lente

**Symptôme**: Lag quand on ouvre historique

**Cause**: Trop données (>10k mesures)
**Solutions**:

```dart
// Nettoyer les vieilles données (> 90 jours)
await databaseService.deleteOldSensorData(90);

// Ou limiter affichage
final recentData = databaseService.getSensorDataLastNHours(24 * 7);
// Au lieu de: getAllSensorData()

// Indexing (Hive n'a pas d'index natif)
// Utiliser collection filtering:
final todayData = sensorDataBox.values
  .where((d) => d.timestamp.isAfter(today))
  .toList();
```

### ❌ AlertSettings non persistant

**Symptôme**: Paramètres réinitialisés

**Cause**: `AlertSettings` pas sauvegardé
**Solution**:

```dart
// Dans SettingsScreen, vérifier :
await sensorProvider.updateAlertSettings(newSettings);
// et pas juste:
// sensorProvider.alertSettings = newSettings;
```

---

## Performance

### ❌ App très lente au démarrage

**Symptôme**: > 5s pour lancer

**Optimizations**:

```dart
// Dans main(): Lazy-load les services
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seulement essentiels:
  final db = DatabaseService();
  await db.initialize();

  // Autres: Initier plus tard

  runApp(const MyApp());
}

// Dans screens: Lazy-load données
class HomeScreen extends StatefulWidget {
  @override
  void initState() {
    // Load data async
    _loadData(); // pas await ici
  }
}
```

### ❌ Consommation mémoire élevée

**Symptôme**: App crashe après > 1h

**Solutions**:

```dart
// Disposer les streams
@override
void dispose() {
  _locationSubscription.cancel();
  _dataSubscription.cancel();
  super.dispose();
}

// Limiter cache
if (sensorDataBox.length > 1000) {
  await deleteOldSensorData(30);
}

// Réduire fréquence updates
const Duration(milliseconds: 1000)  // Au lieu de 100ms
```

### ❌ Battery drain rapide (>5% par heure)

**Symptôme**: Batterie épuisée rapidement

**Causes**:

- GPS actif en continu
- Bluetooth très fréquent
- Screen toujours ON
- Notifications sans fin

**Solutions**:

```dart
// Augmenter intervalle GPS
LocationSettings(
  accuracy: LocationAccuracy.balanced,  // Au lieu de high
  distanceFilter: 100,                  // Minimum 100m
)

// Réduire fréquence télémetrie bracelet
// Attendre 10s au lieu de 5s

// Désactiver l'écran quand non utilisé
WakelockPlus.disable();  // Ajouter wakelock plugin

// Code intelligent:
if (!isConnected) {
  // Arrêter le suivi
  await locationService.stopTracking();
}
```

---

## Problèmes de Build

### ❌ "Failed to resolve flutter_blue_plus"

**Symptôme**: Erreur build Gradle

**Solutions**:

```gradle
// android/build.gradle
buildscript {
    repositories {
        google()
        mavenCentral()      // ← Ajouter
        maven {             // ← Ajouter
            url "https://jcenter.bintray.com"
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### ❌ Gradle sync échoue

**Symptôme**: "Unable to resolve dependency"

**Solutions**:

```bash
# Ignorer et essayer build
flutter clean
flutter pub get
flutter build apk
```

### ❌ "IOS build failed: Unable to boot Simulator"

**Symptôme**: Émulateur iOS pas dispo

**Solutions**:

```bash
# Lister simulateurs
xcrun simctl list

# Créer nouveau
xcrun simctl create "iPhone 14" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-14 \
  com.apple.CoreSimulator.SimRuntime.iOS-16-4

# Démarrer
flutter run -d "iPhone 14"
```

### ❌ "Android Gradle plugin requires Java 11"

**Symptôme**: Java version incompatible

**Solutions**:

```bash
# Vérifier Java
java -version

# Installer Java 11
# macOS: brew install openjdk@11
# Linux: sudo apt install openjdk-11-jdk
# Windows: Télécharger depuis oracle.com

# Configuration Flutter
flutter config --jdk-dir /path/to/java/11
```

---

## 📞 En Cas de Blocage

### Collecte des Informations

```bash
# 1. Logs détaillés
flutter logs -v > app.log

# 2. Infos système
flutter doctor -v > doctor.log

# 3. Erreur build
flutter build apk -v 2>&1 > build.log

# 4. Partager les logs pour aide
```

### Où Trouver Aide

1. **Stack Overflow** - Tag `flutter`
2. **GitHub Issues** - Des packages correspondants
3. **Discord Flutter** - Communauté active
4. **Flutter Docs** - https://flutter.dev/docs
5. **Package Docs** - pub.dev/packages/...

### Créer un Minimal Reproduction

```dart
// Si bug complexe, créer un example minimal:
void main() {
  // Seulement le code qui pose problème
  // Tester isolation
}
```

---

## ✅ Problème Résolu?

Si vous avez trouvé la solution, pensez à:

1. ✔️ Tester complètement
2. ✔️ Nettoyer les fichiers
3. ✔️ Commit le fix
4. ✔️ Documenter la solution
5. ✔️ Partager avec l'équipe

---

**Document**: Guide de Dépannage
**Version**: 1.0
**Dernière MAJ**: 2026
**Maintenu par**: Tech4Girls Team
