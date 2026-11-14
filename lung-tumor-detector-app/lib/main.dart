import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/session_service.dart';
import 'theme.dart';

void main() {
  runApp(const LungTumorDetectorApp());
}

class LungTumorDetectorApp extends StatelessWidget {
  const LungTumorDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lung Tumor Detector',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: const _AuthGate(),
    );
  }
}

/// Shows the login screen when there is no saved session,
/// otherwise the main app with bottom navigation.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    SessionService.isLoggedIn.then((value) {
      if (mounted) setState(() => _loggedIn = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn == null) {
      return const Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.mint),
        ),
      );
    }
    return _loggedIn! ? const MainScreen() : const LoginScreen();
  }
}
