# PocketWise - Personal Budget Tracker

PocketWise is a Flutter application for recording personal expenses and keeping track of a monthly budget. It is the team's customized app for the AGS Mobile App Development Sprint 3 milestone.

## Features

- Local profile name persistence with `shared_preferences`.
- Add and delete expense records.
- Categorize expenses with Material 3 `ChoiceChip` controls.
- Choose an expense date with Flutter's date picker.
- Display formatted transaction dates using `intl`.
- Set a monthly budget and review spending reports.
- Keep the existing dashboard, reports, budget, and profile screens.

## Requirements

- Flutter SDK (Dart SDK 3 or later)
- Android Studio or VS Code with Flutter extensions

## Setup

From the project root, run:

```bash
flutter pub get
flutter run
```

The Week 16-17 assignment command is also supported:

```bash
flutter pub add shared_preferences intl
```

## Sprint 3 Customization

The six team-specific values are in `lib/team_crud_template.dart`:

- `appTitle`: PocketWise
- `itemNoun`: Expense
- `inputHintText`: expense description prompt
- `itemIcon`: expense list icon
- `themeColor`: PocketWise teal accent
- `itemCategories`: Food, Transport, Study, Shopping, Bills, Other

The project keeps its existing modular structure. `WelcomeScreen` is the Tier 1 login gate in `lib/screens/welcome_screen.dart`; `DashboardScreen` is Tier 2 in `lib/screens/dashboard_screen.dart`. The reusable category chart lives in `lib/widgets/expense_chart.dart`. The dashboard continues to connect the existing expense CRUD, report, budget, and profile screens.

## Defensive checks

- Welcome, registration, and add-expense forms use scrollable layouts for keyboard safety.
- Empty expense titles show a SnackBar and are not saved.
- Invalid or non-positive amounts are rejected.
- An intentionally empty saved expense list stays empty after restart.

## Beta release

The app version is `0.3.0-beta+3`. After testing the Android and Chrome builds:

```bash
git add .
git commit -m "feat(sprint-3): finalize PocketWise beta polish"
git tag v0.3.0-beta
git push origin --tags
```

## Tests

```bash
flutter test
flutter analyze
```
