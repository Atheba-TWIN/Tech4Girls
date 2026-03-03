import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:tech4girls/providers/bluetooth_provider.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  @override
  void initState() {
    super.initState();
    // Start scanning when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothProvider>().startScan();
    });
  }

  @override
  void dispose() {
    // Stop scanning when leaving
    context.read<BluetoothProvider>().stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher un Bracelet'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, btProvider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (btProvider.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Erreur: ${btProvider.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (btProvider.isScanning)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Recherche en cours...'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child:
                    btProvider.devices.isEmpty && !btProvider.isScanning
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth_disabled,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text('Aucun périphérique trouvé'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  btProvider.startScan();
                                },
                                child: const Text('Relancer la recherche'),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: btProvider.devices.length,
                          itemBuilder: (context, index) {
                            final device = btProvider.devices[index];
                            return _buildDeviceTile(
                              context,
                              device,
                              btProvider,
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeviceTile(
    BuildContext context,
    ScanResult device,
    BluetoothProvider btProvider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.devices, color: Colors.deepPurple),
        title: Text(
          device.device.platformName.isNotEmpty
              ? device.device.platformName
              : 'Appareil inconnu',
        ),
        subtitle: Text(device.device.remoteId.toString()),
        trailing: ElevatedButton(
          onPressed: () async {
            await btProvider.connectToDevice(device.device);
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Connecter'),
        ),
      ),
    );
  }
}
