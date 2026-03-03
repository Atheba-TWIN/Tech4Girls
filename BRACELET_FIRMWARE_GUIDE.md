# Documentation du Bracelet Capteur Drépanocytaire

## Vue d'ensemble

Le bracelet est un périphérique Bluetooth Low Energy (BLE) qui envoie les données de santé en temps réel à l'application mobile.

## Spécifications Bluetooth

- **Type**: Bluetooth Low Energy (BLE)
- **Mode**: Broadcast/Notify
- **Protocole**: UART Serial (Service UUID standard)
- **Baudrate**: 115200 bps (standard BLE)

## Format des Données Transmises

Chaque message du bracelet est composé de **2 bytes**:

```
Byte 0: Température
Byte 1: Signal d'Urgence
```

### Byte 0 - Température

- **Format**: Entier non signé (0-255)
- **Calcul**: Température en °C = Byte 0 / 2
- **Plage valide**: 30°C à 42°C
- **Résolution**: 0.5°C

**Exemples**:

- Byte 0 = 60 → 30°C (température minimale)
- Byte 0 = 76 → 38°C (normal)
- Byte 0 = 80 → 40°C (alerte)
- Byte 0 = 84 → 42°C (température maximale)

### Byte 1 - Signal d'Urgence

- **Format**: Booléen (0 ou 1)
- **Valeurs**:
  - `0` = Pas d'urgence (vert)
  - `1` = Urgence détectée (rouge)
- **Usage**: Bouton d'urgence physique sur le bracelet

## Exemples de Frames

```
Frame: [76, 0]   → 38°C, pas d'urgence
Frame: [76, 1]   → 38°C, urgence activée
Frame: [126, 1]  → 63°C, urgence activée (crise)
```

## Fréquence d'Envoi

- **Recommandée**: Toutes les 5-10 secondes
- **Minimale**: Toutes les 30 secondes
- **Optimale**: Toutes les 5 secondes

## Service et Characteristics BLE

### Service UART Standard

```
Service UUID: 6E400001-B5A3-F393-E0A9-E50E24DCCA9E

Characteristics:
├── TX (Write): 6E400002-B5A3-F393-E0A9-E50E24DCCA9E
│   └── Commandes envoyées vers le bracelet
└── RX (Notify): 6E400003-B5A3-F393-E0A9-E50E24DCCA9E
    └── Données reçues du bracelet
```

### Commandes Possibles (Bracelet → App)

```
Télémetrie Standard:
[0x54, 0x45, 0x4d, 0x50] = "TEMP" (Header optionnel)
[Température, Urgence]

Exemple complet:
"TEMP" + "TC\x00" = [0x54, 0x45, 0x4d, 0x50] + [tempsec, urgence_bit]
```

## Implémentation Arduino (Exemple)

```cpp
#include <ArduinoBLE.h>

BLEService sensorService("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
BLECharacteristic rxCharacteristic("6E400003-B5A3-F393-E0A9-E50E24DCCA9E",
                                    BLERead | BLENotify, 2);

void setup() {
  // Initialiser BLE
  if (!BLE.begin()) {
    while (1);
  }

  BLE.setLocalName("SickleCellBracelet");
  BLE.setAdvertisedService(sensorService);
  sensorService.addCharacteristic(rxCharacteristic);
  BLE.addService(sensorService);

  BLE.advertise();
}

void loop() {
  BLEDevice central = BLE.central();

  if (central) {
    while (central.connected()) {
      // Lire capteur de température
      float tempC = readTemperatureSensor();

      // Lire bouton d'urgence
      bool emergency = digitalRead(EMERGENCY_BUTTON);

      // Préparer frame
      byte frame[2];
      frame[0] = (byte)(tempC * 2);  // Température
      frame[1] = emergency ? 1 : 0;  // Urgence

      // Envoyer via BLE
      rxCharacteristic.writeValue(frame, 2);

      delay(5000);  // Envoyer tous les 5 secondes
    }
  }
}

float readTemperatureSensor() {
  // Lire capteur (DS18B20, MLX90614, BME280, etc.)
  // Retourner température en °C
  return 37.5;
}
```

## Implémentation MicroPython (Exemple)

```python
import bluetooth
from ble_advertising import advertising_payload
from micropython import const

_IRQ_CENTRAL_CONNECT = const(1)
_IRQ_CENTRAL_DISCONNECT = const(2)

_UART_SERVICE_UUID = bluetooth.UUID("6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
_UART_RX_CHAR_UUID = bluetooth.UUID("6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

class BLETemperatureSensor:
    def __init__(self):
        self.ble = bluetooth.BLE()
        self.ble.active(True)
        self.ble.irq(self.ble_irq)

        # Créer service UART
        self.register_services()
        self.advertise()

    def register_services(self):
        # Créer caractéristique RX (notify)
        (self.rx_char_h,) = self.ble.gatts_register_services([
            (_UART_SERVICE_UUID, [
                (_UART_RX_CHAR_UUID, bluetooth.FLAG_READ | bluetooth.FLAG_NOTIFY),
            ])
        ])

    def advertise(self):
        self.ble.gap_advertise(100, advertising_payload(
            name="SickleCellBand",
            services=[_UART_SERVICE_UUID]
        ))

    def ble_irq(self, event, data):
        if event == _IRQ_CENTRAL_CONNECT:
            self.start_sensing()
        elif event == _IRQ_CENTRAL_DISCONNECT:
            self.stop_sensing()

    def start_sensing(self):
        while True:
            # Lire capteur
            temp = self.read_temperature()
            emergency = self.read_emergency()

            # Préparer frame
            frame = bytes([int(temp * 2), 1 if emergency else 0])

            # Envoyer notification
            self.ble.gatts_notify(0, self.rx_char_h, frame)

            time.sleep(5)  # 5 secondes

    def read_temperature(self):
        # Implémenter lecture du capteur
        return 37.5

    def read_emergency(self):
        # Implémenter lecture du bouton
        return False
```

## Debugging et Testing

### Avec Android (Bluetooth Terminal)

1. Télécharger "Bluetooth Terminal" depuis Google Play
2. Scanner et se connecter au bracelet
3. Vérifier les données reçues en hexadécimal

### Avec nRF Connect (Nordic)

1. Télécharger l'app "nRF Connect"
2. Scanner le bracelet
3. Se connecter
4. Activer notifications sur la characteristic RX
5. Observer les frames entrants

### Avec Python (PC)

```python
import asyncio
from bleak import BleakClient

DEVICE_ADDRESS = "XX:XX:XX:XX:XX:XX"
RX_CHAR_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

async def main():
    async with BleakClient(DEVICE_ADDRESS) as client:
        # Callback pour les notifications
        def notification_handler(sender, data):
            temp = data[0] / 2.0
            emergency = bool(data[1])
            print(f"Température: {temp}°C, Urgence: {emergency}")

        # S'abonner aux notifications
        await client.start_notify(RX_CHAR_UUID, notification_handler)

        # Écouter pendant 60 secondes
        await asyncio.sleep(60)

        await client.stop_notify(RX_CHAR_UUID)

asyncio.run(main())
```

## Points Importants

1. **Stabilité**: Éviter les déconnexions fréquentes
2. **Batterie**: Utiliser BLE pour minimiser la consommation
3. **Sécurité**: Ne pas envoyer d'ID utilisateur via BLE
4. **Précision**: Calibrer précisément le capteur de température
5. **Redondance**: Envoyer l'urgence plusieurs fois pour sûreté

## Support des Capteurs

### Capteurs de Température Recommandés

1. **DS18B20**: Simple, 0.5°C de résolution
2. **MLX90614**: Infrarouge, sans contact (idéal)
3. **BME280**: Température + pression + humidité
4. **DHT22**: Budget-friendly, mais moins précis

### Bouton d'Urgence

- Bouton momentané simple
- Débounce matériel ou logiciel requis (20-50ms)
- LED de confirmation recommandée

## Troubleshooting

| Problème                    | Cause Probable      | Solution                |
| --------------------------- | ------------------- | ----------------------- |
| Données erratiques          | Capteur instable    | Ajouter filtre logiciel |
| Déconnexions fréquentes     | Radio interference  | Augmenter puissance TX  |
| Batterie épuisée rapidement | Envoi trop fréquent | Réduire fréquence à 30s |
| Température incorrecte      | Capteur mal calibré | Re-calibrer ou offset   |
| Urgence ne fonctionne pas   | Mauvais wiring      | Vérifier connexions     |

---

**Document Version**: 1.0  
**Dernière mise à jour**: 2026  
**Plateforme Support**: Arduino, MicroPython, ESP32, nRF52, STM32
