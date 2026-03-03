# Checklist Initialisation du Projet

## ✅ Avant de Démarrer

### 1. Installation de Flutter

- [ ] Flutter SDK installé (https://flutter.dev)
- [ ] Dart SDK inclus
- [ ] Android SDK configuré (pour Android)
- [ ] Xcode installé (pour iOS)
- [ ] Vérifier: `flutter doctor`

### 2. Cloner le Projet

```bash
git clone <repository-url> tech4girls
cd tech4girls
```

### 3. Dépendances Flutter

```bash
flutter pub get
```

- [ ] ✓ Toutes les dépendances téléchargées

### 4. Code Generation (Hive)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] ✓ Adapters Hive générés
- [ ] ✓ `sensor_data.g.dart` créé
- [ ] ✓ `alert_settings.g.dart` créé

## ⚙️ Configuration Requise

### Android

#### 4.1 Google Maps API

- [ ] Aller sur [Google Cloud Console](https://console.cloud.google.com/)
- [ ] Créer un nouveau projet
- [ ] Activer `Maps SDK for Android`
- [ ] Créer une clé API
- [ ] Copier la clé

#### 4.2 Ajouter la Clé

Modifier `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE" />
</application>
```

- [ ] ✓ Clé API insérée
- [ ] ✓ Aucune syntaxe erreur

#### 4.3 Vérifier Permissions

Contrôler `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

- [ ] ✓ Toutes les permissions présentes

### iOS

#### 4.4 Localisation et Bluetooth

Modifier `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Utilisé pour afficher votre position sur la carte</string>

<key>NSBluetoothAlwaysUsageDescription</key>
<string>Utilisé pour se connecter au bracelet capteur</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>Utilisé pour recevoir les données de santé</string>
```

- [ ] ✓ Clés ajoutées à Info.plist

#### 4.5 Google Maps (iOS)

Voir CONFIGURATION.md pour les détails spécifiques iOS.

## 🧪 Tests Pré-Lancement

### 5.1 Coder et Compiler

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] ✓ Compilation sans erreur

### 5.2 Lancer en Mode Debug

```bash
flutter run -d <device-id>
```

- [ ] ✓ App lance sans crash
- [ ] ✓ Écrans s'affichent

### 5.3 Tester Bluetooth

1. Activer un bracelet BLE
2. Naviguer vers "Rechercher un Bracelet"
3. Attendre la détection (max 15s)
4. Vérifier que l'appareil s'affiche
5. Cliquer "Connecter"

- [ ] ✓ Bracelet détecté
- [ ] ✓ Connexion établie
- [ ] ✓ Données reçues

### 5.4 Tester Localisation

1. Activer les services de localisation
2. Accorder les permissions
3. Vérifier la position affichée
4. Vérifier la carte chargée

- [ ] ✓ Position affichée
- [ ] ✓ Carte fonctionnelle
- [ ] ✓ Précision acceptable

### 5.5 Tester Notifications

1. Augmenter température simulée
2. Déclencher alerte urgence
3. Vérifier notification reçue

- [ ] ✓ Notification affichée
- [ ] ✓ Vibration fonctionnelle
- [ ] ✓ Son joué (si activé)

### 5.6 Tester Historique

1. Attendre quelques mesures
2. Aller à "Historique"
3. Sélectionner période
4. Vérifier graphique

- [ ] ✓ Données affichées
- [ ] ✓ Graphique tracé
- [ ] ✓ Statistiques correctes

### 5.7 Tester Paramètres

1. Aller à "Paramètres"
2. Modifier seuil température
3. Activer/désactiver alertes
4. Sauvegarder

- [ ] ✓ Changements sauvegardés
- [ ] ✓ Affichage mis à jour

## 📱 Devices de Test

### Android

```bash
# Lister appareils
flutter devices

# Lancer sur un device spécifique
flutter run -d <device-id>

# Lancer sur tous les devices
flutter run -d all
```

- [ ] ✓ Device détecté
- [ ] ✓ App installée

### iOS

```bash
# Ouvrir Xcode
open ios/Runner.xcworkspace

# Ou lancer directement
flutter run -d "iPhone 14"
```

- [ ] ✓ Simulateur/Device connecté
- [ ] ✓ App lancé

## 🔧 Dépannage

### Si "flutter doctor" échoue

```bash
flutter doctor --verbose
# Suivre les instructions
```

### Si compilation échoue

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Si Hive ne fonctionne pas

- [ ] Vérifier que build_runner a généré les fichiers .g.dart
- [ ] Vérifier @HiveType et @HiveField annotations
- [ ] Régénérer: `flutter pub run build_runner build`

### Si Google Maps ne s'affiche pas

- [ ] Vérifier API Key configurée
- [ ] Vérifier Internet activé
- [ ] Vérifier permissions accordées
- [ ] Vérifier billing activé sur Google Cloud

### Si Bluetooth ne fonctionne pas

- [ ] Vérifier Bluetooth allumé
- [ ] Vérifier permissions Bluetooth accordées
- [ ] Vérifier bracelet en mode broadcast

## 📚 Documentation À Consulter

| Document                   | Objectif                |
| -------------------------- | ----------------------- |
| SETUP_GUIDE.md             | Installation complète   |
| CONFIGURATION.md           | Configuration détaillée |
| BRACELET_FIRMWARE_GUIDE.md | Développement bracelet  |
| USAGE_EXAMPLES.md          | Exemples de code        |
| PROJECT_SUMMARY.md         | Vue d'ensemble projet   |

## 🚀 Prêt à Démarrer!

Une fois cette checklist complétée, vous pouvez:

1. **Développer** les nouvelles fonctionnalités
2. **Modifier** la UI selon besoin
3. **Ajouter** des services supplémentaires
4. **Builder** pour Google Play/App Store

```bash
# Mode développement
flutter run

# Build release Android
flutter build apk --release

# Build release iOS
flutter build ios --release

# Build web
flutter build web --release
```

## 📞 En Cas de Problème

1. Vérifier les logs: `flutter logs`
2. Activer verbose: `flutter run -v`
3. Consulter la documentation pertinente
4. Vérifier les versions:
   ```bash
   flutter --version
   dart --version
   ```

## ✨ Prochaines Étapes

- [ ] Personnaliser les couleurs/logo
- [ ] Traduire en d'autres langues
- [ ] Ajouter plus de fonctionnalités
- [ ] Tester sur plusieurs devices
- [ ] Préparer pour publication Play Store/App Store

---

**Date**: 2026
**Version App**: 1.0.0
**Bonne Développement!** 🎉
