import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tech4girls/providers/bluetooth_provider.dart';
import 'package:tech4girls/providers/sensor_data_provider.dart';
import 'package:tech4girls/services/database_service.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _databaseService = DatabaseService();
  final TextEditingController _manualTempController = TextEditingController();
  final List<_MedicationReminder> _fallbackReminders = const [
    _MedicationReminder(name: 'Acide folique', time: '08:00', dose: '5 mg'),
    _MedicationReminder(name: 'Hydroxyurée', time: '13:00', dose: '500 mg'),
    _MedicationReminder(name: 'Paracétamol', time: '20:00', dose: '1 comprimé'),
  ];
  List<_MedicationReminder> _medicationReminders = [];
  final Set<int> _takenReminderIndexes = <int>{};

  @override
  void initState() {
    super.initState();
    _loadMedicationData();
  }

  @override
  void dispose() {
    _manualTempController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicationData() async {
    final savedReminders = _databaseService.getMedicationReminders();
    final reminders =
        savedReminders.isEmpty
            ? List<_MedicationReminder>.from(_fallbackReminders)
            : savedReminders.map(_MedicationReminder.fromMap).toList();
    final savedTaken = _databaseService.getTakenMedicationIndexes();

    if (!mounted) return;
    setState(() {
      _medicationReminders = reminders;
      _takenReminderIndexes
        ..clear()
        ..addAll(
          savedTaken.where((index) => index >= 0 && index < reminders.length),
        );
    });
  }

  Future<void> _saveTakenReminders() async {
    await _databaseService.saveTakenMedicationIndexes(
      _takenReminderIndexes.toList()..sort(),
    );
  }

  Future<void> _saveMedicationReminders() async {
    await _databaseService.saveMedicationReminders(
      _medicationReminders.map((r) => r.toMap()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi Drépanocytaire'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(),
              const SizedBox(height: 16),

              // Les 4 dernières cards en grille 2x2
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonne 1
                  Expanded(
                    child: Column(
                      children: [
                        _buildConnectionCard(),
                        const SizedBox(height: 16),
                        _buildTemperatureCard(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Colonne 2
                  Expanded(
                    child: Column(
                      children: [
                        _buildEmergencyCard(),
                        const SizedBox(height: 16),
                        _buildMotionCard(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildManualTemperatureTestCard(),
              const SizedBox(height: 16),
              _buildMedicationRemindersCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildBluetoothFAB(),
    );
  }

  Widget _buildWelcomeCard() {
    final user = FirebaseAuth.instance.currentUser;
    final databaseService = DatabaseService();
    final userProfile =
        user != null ? databaseService.getUserProfile(user.uid) : null;

    final displayName =
        userProfile?.firstName.capitalize() ??
        user?.displayName ??
        (user?.email?.split('@').first ?? 'Utilisateur').capitalize();

    return Card(
      elevation: 4,
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenue,',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre bracelet de surveillance est prêt à l\'emploi.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Consumer<BluetoothProvider>(
      builder: (context, btProvider, _) {
        bool isConnected = btProvider.connectedDevice != null;
        return Card(
          elevation: 4,
          color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'État de Connexion',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        isConnected
                            ? 'Connecté: ${btProvider.connectedDevice?.platformName ?? 'Bracelet'}'
                            : 'Déconnecté',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemperatureCard() {
    return Consumer<SensorDataProvider>(
      builder: (context, sensorProvider, _) {
        final data = sensorProvider.currentData;
        final temp = data?.temperature ?? 0.0;
        final isAlert =
            temp >= sensorProvider.alertSettings.temperatureThreshold;

        return Card(
          elevation: 4,
          color: isAlert ? Colors.orange.shade50 : Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Température',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    if (isAlert)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Alerte',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${temp.toStringAsFixed(1)}°C',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: isAlert ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seuil d\'alerte: ${sensorProvider.alertSettings.temperatureThreshold}°C',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyCard() {
    return Consumer<SensorDataProvider>(
      builder: (context, sensorProvider, _) {
        final isEmergency =
            sensorProvider.currentData?.emergencySignal ?? false;
        final temperature = sensorProvider.currentData?.temperature ?? 0.0;
        final threshold = sensorProvider.alertSettings.temperatureThreshold;

        final isCriticalTemp = temperature >= 40.0;
        final isHighTemp = temperature >= threshold && temperature < 40.0;

        final Color statusColor =
            isEmergency || isCriticalTemp
                ? Colors.red
                : isHighTemp
                ? Colors.orange
                : Colors.green;

        final Color cardColor =
            isEmergency || isCriticalTemp
                ? Colors.red.shade50
                : isHighTemp
                ? Colors.orange.shade50
                : Colors.green.shade50;

        final String statusText =
            isEmergency
                ? 'ACTIVÉ'
                : isCriticalTemp
                ? 'CRITIQUE (>= 40°C)'
                : isHighTemp
                ? 'Surveillance renforcée'
                : 'Normal';

        return Card(
          elevation: 4,
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signal d\'Urgence',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMotionCard() {
    return Consumer<SensorDataProvider>(
      builder: (context, sensorProvider, _) {
        final motion = sensorProvider.currentData?.motionDetected ?? false;

        return Card(
          elevation: 4,
          color: motion ? Colors.blue.shade50 : Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  motion ? Icons.directions_walk : Icons.pan_tool,
                  color: motion ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mouvement',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        motion ? 'Détecté' : 'Aucun',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: motion ? Colors.blue : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBluetoothFAB() {
    return Consumer<BluetoothProvider>(
      builder: (context, btProvider, _) {
        bool isConnected = btProvider.connectedDevice != null;
        return FloatingActionButton(
          onPressed: () {
            if (isConnected) {
              btProvider.disconnectDevice();
            } else {
              Navigator.of(context).pushNamed('/scan');
            }
          },
          backgroundColor: isConnected ? Colors.red : Colors.blue,
          child: Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
          ),
        );
      },
    );
  }

  Widget _buildMedicationRemindersCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication_outlined, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Rappels de médicaments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Suivi journalier',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            if (_medicationReminders.isEmpty)
              Text(
                'Aucun médicament configuré.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ...List.generate(_medicationReminders.length, (index) {
              final reminder = _medicationReminders[index];
              final isTaken = _takenReminderIndexes.contains(index);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isTaken,
                        onChanged: (value) {
                          setState(() {
                            if (value ?? false) {
                              _takenReminderIndexes.add(index);
                            } else {
                              _takenReminderIndexes.remove(index);
                            }
                          });
                          _saveTakenReminders();
                        },
                      ),
                      Icon(
                        isTaken ? Icons.check_circle : Icons.schedule,
                        color: isTaken ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder.name,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              '${reminder.time} • ${reminder.dose}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Modifier',
                        onPressed: () => _editMedication(index),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Supprimer',
                        onPressed: () => _deleteMedication(index),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _addMedication,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un médicament'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTemperatureTestCard() {
    return Card(
      elevation: 4,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test alerte température',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Saisissez une valeur (ex: 39.0) pour tester l\'envoi SMS.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualTempController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Température (°C)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final value = double.tryParse(_manualTempController.text);
                    if (value == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Température invalide.'),
                        ),
                      );
                      return;
                    }

                    await context
                        .read<SensorDataProvider>()
                        .addManualTemperatureReading(value);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Mesure manuelle enregistrée: ${value.toStringAsFixed(1)}°C',
                        ),
                      ),
                    );
                  },
                  child: const Text('Déclencher'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMedication() async {
    final result = await _showMedicationDialog();
    if (result == null || !mounted) return;

    setState(() {
      _medicationReminders.add(result);
    });
    await _saveMedicationReminders();
  }

  Future<void> _editMedication(int index) async {
    if (index < 0 || index >= _medicationReminders.length) return;
    final existing = _medicationReminders[index];
    final result = await _showMedicationDialog(initial: existing);
    if (result == null || !mounted) return;

    setState(() {
      _medicationReminders[index] = result;
    });
    await _saveMedicationReminders();
  }

  Future<void> _deleteMedication(int index) async {
    if (index < 0 || index >= _medicationReminders.length) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer le médicament'),
            content: const Text('Voulez-vous supprimer ce rappel ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );

    if (!(confirm ?? false) || !mounted) return;

    setState(() {
      _medicationReminders.removeAt(index);

      // Rebuild checked indexes to keep them aligned after deletion.
      final updated = <int>{};
      for (final takenIndex in _takenReminderIndexes) {
        if (takenIndex == index) continue;
        updated.add(takenIndex > index ? takenIndex - 1 : takenIndex);
      }
      _takenReminderIndexes
        ..clear()
        ..addAll(updated);
    });

    await _saveMedicationReminders();
    await _saveTakenReminders();
  }

  Future<_MedicationReminder?> _showMedicationDialog({
    _MedicationReminder? initial,
  }) async {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    final timeController = TextEditingController();
    if (initial != null) {
      nameController.text = initial.name;
      doseController.text = initial.dose;
      timeController.text = initial.time;
    }

    final result = await showDialog<_MedicationReminder>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              initial == null ? 'Ajouter un médicament' : 'Modifier le médicament',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: doseController,
                    decoration: const InputDecoration(labelText: 'Dose'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: timeController,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        timeController.text =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Heure',
                      hintText: 'HH:mm',
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
                onPressed: () {
                  final name = nameController.text.trim();
                  final dose = doseController.text.trim();
                  final time = timeController.text.trim();
                  if (name.isEmpty || dose.isEmpty || time.isEmpty) return;
                  Navigator.pop(
                    context,
                    _MedicationReminder(name: name, time: time, dose: dose),
                  );
                },
                child: Text(initial == null ? 'Ajouter' : 'Enregistrer'),
              ),
            ],
          ),
    );

    return result;
  }
}

class _MedicationReminder {
  final String name;
  final String time;
  final String dose;

  const _MedicationReminder({
    required this.name,
    required this.time,
    required this.dose,
  });

  Map<String, String> toMap() => {
    'name': name,
    'time': time,
    'dose': dose,
  };

  factory _MedicationReminder.fromMap(Map<String, String> map) {
    return _MedicationReminder(
      name: map['name'] ?? '',
      time: map['time'] ?? '',
      dose: map['dose'] ?? '',
    );
  }
}
