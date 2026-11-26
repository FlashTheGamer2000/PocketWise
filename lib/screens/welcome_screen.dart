import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/database_service.dart';
import '../team_crud_template.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;

  bool _isLoggingIn = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _passwordController = TextEditingController();

    _prefillLastAccountName();
  }

  Future<void> _prefillLastAccountName() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName =
        prefs.getString('last_account_name') ?? prefs.getString('user_name');

    if (!mounted || savedName == null || savedName.isEmpty) {
      return;
    }

    setState(() {
      _nameController.text = savedName;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
    final accountName = _nameController.text.trim();
    final password = _passwordController.text;

    if (accountName.isEmpty || password.isEmpty) {
      _showMessage('Please enter your account name and password.');
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final database = DatabaseService.instance;

      // FIRST: Check whether the account exists.
      final exists = await database.accountExists(accountName);

      if (!exists) {
        if (mounted) {
          _showMessage('Account not found. Please create an account first.');
        }
        return;
      }

      // SECOND: Verify the password.
      final account = await database.authenticate(
        accountName: accountName,
        password: password,
      );

      if (account == null) {
        if (mounted) {
          _showMessage('Incorrect password. Please try again.');
        }
        return;
      }

      // THIRD: Save the last account name for convenience.
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('last_account_name', account.accountKey);

      if (!mounted) return;

      // FOURTH: Enter the dashboard.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            userName: account.displayName,
            accountKey: account.accountKey,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage('Could not sign in. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: themeColor,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const ClampingScrollPhysics(),

            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),

                    decoration: const BoxDecoration(
                      color: Color(0xFF334155),
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(itemIcon, size: 48, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  appTitle,
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Manage your daily budget with ease',
                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 14, color: Color(0xFFCBD5E1)),
                ),

                const SizedBox(height: 36),

                // ACCOUNT NAME
                TextField(
                  controller: _nameController,

                  textInputAction: TextInputAction.next,

                  style: const TextStyle(color: Colors.white),

                  decoration: InputDecoration(
                    hintText: 'Enter your account name',

                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),

                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF94A3B8),
                    ),

                    filled: true,

                    fillColor: const Color(0xFF334155).withValues(alpha: 0.4),

                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF475569)),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // PASSWORD
                TextField(
                  controller: _passwordController,

                  obscureText: _obscurePassword,

                  onSubmitted: (_) => _login(),

                  style: const TextStyle(color: Colors.white),

                  decoration: InputDecoration(
                    hintText: 'Enter your password',

                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),

                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF94A3B8),
                    ),

                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: const Color(0xFF94A3B8),
                      ),

                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),

                    filled: true,

                    fillColor: const Color(0xFF334155).withValues(alpha: 0.4),

                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF475569)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // LOGIN BUTTON
                SizedBox(
                  height: 52,

                  child: ElevatedButton(
                    onPressed: _isLoggingIn ? null : _login,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E293B),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),

                      elevation: 0,
                    ),

                    child: _isLoggingIn
                        ? const SizedBox(
                            width: 22,
                            height: 22,

                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Log In',

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 28),

                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFF475569))),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),

                      child: Text(
                        'NEW USER?',

                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Expanded(child: Divider(color: Color(0xFF475569))),
                  ],
                ),

                const SizedBox(height: 24),

                // SIGNUP BUTTON
                SizedBox(
                  height: 52,

                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },

                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,

                      side: const BorderSide(color: Colors.white, width: 1.5),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),

                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),

                    label: const Text(
                      'Create New Account (Sign Up)',

                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
