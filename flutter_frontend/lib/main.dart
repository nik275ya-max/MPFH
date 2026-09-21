import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/license_screen.dart';
import 'services/license_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.init();
  runApp(const MpfhApp());
}

class MpfhApp extends StatelessWidget {
  const MpfhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MPFH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C2BD9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0A1E),
      ),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _licensed = false;

  @override
  void initState() {
    super.initState();
    _licensed = LicenseService.instance.isValidStored();
  }

  void _onLicensedChanged(bool licensed) {
    setState(() => _licensed = licensed);
  }

  @override
  Widget build(BuildContext context) {
    if (!_licensed) {
      return LicenseScreen(
        onLicensed: () => _onLicensedChanged(true),
      );
    }
    return HomeScreen(
      onLicenseLost: () => _onLicensedChanged(false),
    );
  }
}