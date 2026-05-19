import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'config/router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';

class CampusIQApp extends StatefulWidget {
  const CampusIQApp({super.key});

  @override
  State<CampusIQApp> createState() => _CampusIQAppState();
}

class _CampusIQAppState extends State<CampusIQApp> {
  final _storage = const FlutterSecureStorage();
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await _storage.read(key: 'dark_mode');
    if (isDark == 'true') {
      setState(() => _themeMode = ThemeMode.dark);
    }
  }

  void toggleTheme(bool dark) async {
    setState(() => _themeMode = dark ? ThemeMode.dark : ThemeMode.light);
    await _storage.write(key: 'dark_mode', value: dark.toString());
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      builder: (context, _) {
        final router = createRouter(context);
        return MaterialApp.router(
          title: 'CampusIQ',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
