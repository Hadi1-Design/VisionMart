import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_app/theme/design_system.dart';
import 'firebase_options.dart';

// Import all your pages
import 'pages/dashboard.dart';
import 'pages/crowded_dense_area.dart';

import 'pages/heatmap.dart';
import 'pages/login.dart';
import 'pages/signup.dart';
import 'pages/forgot_password.dart';
import 'pages/settings.dart';
import 'pages/splash.dart';
import 'pages/suspicious_activity.dart';

import 'package:vision_app/pages/alert_service.dart'; // <-- ADDED: import service for seeding
import 'pages/staff_dashboard.dart';
import 'services/presence_service.dart';
import 'services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Presence Tracking (Unique Devices)
  await PresenceService.instance.initialize();

  // Initialize Connectivity Monitoring
  await ConnectivityService.instance.initialize();

  // Start listening to real-time weapon and shoplifting alerts from Firebase
  // This will automatically populate the "Recent Alerts" and trigger popups.
  AlertService.instance.startListeningToWeapons();
  AlertService.instance.startListeningToShoplifting();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Full App',
      scaffoldMessengerKey: globalScaffoldMessengerKey, // <-- Global Pop-ups
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.background,
          surfaceContainer: AppColors.card,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
            .copyWith(
              displayLarge: AppTextStyles.heading(fontSize: 32),
              displayMedium: AppTextStyles.heading(fontSize: 24),
              bodyLarge: AppTextStyles.body(fontSize: 16),
              bodyMedium: AppTextStyles.body(fontSize: 14),
            ),
      ),
      initialRoute: '/splash',
      // routes: {
      //   '/splash': (context) => const SplashPage(),
      //   '/login': (context) => const LoginPage(),
      //   '/dashboard': (context) => DashboardPage(onThemeChanged: toggleTheme),
      //   '/people-counter': (context) => PeopleCounterPage(),
      //   '/stock-monitoring': (context) => StockMonitoringPage(),
      //   '/alerts': (context) => AlertsPage(),
      //   '/analytics': (context) => AnalyticsPage(),
      //   '/cleaning': (context) => CleaningPage(),
      //   '/fallen-object': (context) => FallenObjectsPage(),
      //   '/heatmap': (context) => HeatmapPage(),
      //   '/suspicious-activity': (context) => SuspiciousActivityPage(),
      //   '/settings': (context) => SettingsPage(onThemeChanged: toggleTheme),
      //   '/index': (context) => IndexPage(),
      // },
      routes: {
        '/splash': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),

        // ADMIN DASHBOARD (same as your current dashboard)
        '/dashboard': (context) => DashboardPage(onThemeChanged: toggleTheme),

        // STAFF DASHBOARD (new)
        '/staff_dashboard': (context) =>
            StaffDashboardPage(onThemeChanged: toggleTheme),

        // Other pages
        '/heatmap': (context) => HeatmapPage(),
        '/suspicious-activity': (context) => SuspiciousActivityPage(),
        '/crowded-dense-area': (context) => const CrowdedDenseAreaPage(),
        '/settings': (context) =>
            SettingsPage(onThemeChanged: toggleTheme, isAdmin: true),
      },
    );
  }
}
