import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ags_flutter_starter/main.dart';
import 'package:ags_flutter_starter/screens/add_expense_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PocketWise welcome screen renders', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BudgetTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('PocketWise'), findsOneWidget);
    expect(find.text('Enter App'), findsOneWidget);
  });

  testWidgets('blank expense title is rejected with a SnackBar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AddExpenseScreen()),
    );

    await tester.ensureVisible(find.text('Save Expense'));
    await tester.tap(find.text('Save Expense'));
    await tester.pump();

    expect(
      find.text('Please enter a valid Expense name!'),
      findsOneWidget,
    );
  });
}
