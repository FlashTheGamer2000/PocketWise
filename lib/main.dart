import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'team_crud_template.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const BudgetTrackerApp());
}

class BudgetTrackerApp extends StatelessWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 0, 0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),

      home: const WelcomeScreen(),

      routes: {'/welcome': (context) => const WelcomeScreen()},
    );
  }
}
