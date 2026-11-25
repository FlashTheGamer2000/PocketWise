import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../widgets/expense_chart.dart';

class ReportScreen extends StatelessWidget {
  final List<Expense> expenses;
  final double monthlyBudget;

  const ReportScreen({
    super.key,
    required this.expenses,
    required this.monthlyBudget,
  });

  double get _totalSpent {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _remainingBalance {
    return monthlyBudget - _totalSpent;
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Expenses Chart:',

              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            ExpenseChart(expenses: expenses),

            const SizedBox(height: 24),

            const Text(
              'Monthly Overview',

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 12),

            _ReportCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Monthly Budget',
              value: _formatCurrency(monthlyBudget),
              color: const Color(0xFF0D9488),
            ),

            _ReportCard(
              icon: Icons.trending_down,
              title: 'Total Spent',
              value: _formatCurrency(_totalSpent),
              color: Colors.red,
            ),

            _ReportCard(
              icon: Icons.account_balance,
              title: 'Remaining Balance',
              value: _formatCurrency(_remainingBalance),
              color: _remainingBalance < 0
                  ? Colors.red
                  : const Color(0xFF16A34A),
            ),

            _ReportCard(
              icon: Icons.receipt_long,
              title: 'Total Transactions',
              value: '${expenses.length}',
              color: const Color(0xFF1E293B),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),

      child: ListTile(
        leading: Icon(icon, color: color),

        title: Text(title),

        trailing: Text(
          value,

          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
      ),
    );
  }
}
