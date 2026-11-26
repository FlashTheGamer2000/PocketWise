import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart' as sembast_io;
import 'package:sembast_web/sembast_web.dart' as sembast_web;

import '../models/expense.dart';

class PocketWiseAccount {
  final String accountKey;
  final String displayName;

  const PocketWiseAccount({
    required this.accountKey,
    required this.displayName,
  });
}

class ProfileSettings {
  final bool twoFactorEnabled;
  final bool notificationsEnabled;

  const ProfileSettings({
    this.twoFactorEnabled = false,
    this.notificationsEnabled = true,
  });

  factory ProfileSettings.fromMap(Map<String, Object?> data) {
    return ProfileSettings(
      twoFactorEnabled: data['twoFactorEnabled'] as bool? ?? false,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
    );
  }
}

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String _databaseName = 'pocketwise.db';

  static const double defaultMonthlyBudget = 1000000.0;

  static const List<String> defaultCategories = <String>[
    'Food',
    'Transport',
    'Study',
    'Shopping',
    'Bills',
    'Other',
  ];

  final StoreRef<String, Map<String, Object?>> _users = stringMapStoreFactory
      .store('users');

  final StoreRef<String, Map<String, Object?>> _expenses = stringMapStoreFactory
      .store('expenses');

  Database? _database;

  final Pbkdf2 _passwordHasher = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 120000,
    bits: 256,
  );

  Future<Database> get _db async {
    if (_database != null) return _database!;

    if (kIsWeb) {
      _database = await sembast_web.databaseFactoryWeb.openDatabase(
        _databaseName,
      );
    } else {
      final directory = await getApplicationDocumentsDirectory();

      await directory.create(recursive: true);

      final databasePath = p.join(directory.path, _databaseName);

      _database = await sembast_io.databaseFactoryIo.openDatabase(databasePath);
    }

    return _database!;
  }

  String accountKeyFor(String accountName) {
    return accountName.trim().toLowerCase();
  }

  List<int> _newSalt() {
    final random = Random.secure();

    return List<int>.generate(16, (_) => random.nextInt(256));
  }

  Future<List<int>> _hashPassword(String password, List<int> salt) async {
    final secretKey = await _passwordHasher.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    return await secretKey.extractBytes();
  }

  bool _constantTimeEquals(List<int> first, List<int> second) {
    if (first.length != second.length) return false;

    var difference = 0;

    for (var i = 0; i < first.length; i++) {
      difference |= first[i] ^ second[i];
    }

    return difference == 0;
  }

  // CHECK WHETHER AN ACCOUNT EXISTS

  Future<bool> accountExists(String accountName) async {
    final key = accountKeyFor(accountName);

    if (key.isEmpty) return false;

    final db = await _db;

    return await _users.record(key).get(db) != null;
  }

  // CREATE ACCOUNT

  Future<String?> createAccount({
    required String accountName,
    required String password,
  }) async {
    final displayName = accountName.trim();

    final key = accountKeyFor(displayName);

    if (displayName.isEmpty) {
      throw ArgumentError('Account name cannot be empty.');
    }

    if (password.length < 8) {
      throw ArgumentError('Password must contain at least 8 characters.');
    }

    final salt = _newSalt();

    final passwordHash = await _hashPassword(password, salt);

    final db = await _db;

    var alreadyExists = false;

    await db.transaction((transaction) async {
      final existing = await _users.record(key).get(transaction);

      if (existing != null) {
        alreadyExists = true;
        return;
      }

      await _users.record(key).put(transaction, <String, Object?>{
        'displayName': displayName,
        'passwordSalt': base64Encode(salt),
        'passwordHash': base64Encode(passwordHash),
        'monthlyBudget': defaultMonthlyBudget,
        'twoFactorEnabled': false,
        'notificationsEnabled': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
    });

    return alreadyExists ? null : key;
  }

  // VERIFY PASSWORD

  Future<bool> _verifyPasswordRecord(
    Map<String, Object?> user,
    String password,
  ) async {
    final saltValue = user['passwordSalt'];
    final hashValue = user['passwordHash'];

    if (saltValue is! String || hashValue is! String) {
      return false;
    }

    final salt = base64Decode(saltValue);
    final savedHash = base64Decode(hashValue);

    final enteredHash = await _hashPassword(password, salt);

    return _constantTimeEquals(savedHash, enteredHash);
  }

  // LOGIN AUTHENTICATION

  Future<PocketWiseAccount?> authenticate({
    required String accountName,
    required String password,
  }) async {
    final key = accountKeyFor(accountName);

    if (key.isEmpty || password.isEmpty) {
      return null;
    }

    final db = await _db;

    final user = await _users.record(key).get(db);

    if (user == null) return null;

    final valid = await _verifyPasswordRecord(user, password);

    if (!valid) return null;

    return PocketWiseAccount(
      accountKey: key,
      displayName: user['displayName'] as String? ?? accountName.trim(),
    );
  }

  // VERIFY CURRENT PASSWORD

  Future<bool> verifyPassword(String accountKey, String password) async {
    final db = await _db;

    final user = await _users.record(accountKey).get(db);

    if (user == null) return false;

    return _verifyPasswordRecord(user, password);
  }

  // CHANGE PASSWORD

  Future<bool> changePassword({
    required String accountKey,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      throw ArgumentError('New password must contain at least 8 characters.');
    }

    final db = await _db;

    final user = await _users.record(accountKey).get(db);

    if (user == null || !await _verifyPasswordRecord(user, currentPassword)) {
      return false;
    }

    final salt = _newSalt();

    final hash = await _hashPassword(newPassword, salt);

    final updated = Map<String, Object?>.from(user)
      ..['passwordSalt'] = base64Encode(salt)
      ..['passwordHash'] = base64Encode(hash);

    await _users.record(accountKey).put(db, updated);

    return true;
  }

  // UPDATE DISPLAY NAME

  Future<void> updateDisplayName(String accountKey, String newName) async {
    final db = await _db;

    final user = await _users.record(accountKey).get(db);

    if (user == null) {
      throw StateError('Account no longer exists.');
    }

    final updated = Map<String, Object?>.from(user)
      ..['displayName'] = newName.trim();

    await _users.record(accountKey).put(db, updated);
  }

  // LOAD MONTHLY BUDGET

  Future<double> loadMonthlyBudget(String accountKey) async {
    final db = await _db;

    final user = await _users.record(accountKey).get(db);

    final value = user?['monthlyBudget'];

    return value is num ? value.toDouble() : defaultMonthlyBudget;
  }

  // SAVE MONTHLY BUDGET

  Future<void> saveMonthlyBudget(String accountKey, double amount) async {
    if (amount < 0 || !amount.isFinite) {
      throw ArgumentError('Invalid budget amount.');
    }

    final db = await _db;

    final user = await _users.record(accountKey).get(db);

    if (user == null) {
      throw StateError('Account no longer exists.');
    }

    final updated = Map<String, Object?>.from(user)..['monthlyBudget'] = amount;

    await _users.record(accountKey).put(db, updated);
  }

  // LOAD CUSTOM EXPENSE CATEGORIES FOR A PARTICULAR ACCOUNT.
  // Existing accounts without a saved list automatically receive the defaults.
  Future<List<String>> loadCategories(String accountKey) async {
    final db = await _db;
    final user = await _users.record(accountKey).get(db);
    final stored = user?['expenseCategories'];

    if (stored is List) {
      final cleaned = stored
          .whereType<String>()
          .map((category) => category.trim())
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (cleaned.isNotEmpty) return cleaned;
    }

    return List<String>.from(defaultCategories);
  }

  // SAVE CATEGORY SETTINGS ON THE ACCOUNT RECORD.
  Future<void> saveCategories(
    String accountKey,
    List<String> categories,
  ) async {
    final cleaned = <String>[];
    final seen = <String>{};

    for (final rawCategory in categories) {
      final category = rawCategory.trim();
      if (category.isEmpty || !seen.add(category.toLowerCase())) continue;
      cleaned.add(category);
    }

    if (cleaned.isEmpty) {
      throw ArgumentError('At least one expense category is required.');
    }
    if (cleaned.length > 30) {
      throw ArgumentError('You can create up to 30 expense categories.');
    }

    final db = await _db;
    final user = await _users.record(accountKey).get(db);
    if (user == null) throw StateError('Account no longer exists.');

    final updated = Map<String, Object?>.from(user)
      ..['expenseCategories'] = cleaned;
    await _users.record(accountKey).put(db, updated);
  }

  // LOAD EXPENSES FOR A PARTICULAR ACCOUNT

  Future<List<Expense>> loadExpenses(String accountKey) async {
    final db = await _db;

    final records = await _expenses.find(
      db,
      finder: Finder(
        filter: Filter.equals('accountKey', accountKey),
        sortOrders: [SortOrder('date', false)],
      ),
    );

    return records
        .map((record) => Expense.fromMap(record.value))
        .toList(growable: true);
  }

  // SAVE EXPENSE

  Future<void> saveExpense(String accountKey, Expense expense) async {
    final db = await _db;

    await _expenses.record(expense.id).put(db, <String, Object?>{
      ...expense.toMap(),
      'accountKey': accountKey,
    });
  }

  // DELETE EXPENSE

  Future<void> deleteExpense(String accountKey, String expenseId) async {
    final db = await _db;

    final record = await _expenses.record(expenseId).get(db);

    if (record != null && record['accountKey'] == accountKey) {
      await _expenses.record(expenseId).delete(db);
    }
  }

  // LOAD PROFILE SETTINGS

  Future<ProfileSettings> loadProfileSettings(String accountKey) async {
    final db = await _db;

    final user = await _users.record(accountKey).get(db);

    if (user == null) {
      return const ProfileSettings();
    }

    return ProfileSettings.fromMap(user);
  }

  // SAVE PROFILE SETTINGS

  Future<void> saveProfileSetting({
    required String accountKey,
    required String settingKey,
    required bool value,
  }) async {
    const allowedKeys = {'twoFactorEnabled', 'notificationsEnabled'};

    if (!allowedKeys.contains(settingKey)) {
      throw ArgumentError('Unknown profile setting.');
    }

    final db = await _db;

    final user = await _users.record(accountKey).get(db);

    if (user == null) {
      throw StateError('Account no longer exists.');
    }

    final updated = Map<String, Object?>.from(user)..[settingKey] = value;

    await _users.record(accountKey).put(db, updated);
  }
}
