import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme_notifier.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const WarehouseInventoryApp(),
    ),
  );
}

class WarehouseInventoryApp extends StatefulWidget {
  const WarehouseInventoryApp({super.key});

  @override
  State<WarehouseInventoryApp> createState() => _WarehouseInventoryAppState();
}

class _WarehouseInventoryAppState extends State<WarehouseInventoryApp> {
  @override
  void initState() {
    super.initState();
    context.read<ThemeNotifier>().loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Warehouse Inventory',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(
            useMaterial3: true,
          ),
          themeMode: themeNotifier.themeMode,
          debugShowCheckedModeBanner: false,
          home: const LoginScreen(),
        );
      },
    );
  }
}