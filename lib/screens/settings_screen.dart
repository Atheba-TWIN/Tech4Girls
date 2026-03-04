import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tech4girls/providers/sensor_data_provider.dart';
import 'package:tech4girls/models/alert_settings.dart';
import 'package:tech4girls/models/emergency_contact.dart';
import 'package:tech4girls/services/database_service.dart';
import 'package:tech4girls/services/emergency_service.dart';
import 'package:tech4girls/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _temperatureController;
  // ignore: unused_field
  final _databaseService = DatabaseService();
  final _emergencyService = EmergencyService();
  List<EmergencyContact> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SensorDataProvider>().alertSettings;
    _temperatureController = TextEditingController(
      text: settings.temperatureThreshold.toString(),
    );
    _loadEmergencyContacts();
  }

  Future<void> _loadEmergencyContacts() async {
    final contacts = await _emergencyService.getEmergencyContacts();
    setState(() {
      _emergencyContacts = contacts;
    });
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
                  // User Profile Section
                  _buildUserProfileCard(),
                  const SizedBox(height: 24),

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
                                      callAmbulanceOnEmergency:
                                          sensorProvider
                                              .alertSettings
                                              .callAmbulanceOnEmergency,
                                      emergencyContactIds:
                                          sensorProvider
                                              .alertSettings
                                              .emergencyContactIds,
                                      enableMovementAnomaly:
                                          sensorProvider
                                              .alertSettings
                                              .enableMovementAnomaly,
                                      movementAnomalyThreshold:
                                          sensorProvider
                                              .alertSettings
                                              .movementAnomalyThreshold,
                                    );
                                    await sensorProvider.updateAlertSettings(
                                      newSettings,
                                    );
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Seuil de température mis à jour',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: null,
                              ),
                            ],
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
                                callAmbulanceOnEmergency:
                                    sensorProvider
                                        .alertSettings
                                        .callAmbulanceOnEmergency,
                                emergencyContactIds:
                                    sensorProvider
                                        .alertSettings
                                        .emergencyContactIds,
                                enableMovementAnomaly:
                                    sensorProvider
                                        .alertSettings
                                        .enableMovementAnomaly,
                                movementAnomalyThreshold:
                                    sensorProvider
                                        .alertSettings
                                        .movementAnomalyThreshold,
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

                  // Emergency Contacts Section
                  Text(
                    'Contacts d\'Urgence',
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Contacts configurés: ${_emergencyContacts.length}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              ElevatedButton.icon(
                                onPressed:
                                    () => _showAddContactDialog(sensorProvider),
                                icon: const Icon(Icons.add),
                                label: const Text('Ajouter'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_emergencyContacts.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.person_add,
                                      size: 48,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Aucun contact d\'urgence',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _emergencyContacts.length,
                              itemBuilder: (context, index) {
                                final contact = _emergencyContacts[index];
                                final isSelected = sensorProvider
                                    .alertSettings
                                    .emergencyContactIds
                                    .contains(contact.id);
                                return ListTile(
                                  leading: Checkbox(
                                    value: isSelected,
                                    onChanged: (value) async {
                                      final newContactIds = List<String>.from(
                                        sensorProvider
                                            .alertSettings
                                            .emergencyContactIds,
                                      );
                                      if (value ?? false) {
                                        if (!newContactIds.contains(
                                          contact.id,
                                        )) {
                                          newContactIds.add(contact.id);
                                        }
                                      } else {
                                        newContactIds.remove(contact.id);
                                      }
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
                                        enableNotifications:
                                            sensorProvider
                                                .alertSettings
                                                .enableNotifications,
                                        callAmbulanceOnEmergency:
                                            sensorProvider
                                                .alertSettings
                                                .callAmbulanceOnEmergency,
                                        emergencyContactIds: newContactIds,
                                        enableMovementAnomaly:
                                            sensorProvider
                                                .alertSettings
                                                .enableMovementAnomaly,
                                        movementAnomalyThreshold:
                                            sensorProvider
                                                .alertSettings
                                                .movementAnomalyThreshold,
                                      );
                                      await sensorProvider.updateAlertSettings(
                                        newSettings,
                                      );
                                    },
                                  ),
                                  title: Text(contact.name),
                                  subtitle: Text(
                                    '${contact.phoneNumber} • ${contact.relationship ?? 'Autre'}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await _emergencyService
                                          .deleteEmergencyContact(contact.id);
                                      await _loadEmergencyContacts();
                                    },
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ambulance Setting Section
                  Text(
                    'Préférences d\'Urgence',
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
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Appeler l\'ambulance'),
                            subtitle: const Text('En cas de signal d\'urgence'),
                            value:
                                sensorProvider
                                    .alertSettings
                                    .callAmbulanceOnEmergency,
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
                                enableNotifications:
                                    sensorProvider
                                        .alertSettings
                                        .enableNotifications,
                                callAmbulanceOnEmergency: value,
                                emergencyContactIds:
                                    sensorProvider
                                        .alertSettings
                                        .emergencyContactIds,
                                enableMovementAnomaly:
                                    sensorProvider
                                        .alertSettings
                                        .enableMovementAnomaly,
                                movementAnomalyThreshold:
                                    sensorProvider
                                        .alertSettings
                                        .movementAnomalyThreshold,
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
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileCard() {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();
    final databaseService = DatabaseService();
    final userProfile =
        user != null ? databaseService.getUserProfile(user.uid) : null;

    final displayName = user?.displayName ?? user?.email ?? 'Utilisateur';
    final photoUrl = user?.photoURL;

    return Card(
      elevation: 4,
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepPurple,
                  ),
                  child:
                      photoUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    displayName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                          : Center(
                            child: Text(
                              displayName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                ),
                const SizedBox(width: 16),
                // Profile Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Email non disponible',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (userProfile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tél: ${userProfile.phoneNumber}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (userProfile != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              // Additional Info
              _buildProfileInfoRow(
                context,
                'Date de naissance',
                userProfile.dateOfBirth.toString().split(' ')[0],
              ),
              const SizedBox(height: 8),
              _buildProfileInfoRow(
                context,
                'Sexe',
                userProfile.gender == 'M'
                    ? 'Homme'
                    : userProfile.gender == 'F'
                    ? 'Femme'
                    : 'Autre',
              ),
              if (userProfile.weight != null) ...[
                const SizedBox(height: 8),
                _buildProfileInfoRow(
                  context,
                  'Poids',
                  '${userProfile.weight} kg',
                ),
              ],
            ],
            const SizedBox(height: 16),
            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                onPressed: () async {
                  await authService.logout();
                  if (mounted) {
                    // Navigate back and let AuthWrapper handle routing
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showAddContactDialog(SensorDataProvider sensorProvider) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final relationshipOptions = const [
      'Papa',
      'Maman',
      'Frère/Soeur',
      'Ami',
      'Autre',
    ];
    String selectedRelationship = 'Autre';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
            title: const Text('Ajouter un contact'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Téléphone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email (optionnel)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRelationship,
                    items:
                        relationshipOptions
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedRelationship = value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Lien',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      phoneController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez remplir les champs requis'),
                      ),
                    );
                    return;
                  }

                  if ((selectedRelationship == 'Papa' ||
                          selectedRelationship == 'Maman') &&
                      _emergencyContacts.any(
                        (c) => c.relationship == selectedRelationship,
                      )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Un seul contact "$selectedRelationship" est autorisé.',
                        ),
                      ),
                    );
                    return;
                  }

                  final contact = EmergencyContact(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    phoneNumber: phoneController.text,
                    email:
                        emailController.text.isEmpty
                            ? null
                            : emailController.text,
                    relationship: selectedRelationship,
                    notifyOnTemperatureAlert: true,
                    notifyOnEmergencyAlert: true,
                  );

                  await _emergencyService.saveEmergencyContact(contact);
                  await _loadEmergencyContacts();

                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact ajouté avec succès'),
                      ),
                    );
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
    );
  }
}
