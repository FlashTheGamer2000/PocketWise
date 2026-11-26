import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../team_crud_template.dart';
import '../widgets/period_spending_chart.dart';

class ReportScreen extends StatefulWidget {
  final List<Expense> expenses;
  final double monthlyBudget;
  final List<String> categories;

  const ReportScreen({
    super.key,
    required this.expenses,
    required this.monthlyBudget,
    this.categories = itemCategories,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const List<String> _periods = <String>[
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  String _selectedPeriod = 'Monthly';
  DateTime _anchorDate = DateTime.now();
  final Set<String> _excludedCategories = <String>{};

  List<String> get _allCategories {
    final values = <String>{
      ...widget.categories,
      ...widget.expenses.map((expense) => expense.category),
    };
    final result = values.where((value) => value.trim().isNotEmpty).toList()
      ..sort();
    return result;
  }

  DateTime get _rangeStart {
    switch (_selectedPeriod) {
      case 'Daily':
        return DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);
      case 'Weekly':
        final day = DateTime(
          _anchorDate.year,
          _anchorDate.month,
          _anchorDate.day,
        );
        return day.subtract(Duration(days: day.weekday - DateTime.monday));
      case 'Yearly':
        return DateTime(_anchorDate.year);
      case 'Monthly':
      default:
        return DateTime(_anchorDate.year, _anchorDate.month);
    }
  }

  DateTime get _rangeEnd {
    switch (_selectedPeriod) {
      case 'Daily':
        return _rangeStart.add(const Duration(days: 1));
      case 'Weekly':
        return _rangeStart.add(const Duration(days: 7));
      case 'Yearly':
        return DateTime(_anchorDate.year + 1);
      case 'Monthly':
      default:
        return DateTime(_anchorDate.year, _anchorDate.month + 1);
    }
  }

  List<Expense> _expensesInRange(
    DateTime start,
    DateTime end, {
    bool applyCategoryFilter = true,
  }) {
    return widget.expenses.where((expense) {
      final date = expense.date;
      final inRange = !date.isBefore(start) && date.isBefore(end);
      final categoryIncluded =
          !applyCategoryFilter || !_excludedCategories.contains(expense.category);
      return inRange && categoryIncluded;
    }).toList();
  }

  List<Expense> get _periodExpenses =>
      _expensesInRange(_rangeStart, _rangeEnd);

  // Budget recaps always use every category so category filtering does not
  // make the remaining-budget figure look larger than it really is.
  List<Expense> get _monthExpenses => _expensesInRange(
        DateTime(_anchorDate.year, _anchorDate.month),
        DateTime(_anchorDate.year, _anchorDate.month + 1),
        applyCategoryFilter: false,
      );

  List<Expense> get _yearExpenses => _expensesInRange(
        DateTime(_anchorDate.year),
        DateTime(_anchorDate.year + 1),
        applyCategoryFilter: false,
      );

  double _total(List<Expense> expenses) =>
      expenses.fold(0.0, (sum, expense) => sum + expense.amount);

  String _formatCurrency(double amount) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(amount);

  String get _rangeLabel {
    switch (_selectedPeriod) {
      case 'Daily':
        return DateFormat('EEEE, d MMM yyyy').format(_anchorDate);
      case 'Weekly':
        final lastDay = _rangeEnd.subtract(const Duration(days: 1));
        return '${DateFormat('d MMM').format(_rangeStart)} – ${DateFormat('d MMM yyyy').format(lastDay)}';
      case 'Yearly':
        return '${_anchorDate.year}';
      case 'Monthly':
      default:
        return DateFormat('MMMM yyyy').format(_anchorDate);
    }
  }

  void _changePeriod(int amount) {
    setState(() {
      switch (_selectedPeriod) {
        case 'Daily':
          _anchorDate = _anchorDate.add(Duration(days: amount));
          break;
        case 'Weekly':
          _anchorDate = _anchorDate.add(Duration(days: amount * 7));
          break;
        case 'Yearly':
          _anchorDate = DateTime(_anchorDate.year + amount, _anchorDate.month, 1);
          break;
        case 'Monthly':
        default:
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + amount, 1);
          break;
      }
    });
  }

  Future<void> _showCategoryFilter() async {
    final categories = _allCategories;
    if (categories.isEmpty) return;

    final selected = categories
        .where((category) => !_excludedCategories.contains(category))
        .toSet();

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Categories to include'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => setDialogState(() {
                          selected.addAll(categories);
                        }),
                        child: const Text('Select all'),
                      ),
                      TextButton(
                        onPressed: () => setDialogState(selected.clear),
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 330),
                  child: SingleChildScrollView(
                    child: Column(
                      children: categories.map((category) {
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: selected.contains(category),
                          title: Text(category),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (checked) => setDialogState(() {
                            if (checked == true) {
                              selected.add(category);
                            } else {
                              selected.remove(category);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _excludedCategories
        ..clear()
        ..addAll(categories.where((category) => !result.contains(category)));
    });
  }

  List<SpendingBucket> _buildBuckets() {
    final expenses = _periodExpenses;
    final buckets = <SpendingBucket>[];

    if (_selectedPeriod == 'Daily') {
      buckets.add(
        SpendingBucket(
          label: DateFormat('d MMM').format(_anchorDate),
          amount: _total(expenses),
        ),
      );
      return buckets;
    }

    if (_selectedPeriod == 'Weekly') {
      const labels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (var day = 0; day < 7; day++) {
        final date = _rangeStart.add(Duration(days: day));
        final amount = _total(
          expenses.where((expense) => _sameDay(expense.date, date)).toList(),
        );
        buckets.add(SpendingBucket(label: labels[day], amount: amount));
      }
      return buckets;
    }

    if (_selectedPeriod == 'Monthly') {
      final daysInMonth = DateTime(
        _anchorDate.year,
        _anchorDate.month + 1,
        0,
      ).day;
      final weekCount = ((daysInMonth - 1) ~/ 7) + 1;
      for (var week = 0; week < weekCount; week++) {
        final startDay = week * 7 + 1;
        final endDay = (startDay + 7).clamp(1, daysInMonth + 1).toInt();
        final amount = _total(
          expenses.where((expense) {
            return expense.date.day >= startDay && expense.date.day < endDay;
          }).toList(),
        );
        buckets.add(
          SpendingBucket(label: 'W${week + 1}', amount: amount),
        );
      }
      return buckets;
    }

    for (var month = 1; month <= 12; month++) {
      final amount = _total(
        expenses.where((expense) => expense.date.month == month).toList(),
      );
      buckets.add(
        SpendingBucket(
          label: DateFormat('MMM').format(DateTime(_anchorDate.year, month)),
          amount: amount,
        ),
      );
    }
    return buckets;
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: color.withValues(alpha: 0.10),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recapCard({
    required String title,
    required String period,
    required double budget,
    required double spent,
    String budgetLabel = 'Budget',
  }) {
    final left = budget - spent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 3),
          Text(period, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          _recapLine(budgetLabel, _formatCurrency(budget)),
          const SizedBox(height: 8),
          _recapLine('Spent', _formatCurrency(spent), valueColor: const Color(0xFFDC2626)),
          const Divider(height: 22),
          _recapLine(
            left >= 0 ? 'Unspent budget' : 'Over budget',
            _formatCurrency(left.abs()),
            valueColor: left >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _recapLine(
    String label,
    String value, {
    Color? valueColor,
    bool emphasized = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final periodExpenses = _periodExpenses;
    final periodSpent = _total(periodExpenses);
    final monthSpent = _total(_monthExpenses);
    final yearSpent = _total(_yearExpenses);
    final includedCount = _allCategories.length -
        _allCategories.where(_excludedCategories.contains).length;

    final categoryTotals = <String, double>{};
    for (final expense in periodExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    final sortedCategoryTotals = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Spending Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Explore your expenses across different time periods.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _periods.map((period) {
                  final selected = _selectedPeriod == period;
                  return ChoiceChip(
                    label: Text(period),
                    selected: selected,
                    selectedColor: themeColor,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _selectedPeriod = period),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous period',
                    onPressed: () => _changePeriod(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _rangeLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next period',
                    onPressed: _rangeStart.isAfter(DateTime.now())
                        ? null
                        : () => _changePeriod(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _anchorDate = DateTime.now()),
                    icon: const Icon(Icons.today, size: 17),
                    label: const Text('Today'),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _showCategoryFilter,
                    icon: const Icon(Icons.filter_list, size: 17),
                    label: Text('Categories $includedCount/${_allCategories.length}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PeriodSpendingChart(
                title: switch (_selectedPeriod) {
                  'Daily' => 'Spending for this day',
                  'Weekly' => 'Daily spending this week',
                  'Yearly' => 'Monthly spending this year',
                  _ => 'Weekly spending this month',
                },
                buckets: _buildBuckets(),
              ),
              const SizedBox(height: 16),
              _summaryCard(
                title: 'Total spending',
                value: _formatCurrency(periodSpent),
                icon: Icons.trending_down,
                color: const Color(0xFFDC2626),
                subtitle: '${periodExpenses.length} transactions in this period',
              ),
              const SizedBox(height: 10),
              _summaryCard(
                title: 'Average transaction',
                value: _formatCurrency(
                  periodExpenses.isEmpty ? 0 : periodSpent / periodExpenses.length,
                ),
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 22),
              const Text(
                'Category Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              if (sortedCategoryTotals.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'No transactions match this period and category selection.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                )
              else
                ...sortedCategoryTotals.map((entry) {
                  final share = periodSpent <= 0 ? 0.0 : entry.value / periodSpent;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              Text(
                                _formatCurrency(entry.value),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: share.clamp(0.0, 1.0).toDouble(),
                              minHeight: 7,
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: const Color(0xFF0D9488),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 22),
              const Text(
                'Monthly & Yearly Recap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Recaps include all categories. The yearly budget is estimated as the current monthly budget × 12. Unspent budget is not actual savings or income.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              _recapCard(
                title: 'Monthly recap',
                period: DateFormat('MMMM yyyy').format(_anchorDate),
                budget: widget.monthlyBudget,
                spent: monthSpent,
              ),
              const SizedBox(height: 10),
              _recapCard(
                title: 'Yearly recap',
                period: '${_anchorDate.year}',
                budget: widget.monthlyBudget * 12,
                spent: yearSpent,
                budgetLabel: 'Annual budget estimate',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
