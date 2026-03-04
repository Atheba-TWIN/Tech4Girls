import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tech4girls/screens/auth_wrapper.dart';
import 'firebase_options.dart';
import 'package:logging/logging.dart';
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
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // 🔥 Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((rec) {
    // ignore: avoid_print
    print('${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
  });

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize database service
  final databaseService = DatabaseService();
  await databaseService.initialize();

  // Determine whether onboarding was completed
  bool onboardingDone = databaseService.isOnboardingComplete();

  runApp(MyApp(onboardingDone: onboardingDone));
}

class MyApp extends StatelessWidget {
  final bool onboardingDone;

  const MyApp({super.key, required this.onboardingDone});

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
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => const MainNavigation(initialIndex: 0),
          '/history': (context) => const MainNavigation(initialIndex: 1),
          '/settings': (context) => const MainNavigation(initialIndex: 2),
          '/scan': (context) => const BluetoothScanScreen(),
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
  static bool _providersInitialized = false;

  late SensorDataProvider _sensorDataProvider;
  late LocationProvider _locationProvider;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    if (_providersInitialized) return;
    _sensorDataProvider = context.read<SensorDataProvider>();
    _locationProvider = context.read<LocationProvider>();

    // Initialize sensor data provider
    await _sensorDataProvider.initialize();

    // Initialize location provider
    try {
      await _locationProvider.initialize();
    } catch (e) {
      // use logging instead of print
      Logger('MainNavigation').shout('Error initializing location: $e');
    }
    _providersInitialized = true;
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
          if (index == _selectedIndex) return;
          final route = switch (index) {
            0 => '/home',
            1 => '/history',
            2 => '/settings',
            _ => '/home',
          };
          Navigator.of(context).pushReplacementNamed(route);
        },
      ),
    );
  }
}
