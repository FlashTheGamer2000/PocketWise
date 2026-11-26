import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/database_service.dart';
import '../team_crud_template.dart';
import '../widgets/expense_chart.dart';

import 'add_expense_screen.dart' as add_expense;
import 'budget_screen.dart' as budget;
import 'report_screen.dart' as report;
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String accountKey;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.accountKey,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  bool _isLoading = true;

  late String _userName;

  double _monthlyBudget = DatabaseService.defaultMonthlyBudget;

  final double _savingsGoal = 500000.00;

  List<Expense> _expenses = [];

  List<String> _categories = List<String>.from(itemCategories);

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _userName = widget.userName;

    _scrollController = ScrollController();

    _loadStoredData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // LOAD DATA BELONGING TO THE LOGGED-IN ACCOUNT

  Future<void> _loadStoredData() async {
    try {
      final database = DatabaseService.instance;

      final loadedExpenses = await database.loadExpenses(widget.accountKey);

      final loadedBudget = await database.loadMonthlyBudget(widget.accountKey);
      final loadedCategories = await database.loadCategories(widget.accountKey);

      if (!mounted) return;

      setState(() {
        _expenses = loadedExpenses;
        _monthlyBudget = loadedBudget;
        _categories = loadedCategories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not load your saved data. Please restart PocketWise.',
          ),
        ),
      );
    }
  }

  double get _totalSpent {
    final now = DateTime.now();
    return _expenses
        .where((item) => item.date.year == now.year && item.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _remainingBalance {
    return _monthlyBudget - _totalSpent;
  }

  // UPDATE PROFILE NAME

  Future<void> _updateUserName(String newName) async {
    await DatabaseService.instance.updateDisplayName(
      widget.accountKey,
      newName,
    );

    if (!mounted) return;

    setState(() {
      _userName = newName;
    });
  }

  // UPDATE MONTHLY BUDGET

  Future<void> _updateMonthlyBudget(double newBudget) async {
    await DatabaseService.instance.saveMonthlyBudget(
      widget.accountKey,
      newBudget,
    );

    if (!mounted) return;

    setState(() {
      _monthlyBudget = newBudget;
    });
  }

  // SAVE ACCOUNT-SPECIFIC CATEGORY CUSTOMIZATION

  Future<void> _saveCategories(List<String> categories) async {
    await DatabaseService.instance.saveCategories(widget.accountKey, categories);
    if (!mounted) return;
    setState(() => _categories = List<String>.from(categories));
  }

  // ADD EXPENSE

  Future<void> _openAddExpenseScreen() async {
    final Expense? newExpense = await Navigator.of(context).push<Expense>(
      MaterialPageRoute(
        builder: (_) => add_expense.AddExpenseScreen(
          categories: _categories,
          onCategoriesChanged: _saveCategories,
        ),
      ),
    );

    if (newExpense == null) return;

    await DatabaseService.instance.saveExpense(widget.accountKey, newExpense);

    if (!mounted) return;

    setState(() {
      _expenses.insert(0, newExpense);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${itemNoun.toLowerCase()} "${newExpense.title}" successfully!',
        ),
      ),
    );
  }

  // DELETE EXPENSE

  Future<void> _deleteExpense(String id) async {
    await DatabaseService.instance.deleteExpense(widget.accountKey, id);

    if (!mounted) return;

    setState(() {
      _expenses.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),

        body: Center(child: CircularProgressIndicator(color: themeColor)),
      );
    }

    // MAIN APPLICATION SCREENS

    final List<Widget> screens = [
      _buildHomeDashboardView(),

      report.ReportScreen(
        expenses: _expenses,
        monthlyBudget: _monthlyBudget,
        categories: _categories,
      ),

      budget.BudgetScreen(
        expenses: _expenses,
        monthlyBudget: _monthlyBudget,
        onUpdateBudget: _updateMonthlyBudget,
        onDeleteExpense: _deleteExpense,
        categories: _categories,
      ),

      ProfileScreen(
        userName: _userName,
        accountKey: widget.accountKey,
        expenses: _expenses,
        monthlyBudget: _monthlyBudget,
        onUpdateUserName: _updateUserName,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      appBar: AppBar(
        title: const Text(
          appTitle,

          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),

        backgroundColor: themeColor,

        elevation: 0,

        automaticallyImplyLeading: false,
      ),

      body: IndexedStack(index: _selectedIndex, children: screens),

      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 2
          ? FloatingActionButton(
              onPressed: _openAddExpenseScreen,

              backgroundColor: themeColor,

              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,

      // BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,

        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,

        backgroundColor: Colors.white,

        selectedItemColor: themeColor,

        unselectedItemColor: Colors.grey,

        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),

          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Report',
          ),

          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _expenses.isNotEmpty,
              label: Text('${_expenses.length}'),
              child: const Icon(Icons.account_balance_wallet),
            ),

            label: 'Budget',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // HOME DASHBOARD

  Widget _buildHomeDashboardView() {
    return SingleChildScrollView(
      controller: _scrollController,

      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // USER PROFILE CARD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,

                  backgroundColor: themeColor,

                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 14),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      _userName,

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 2),

                    const Text(
                      'Active User Profile',

                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Expense Overview:',

            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          ExpenseChart(expenses: _expenses),

          const SizedBox(height: 20),

          const Text(
            'Monthly budget left:',

            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          // REMAINING BALANCE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Remaining Balance',

                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),

                Text(
                  'Rp ${_remainingBalance.toStringAsFixed(2).replaceAll('.', ',')}',

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,

                    color: _remainingBalance < 0
                        ? Colors.red
                        : const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Savings Goal:',

            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          // SAVINGS GOAL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Text(
                  'Target Goal',

                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),

                Text(
                  'Rp ${_savingsGoal.toStringAsFixed(2).replaceAll('.', ',')}',

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // NAVIGATE TO BUDGET RECORDS
          InkWell(
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
            },

            borderRadius: BorderRadius.circular(10),

            child: Container(
              width: double.infinity,

              padding: const EdgeInsets.symmetric(vertical: 16),

              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(10),
              ),

              child: const Center(
                child: Text(
                  'Expenditure Records',

                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
