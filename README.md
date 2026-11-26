# PocketWise v0.4.0

PocketWise is a Flutter personal-finance tracker. Version 0.4.0 continues from the newer v0.3.6 project instead of replacing its account, database, profile, and existing screen implementations with the older partial v0.4.0 upgrade archive.

## What's included

### Existing functionality preserved from v0.3.6

- Local account registration and login.
- Separate account data stored in a local Sembast database.
- Salted PBKDF2-HMAC-SHA256 password hashes.
- One-time migration of eligible legacy SharedPreferences expense and budget data during account registration.
- Add and delete expense transactions.
- Monthly budget editing and expense history filtering.
- Profile-name updates, password changes, settings, support, and CSV export/share.
- Keyboard-safe forms and validation for empty descriptions and invalid amounts.

### New in v0.4.0

- **Account-specific category management:** add and remove categories from the Add Expense screen. Existing transactions keep their saved category even if a category is later removed from the selection list.
- **Category report filters:** choose exactly which categories are included in report calculations and charts.
- **Daily, weekly, monthly, and yearly reporting:** move between periods using the date navigation controls.
- **Weekly spending chart:** shows spending for each day from Monday through Sunday.
- **Monthly spending chart:** groups spending into week buckets (W1–W5).
- **Yearly spending chart:** compares spending month by month.
- **Monthly and yearly recaps:** compare spending with the saved monthly budget and the corresponding annual budget estimate.
- **Corrected monthly budget calculation:** dashboard and budget summaries compare the monthly budget with expenses from the current month, rather than all historical transactions.

## Important note about savings

The current data model records expenses and a monthly budget; it does not record income or separate savings deposits. Therefore, the recap labels the difference as **Unspent budget** (or **Over budget**), calculated as budget minus recorded expenses. It should not be interpreted as actual savings or verified income. An income/savings ledger would require a separate transaction type and is not silently fabricated in this version.

## Storage and account limitations

PocketWise uses Sembast as an embedded local database:

- Android and other native targets store `pocketwise.db` in the application's private documents directory.
- Flutter Web stores the database in browser IndexedDB.
- Account data is local to the device or browser profile. It does not automatically sync between Android and Chrome.
- There is no cloud account service or remote password recovery. Clearing browser site data or uninstalling the app can remove local data.
- The database is not encrypted as a whole. Passwords are hashed, but this is a learning-project implementation rather than a production identity system.

The 2FA setting remains a demonstration control; it displays a generated code but does not send or require it during login. The notification preference stores an in-app setting; it does not deliver background push notifications.

## Requirements

- Flutter SDK compatible with Dart 3.9 or later.
- Android Studio or VS Code with Flutter extensions.

## Run

From the project root:

```bash
flutter pub get
flutter run
```

For Chrome:

```bash
flutter run -d chrome --web-port 5000
```

## Test and analyze

```bash
flutter analyze
flutter test
```

Run the application on both Android and Chrome after dependency resolution. Flutter/Dart SDK tooling is required to execute these checks.

## Versioning

The package version is `0.4.0+4` (Android build number 4, above the previous v0.3.6 build number 3). The Android application ID and database filename remain unchanged from the v0.3.6 base so a normal in-place app update can retain local data. The original `v0.3.0-beta` school-assignment tag should remain unchanged if already published. Once the new version has been tested, create a separate `v0.4.0` Git tag.
