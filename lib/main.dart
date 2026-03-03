import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tech4girls/services/notification_service.dart';
import 'package:tech4girls/services/database_service.dart';
import 'package:tech4girls/providers/bluetooth_provider.dart';
import 'package:tech4girls/providers/sensor_data_provider.dart';
import 'package:tech4girls/providers/location_provider.dart';
import 'package:tech4girls/screens/home_screen.dart';
import 'package:tech4girls/screens/bluetooth_scan_screen.dart';
import 'package:tech4girls/screens/history_screen.dart';
import 'package:tech4girls/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize database service
  final databaseService = DatabaseService();
  await databaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProvider(create: (_) => SensorDataProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'Suivi Drépanocytaire',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MainNavigation(),
        routes: {
          '/scan': (context) => const BluetoothScanScreen(),
          '/history': (context) => const HistoryScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late SensorDataProvider _sensorDataProvider;
  late LocationProvider _locationProvider;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    _sensorDataProvider = context.read<SensorDataProvider>();
    _locationProvider = context.read<LocationProvider>();

    // Initialize sensor data provider
    await _sensorDataProvider.initialize();

    // Initialize location provider
    try {
      await _locationProvider.initialize();
    } catch (e) {
      print('Error initializing location: $e');
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _sensorDataProvider.dispose();
    _locationProvider.dispose();
    super.dispose();
  }
}
