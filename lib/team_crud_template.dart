import 'package:flutter/material.dart';

// ============================================================================
// POCKETWISE CUSTOMIZATION ZONE (Sprint 3 / Weeks 16-17)
// These are the six team-specific values requested in the assignment guide.
// The app keeps its existing modular screens instead of replacing them with a
// simplified classroom CRUD demo.
// ============================================================================

/// 1. App name shown in the welcome screen and app bar.
const String appTitle = 'Pocket Wise';

/// 2. The kind of item this app manages.
const String itemNoun = 'Expense';

/// 3. Hint text shown in the add-expense input field.
const String inputHintText = 'Enter an expense description...';

/// 4. Icon displayed beside each expense in the transaction list.
const IconData itemIcon = Icons.attach_money;

/// 5. PocketWise accent color.
const Color themeColor = Color.fromARGB(255, 0, 0, 0);

/// 6. PocketWise category chips.
const List<String> itemCategories = [
  'Food',
  'Transport',
  'Study',
  'Shopping',
  'Bills',
  'Other',
];

// Architecture mapping for this existing project:
// Tier 1 - WelcomeScreen: lib/screens/welcome_screen.dart
// Tier 2 - DashboardScreen: lib/screens/dashboard_screen.dart
// The dashboard retains expense CRUD, reports, budgets, and profile screens.
