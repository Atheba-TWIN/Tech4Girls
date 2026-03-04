import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:provider/provider.dart';
// ignore: unused_import
import 'package:tech4girls/providers/sensor_data_provider.dart';
import 'package:tech4girls/models/emergency_contact.dart';
import 'package:tech4girls/models/alert_settings.dart';
import 'package:tech4girls/services/database_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  // Settings
  bool _callAmbulance = false;
  final List<EmergencyContact> _contacts = [];
  String _patientName = '';

  // Form fields for new contact
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  final List<String> _relationshipOptions = const [
    'Papa',
    'Maman',
    'Frère/Soeur',
    'Ami',
    'Autre',
  ];
  String _selectedRelationship = 'Autre';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _addContact() {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir les champs requis')),
      );
      return;
    }

    if ((_selectedRelationship == 'Papa' || _selectedRelationship == 'Maman') &&
        _contacts.any((c) => c.relationship == _selectedRelationship)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Un seul contact "$_selectedRelationship" est autorisé.',
          ),
        ),
      );
      return;
    }

    final contact = EmergencyContact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      phoneNumber: _phoneController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      relationship: _selectedRelationship,
      notifyOnTemperatureAlert: true,
      notifyOnEmergencyAlert: true,
    );

    setState(() {
      _contacts.add(contact);
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _selectedRelationship = 'Autre';
    });
  }

  void _removeContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
  }

  Future<void> _finishOnboarding() async {
    final databaseService = DatabaseService();

    // Save patient name (you might want to store this in a separate box)
    // For now, we'll focus on saving contacts and settings

    // Save all emergency contacts
    for (final contact in _contacts) {
      await databaseService.saveEmergencyContact(contact);
    }

    // Update alert settings with contact IDs and ambulance preference
    final contactIds = _contacts.map((c) => c.id).toList();
    final currentSettings = databaseService.getAlertSettings();

    final updatedSettings = AlertSettings(
      temperatureThreshold: currentSettings.temperatureThreshold,
      enableTemperatureAlert: currentSettings.enableTemperatureAlert,
      enableEmergencyAlert: currentSettings.enableEmergencyAlert,
      enableNotifications: currentSettings.enableNotifications,
      callAmbulanceOnEmergency: _callAmbulance,
      emergencyContactIds: contactIds,
      enableMovementAnomaly: currentSettings.enableMovementAnomaly,
      movementAnomalyThreshold: currentSettings.movementAnomalyThreshold,
    );

    await databaseService.saveAlertSettings(updatedSettings);

    // mark onboarding as done so next launch goes straight to home
    await databaseService.setOnboardingComplete(true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Initiale'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        children: [
          _buildWelcomePage(),
          _buildPatientInfoPage(),
          _buildEmergencyContactsPage(),
          _buildAmbulanceSettingPage(),
          _buildSummaryPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety, size: 80, color: Colors.deepPurple),
          const SizedBox(height: 32),
          Text(
            'Bienvenue!',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Cette application vous aide à suivre votre santé et à alerter automatiquement vos proches en cas d\'urgence.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            'Commençons la configuration!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Vos informations',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          TextField(
            onChanged: (value) => _patientName = value,
            decoration: InputDecoration(
              labelText: 'Votre nom',
              hintText: 'Entrez votre nom complet',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seuils d\'alerte recommandés',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.thermostat, color: Colors.red),
                    title: const Text('Température'),
                    subtitle: const Text('Alerte \u00e0 38°C ou plus'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.emergency, color: Colors.red),
                    title: const Text('Signal d\'urgence'),
                    subtitle: const Text(
                      'Alerte imm\u00e9diate si activ\u00e9',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Contacts d\'urgence',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez les personnes qui seront alertées en cas d\'urgence',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Expanded(
            child:
                _contacts.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun contact ajouté',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(contact.name),
                            subtitle: Text(
                              '${contact.phoneNumber} • ${contact.relationship ?? 'Autre'}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeContact(index),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter un contact',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    hintText: 'Ex: Maman',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    hintText: 'Ex: +33612345678',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email (optionnel)',
                    hintText: 'Ex: contact@example.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRelationship,
                  items:
                      _relationshipOptions
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedRelationship = value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Lien',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addContact,
                    child: const Text('Ajouter ce contact'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbulanceSettingPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Appel ambulance',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'En cas de signal d\'urgence',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _callAmbulance,
                    onChanged: (value) {
                      setState(() => _callAmbulance = value ?? false);
                    },
                    title: const Text(
                      'Appeler automatiquement l\'ambulance la plus proche',
                    ),
                    subtitle: const Text(
                      'Le n° du SAMU (15) sera contacté avec votre position',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Note: Votre localisation GPS sera partagée avec les ambulances pour intervention plus rapide.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vous pourrez modifier ce choix à tout moment dans les paramètres.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Résumé de la configuration',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummarySection(
                    'Informations personnelles',
                    Icons.person,
                    [
                      if (_patientName.isNotEmpty)
                        _patientName
                      else
                        'Non défini',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSummarySection(
                    'Contacts d\'urgence',
                    Icons.contacts,
                    _contacts.isEmpty
                        ? ['Aucun contact ajouté']
                        : _contacts
                            .map(
                              (c) =>
                                  '${c.name} (${c.relationship ?? 'Autre'}) - ${c.phoneNumber}',
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 20),
                  _buildSummarySection('Ambulance', Icons.emergency, [
                    _callAmbulance ? 'Appel automatique activé' : 'Désactivé',
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, IconData icon, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('• $item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            ElevatedButton(
              onPressed:
                  () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
              child: const Text('Précédent'),
            )
          else
            const SizedBox(width: 100),
          Expanded(
            child: Center(
              child: Wrap(
                spacing: 8,
                children: List.generate(
                  5,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          index == _currentPage
                              ? Colors.deepPurple
                              : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed:
                _currentPage == 4
                    ? _finishOnboarding
                    : () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
            child: Text(_currentPage == 4 ? 'Terminer' : 'Suivant'),
          ),
        ],
      ),
    );
  }
}
