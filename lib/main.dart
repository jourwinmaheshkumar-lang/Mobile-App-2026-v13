import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/core/theme.dart';
import 'src/core/services/theme_service.dart';
import 'src/core/services/localization_service.dart';
import 'src/core/utils/text_utils.dart';
import 'src/features/splash/splash_screen.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/main_container.dart';
import 'src/core/services/auth_service.dart';

// Global theme service instance for easy access
final themeService = ThemeService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  print('Firebase initialized successfully');
  
  // Initialize theme service
  await themeService.init();
  
  // Initialize text utilities
  await textUtils.init();
  
  // Initialize localization service
  await localizationService.init();
  
  runApp(const DirectorHubApp());
}

class DirectorHubApp extends StatefulWidget {
  const DirectorHubApp({super.key});

  @override
  State<DirectorHubApp> createState() => _DirectorHubAppState();
}

class _DirectorHubAppState extends State<DirectorHubApp> {
  @override
  void initState() {
    super.initState();
    // Listen for global changes
    themeService.addListener(_onServiceChanged);
    textUtils.addListener(_onServiceChanged);
    localizationService.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    themeService.removeListener(_onServiceChanged);
    textUtils.removeListener(_onServiceChanged);
    localizationService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Director Hub Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      home: StreamBuilder(
        stream: AuthService().userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            return const MainContainer();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
