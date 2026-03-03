import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tech4girls/providers/sensor_data_provider.dart';
import 'package:tech4girls/models/alert_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _temperatureController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SensorDataProvider>().alertSettings;
    _temperatureController = TextEditingController(
      text: settings.temperatureThreshold.toString(),
    );
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<SensorDataProvider>(
            builder: (context, sensorProvider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alert Settings Section
                  Text(
                    'Paramètres d\'Alerte',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Temperature Threshold Setting
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seuil de Température',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _temperatureController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Température (°C)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    suffixText: '°C',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  final temp = double.tryParse(
                                    _temperatureController.text,
                                  );
                                  if (temp != null && temp > 0) {
                                    final newSettings = AlertSettings(
                                      temperatureThreshold: temp,
                                      enableTemperatureAlert:
                                          sensorProvider
                                              .alertSettings
                                              .enableTemperatureAlert,
                                      enableEmergencyAlert:
                                          sensorProvider
                                              .alertSettings
                                              .enableEmergencyAlert,
                                      enableNotifications:
                                          sensorProvider
                                              .alertSettings
                                              .enableNotifications,
                                    );
                                    await sensorProvider.updateAlertSettings(
                                      newSettings,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Seuil mis à jour'),
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Valeur invalide'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Enregistrer'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Une alerte sera envoyée si la température dépasse ce seuil',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Enable/Disable Alerts
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Alertes de Température'),
                            value:
                                sensorProvider
                                    .alertSettings
                                    .enableTemperatureAlert,
                            onChanged: (value) async {
                              final newSettings = AlertSettings(
                                temperatureThreshold:
                                    sensorProvider
                                        .alertSettings
                                        .temperatureThreshold,
                                enableTemperatureAlert: value,
                                enableEmergencyAlert:
                                    sensorProvider
                                        .alertSettings
                                        .enableEmergencyAlert,
                                enableNotifications:
                                    sensorProvider
                                        .alertSettings
                                        .enableNotifications,
                              );
                              await sensorProvider.updateAlertSettings(
                                newSettings,
                              );
                            },
                          ),
                          const Divider(),
                          SwitchListTile(
                            title: const Text('Alertes d\'Urgence'),
                            value:
                                sensorProvider
                                    .alertSettings
                                    .enableEmergencyAlert,
                            onChanged: (value) async {
                              final newSettings = AlertSettings(
                                temperatureThreshold:
                                    sensorProvider
                                        .alertSettings
                                        .temperatureThreshold,
                                enableTemperatureAlert:
                                    sensorProvider
                                        .alertSettings
                                        .enableTemperatureAlert,
                                enableEmergencyAlert: value,
                                enableNotifications:
                                    sensorProvider
                                        .alertSettings
                                        .enableNotifications,
                              );
                              await sensorProvider.updateAlertSettings(
                                newSettings,
                              );
                            },
                          ),
                          const Divider(),
                          SwitchListTile(
                            title: const Text('Activer les Notifications'),
                            value:
                                sensorProvider
                                    .alertSettings
                                    .enableNotifications,
                            onChanged: (value) async {
                              final newSettings = AlertSettings(
                                temperatureThreshold:
                                    sensorProvider
                                        .alertSettings
                                        .temperatureThreshold,
                                enableTemperatureAlert:
                                    sensorProvider
                                        .alertSettings
                                        .enableTemperatureAlert,
                                enableEmergencyAlert:
                                    sensorProvider
                                        .alertSettings
                                        .enableEmergencyAlert,
                                enableNotifications: value,
                              );
                              await sensorProvider.updateAlertSettings(
                                newSettings,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  Text(
                    'À Propos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Application de Suivi Drépanocytaire',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Version: 1.0.0',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cette application aide à surveiller la température corporelle et les signaux d\'urgence des patients atteints de drépanocytose.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
