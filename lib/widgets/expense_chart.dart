import 'package:flutter/material.dart';

import '../models/expense.dart';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  Map<String, double> get _categoryTotals {
    final Map<String, double> totals = {};

    for (final expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0.0) + expense.amount;
    }

    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _categoryTotals;

    if (expenses.isEmpty || totals.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,

        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),

        child: const Center(
          child: Text(
            'No expenditure data recorded yet',

            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    final maxAmount = totals.values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 160,
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,

        children: totals.entries.map((entry) {
          final ratio = maxAmount > 0 ? entry.value / maxAmount : 0.0;

          final barHeight = ratio * 75;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,

            children: [
              Text(
                'Rp ${(entry.value / 1000).toStringAsFixed(0)}k',

                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 6),

              AnimatedContainer(
                duration: const Duration(milliseconds: 300),

                width: 28,

                height: barHeight < 8 ? 8 : barHeight,

                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                entry.key,

                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
