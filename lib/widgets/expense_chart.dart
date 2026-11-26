import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0.0) + expense.amount;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _categoryTotals;

    if (totals.isEmpty) {
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

    final maxAmount = totals.values.fold<double>(
      0.0,
      (maximum, amount) => math.max(maximum, amount).toDouble(),
    );
    final viewportWidth = MediaQuery.sizeOf(context).width - 64;
    final chartWidth = math.max(viewportWidth, totals.length * 66.0).toDouble();
    final compactCurrency = NumberFormat.compact(locale: 'id_ID');

    return Container(
      height: 170,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: totals.entries.map((entry) {
              final ratio = maxAmount > 0 ? entry.value / maxAmount : 0.0;
              final barHeight = math.max(8.0, ratio * 78).toDouble();
              return SizedBox(
                width: 62,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 20,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Rp ${compactCurrency.format(entry.value)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 24,
                      child: Text(
                        entry.key,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
