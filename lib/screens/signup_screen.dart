import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';
import '../services/database_service.dart';
import '../team_crud_template.dart';
import 'dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _isPasswordObscured = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ONE-TIME MIGRATION FROM WEEK 15

  Future<void> _migrateLegacyData(String accountKey) async {
    final prefs = await SharedPreferences.getInstance();

    const migrationKey = 'pocketwise_v04_legacy_migration_done';

    if (prefs.getBool(migrationKey) ?? false) {
      return;
    }

    final database = DatabaseService.instance;

    final rawExpenses = prefs.getStringList('expense_items');

    if (rawExpenses != null) {
      for (final rawExpense in rawExpenses) {
        try {
          final expense = Expense.fromJsonString(rawExpense);

          await database.saveExpense(accountKey, expense);
        } catch (_) {
          // Skip invalid old expense records.
        }
      }
    }

    final oldBudget = prefs.getDouble('monthly_budget');

    if (oldBudget != null && oldBudget >= 0) {
      await database.saveMonthlyBudget(accountKey, oldBudget);
    }

    await prefs.setBool(migrationKey, true);
  }

  // SIGNUP PROCESS

  Future<void> _signup() async {
    final fullName = _fullNameController.text.trim();

    final password = _passwordController.text;

    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    if (fullName.length < 3) {
      _showMessage('Account name must contain at least 3 characters.');
      return;
    }

    if (password.length < 8) {
      _showMessage('Use a password with at least 8 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // CREATE ACCOUNT IN DATABASE

      final accountKey = await DatabaseService.instance.createAccount(
        accountName: fullName,
        password: password,
      );

      if (accountKey == null) {
        if (mounted) {
          _showMessage(
            'That account name is already registered. Try logging in.',
          );
        }
        return;
      }

      // ATTEMPT OLD DATA MIGRATION

      try {
        await _migrateLegacyData(accountKey);
      } catch (_) {
        // The new account remains usable even if migration fails.
      }

      // SAVE LAST ACCOUNT NAME

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('last_account_name', accountKey);

      if (!mounted) return;

      // ENTER DASHBOARD

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              DashboardScreen(userName: fullName, accountKey: accountKey),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        _showMessage('Account registration failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text(
          'Create PocketWise Account',

          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: themeColor,

        iconTheme: const IconThemeData(color: Colors.white),

        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                'New User Registration',

                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Create a local account to keep your expenses separate.',

                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),

              const SizedBox(height: 28),

              // ACCOUNT NAME
              const Text(
                'Account Name',

                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _fullNameController,

                textCapitalization: TextCapitalization.words,

                textInputAction: TextInputAction.next,

                decoration: InputDecoration(
                  hintText: 'e.g. Alex Johnson',

                  prefixIcon: const Icon(Icons.person_outline),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // PASSWORD
              const Text(
                'Password',

                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _passwordController,

                obscureText: _isPasswordObscured,

                textInputAction: TextInputAction.next,

                decoration: InputDecoration(
                  hintText: 'At least 8 characters',

                  prefixIcon: const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),

                    onPressed: () {
                      setState(() {
                        _isPasswordObscured = !_isPasswordObscured;
                      });
                    },
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // CONFIRM PASSWORD
              const Text(
                'Confirm Password',

                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _confirmPasswordController,

                obscureText: true,

                onSubmitted: (_) => _signup(),

                decoration: InputDecoration(
                  hintText: 'Re-enter your password',

                  prefixIcon: const Icon(Icons.published_with_changes),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // REGISTER BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _signup,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),

                    elevation: 0,
                  ),

                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign Up Now',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },

                  child: const Text('Already have an account? Log in here'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
