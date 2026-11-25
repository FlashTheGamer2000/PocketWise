import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense.dart';
import '../services/database_service.dart';
import '../team_crud_template.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String accountKey;
  final List<Expense> expenses;
  final double monthlyBudget;

  final Future<void> Function(String newName) onUpdateUserName;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.accountKey,
    required this.expenses,
    required this.monthlyBudget,
    required this.onUpdateUserName,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileSettings _settings = const ProfileSettings();

  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // LOAD SAVED SETTINGS

  Future<void> _loadSettings() async {
    try {
      final settings = await DatabaseService.instance.loadProfileSettings(
        widget.accountKey,
      );

      if (!mounted) return;

      setState(() {
        _settings = settings;
        _settingsLoaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _settingsLoaded = true);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // SAVE PROFILE SETTINGS

  Future<bool> _saveSetting(String key, bool value) async {
    try {
      await DatabaseService.instance.saveProfileSetting(
        accountKey: widget.accountKey,
        settingKey: key,
        value: value,
      );

      return true;
    } catch (_) {
      if (mounted) {
        _showMessage('Could not save this setting.');
      }

      return false;
    }
  }

  // EDIT PROFILE NAME

  Future<void> _showEditNameDialog() async {
    final nameController = TextEditingController(text: widget.userName);

    final passwordController = TextEditingController();

    await showDialog<void>(
      context: context,

      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Edit Profile Name'),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TextField(
                controller: nameController,

                textCapitalization: TextCapitalization.words,

                decoration: const InputDecoration(
                  labelText: 'New display name',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,

                obscureText: true,

                decoration: const InputDecoration(
                  labelText: 'Current password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },

            child: const Text('Cancel'),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
            ),

            onPressed: () async {
              final newName = nameController.text.trim();

              final password = passwordController.text;

              if (newName.length < 3 || password.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter a valid name and your current password.',
                    ),
                  ),
                );
                return;
              }

              try {
                final valid = await DatabaseService.instance.verifyPassword(
                  widget.accountKey,
                  password,
                );

                if (!dialogContext.mounted) return;

                if (!valid) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Incorrect password.')),
                  );
                  return;
                }

                await widget.onUpdateUserName(newName);

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop();

                _showMessage('Profile name updated successfully.');
              } catch (_) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Could not update your profile.'),
                    ),
                  );
                }
              }
            },

            child: const Text('Verify & Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    passwordController.dispose();
  }

  // CHANGE PASSWORD

  Future<void> _showChangePasswordDialog() async {
    final oldPasswordController = TextEditingController();

    final newPasswordController = TextEditingController();

    final confirmPasswordController = TextEditingController();

    await showDialog<void>(
      context: context,

      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Change Password'),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,

                decoration: const InputDecoration(
                  labelText: 'Current password',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: newPasswordController,
                obscureText: true,

                decoration: const InputDecoration(
                  labelText: 'New password (8+ characters)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: confirmPasswordController,
                obscureText: true,

                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },

            child: const Text('Cancel'),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
            ),

            onPressed: () async {
              final currentPassword = oldPasswordController.text;

              final newPassword = newPasswordController.text;

              final confirmation = confirmPasswordController.text;

              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmation.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields.')),
                );
                return;
              }

              if (newPassword.length < 8) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'New password must contain at least 8 characters.',
                    ),
                  ),
                );
                return;
              }

              if (newPassword != confirmation) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match.')),
                );
                return;
              }

              try {
                final changed = await DatabaseService.instance.changePassword(
                  accountKey: widget.accountKey,
                  currentPassword: currentPassword,
                  newPassword: newPassword,
                );

                if (!dialogContext.mounted) return;

                if (!changed) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Current password is incorrect.'),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();

                _showMessage('Password updated successfully.');
              } catch (_) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Could not change your password.'),
                    ),
                  );
                }
              }
            },

            child: const Text('Change Password'),
          ),
        ],
      ),
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  // NOTIFICATIONS SWITCH

  Future<void> _toggleNotifications(bool enabled) async {
    final previous = _settings;

    setState(() {
      _settings = ProfileSettings(
        twoFactorEnabled: previous.twoFactorEnabled,
        notificationsEnabled: enabled,
      );
    });

    final saved = await _saveSetting('notificationsEnabled', enabled);

    if (!mounted) return;

    if (!saved) {
      setState(() {
        _settings = previous;
      });
      return;
    }

    _showMessage(
      enabled
          ? 'PocketWise in-app notifications have been turned on.'
          : 'PocketWise in-app notifications have been turned off.',
    );
  }

  // DEMONSTRATION 2FA SWITCH

  Future<void> _toggleTwoFactor(bool enabled) async {
    final previous = _settings;

    setState(() {
      _settings = ProfileSettings(
        twoFactorEnabled: enabled,
        notificationsEnabled: previous.notificationsEnabled,
      );
    });

    final saved = await _saveSetting('twoFactorEnabled', enabled);

    if (!mounted) return;

    if (!saved) {
      setState(() {
        _settings = previous;
      });
      return;
    }

    if (enabled) {
      _showDemoTwoFactorCode();
    } else {
      _showMessage('Demo two-factor verification has been turned off.');
    }
  }

  // GENERATE RANDOM SIX-DIGIT CODE

  void _showDemoTwoFactorCode() {
    final code = (100000 + Random.secure().nextInt(900000)).toString();

    showDialog<void>(
      context: context,

      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: themeColor),

            SizedBox(width: 10),

            Expanded(child: Text('Demo verification code')),
          ],
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Text(
              'Your randomly generated demonstration code is:',

              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            SelectableText(
              code,

              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: themeColor,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'This code is not sent anywhere and is not checked during login. '
              'The 2FA switch is a UI demonstration, not real account security.',

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },

            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // CSV EXPORT

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');

    return '"$escaped"';
  }

  Future<void> _exportMyData() async {
    final rows = <String>[
      'PocketWise Expense Export',

      'Account,${_csvCell(widget.userName)}',

      'Monthly Budget,${widget.monthlyBudget.toStringAsFixed(2)}',

      '',

      'Date,Description,Category,Amount (IDR)',
    ];

    for (final expense in widget.expenses) {
      rows.add(
        [
          DateFormat('yyyy-MM-dd').format(expense.date),
          _csvCell(expense.title),
          _csvCell(expense.category),
          expense.amount.toStringAsFixed(2),
        ].join(','),
      );
    }

    final csv = rows.join('\n');

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'PocketWise expense data',
          subject: 'PocketWise expense export',
          text: csv,
        ),
      );
    } catch (_) {
      // Clipboard fallback.

      try {
        await Clipboard.setData(ClipboardData(text: csv));

        if (mounted) {
          _showMessage('Sharing is unavailable here. CSV data copied instead.');
        }
      } catch (_) {
        if (mounted) {
          _showMessage('Could not export your data.');
        }
      }
    }
  }

  // MAIN PROFILE UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF1F5F9),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 12),

            // PROFILE CARD
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),

              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,

                    backgroundColor: themeColor,

                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.userName,

                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Local PocketWise Account',

                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Login ID: ${widget.accountKey}',

                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const _SectionTitle('Account Options'),

            _SettingsCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),

                  title: const Text('Edit Profile Name'),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: _showEditNameDialog,
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                ListTile(
                  leading: const Icon(Icons.lock_outline),

                  title: const Text('Change Password'),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: _showChangePasswordDialog,
                ),
              ],
            ),

            const SizedBox(height: 20),

            const _SectionTitle('Notifications'),

            _SettingsCard(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none),

                  title: const Text('App Notifications'),

                  subtitle: const Text(
                    'Toggle PocketWise in-app notification messages',
                  ),

                  value: _settings.notificationsEnabled,

                  activeThumbColor: themeColor,

                  onChanged: _settingsLoaded ? _toggleNotifications : null,
                ),
              ],
            ),

            const SizedBox(height: 20),

            const _SectionTitle('Security & Privacy'),

            _SettingsCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.share_outlined),

                  title: const Text('Export / Share My Data'),

                  subtitle: const Text(
                    'Share your expenses as CSV text with another app',
                  ),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: _exportMyData,
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                SwitchListTile(
                  secondary: const Icon(Icons.security),

                  title: const Text('Two-Factor Authentication (Demo)'),

                  subtitle: const Text(
                    'Generate a sample code; does not change login security',
                  ),

                  value: _settings.twoFactorEnabled,

                  activeThumbColor: themeColor,

                  onChanged: _settingsLoaded ? _toggleTwoFactor : null,
                ),
              ],
            ),

            const SizedBox(height: 20),

            const _SectionTitle('Support'),

            _SettingsCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),

                  title: const Text('Help & Support Page'),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 28),

            // LOGOUT
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/welcome', (route) => false);
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,

                  foregroundColor: Colors.white,

                  padding: const EdgeInsets.symmetric(vertical: 14),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                icon: const Icon(Icons.logout),

                label: const Text(
                  'Logout',

                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// SECTION TITLE

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Text(
        title,

        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

// SETTINGS CARD

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),

      child: Column(children: children),
    );
  }
}
