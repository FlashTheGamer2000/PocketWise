import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../team_crud_template.dart';

class BudgetScreen extends StatefulWidget {
  final List<Expense> expenses;
  final double monthlyBudget;
  final Future<void> Function(double newBudget) onUpdateBudget;
  final Future<void> Function(String id) onDeleteExpense;

  const BudgetScreen({
    super.key,
    required this.expenses,
    required this.monthlyBudget,
    required this.onUpdateBudget,
    required this.onDeleteExpense,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  String _selectedFilter = 'All';

  double get _totalSpent {
    return widget.expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _remainingBalance {
    return widget.monthlyBudget - _totalSpent;
  }

  List<Expense> get _filteredExpenses {
    if (_selectedFilter == 'All') {
      return widget.expenses;
    }
    return widget.expenses
        .where((expense) => expense.category == _selectedFilter)
        .toList();
  }

  String _formatCurrency(double amount) {
    return 'Rp ${NumberFormat('#,##0', 'id_ID').format(amount)}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _showEditBudgetDialog() async {
    final controller = TextEditingController(
      text: widget.monthlyBudget.toStringAsFixed(0),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Update Monthly Budget'),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Monthly Budget (Rp)',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final parsed = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );

              if (parsed == null || parsed <= 0 || !parsed.isFinite) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter a budget amount greater than zero.',
                    ),
                  ),
                );
                return;
              }

              await widget.onUpdateBudget(parsed);

              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              _showMessage(
                'Monthly budget updated to ${_formatCurrency(parsed)}.',
              );
            },
            child: const Text('Save Budget'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> _handleDelete(Expense expense) async {
    await widget.onDeleteExpense(expense.id);
    if (!mounted) return;
    _showMessage('Deleted "${expense.title}".');
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...itemCategories];
    final filtered = _filteredExpenses;
    final progress = widget.monthlyBudget > 0
        ? (_totalSpent / widget.monthlyBudget).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MONTHLY BUDGET SUMMARY CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly Budget',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showEditBudgetDialog,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                  Text(
                    _formatCurrency(widget.monthlyBudget),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: _remainingBalance < 0
                          ? Colors.red
                          : const Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Spent: ${_formatCurrency(_totalSpent)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Left: ${_formatCurrency(_remainingBalance)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _remainingBalance < 0
                              ? Colors.red
                              : const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // MATERIAL 3 CATEGORY FILTER CHIPS
            const Text(
              'Filter by Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final isSelected = _selectedFilter == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      showCheckmark: true,
                      selectedColor: themeColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : themeColor,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: themeColor.withValues(alpha: 0.35),
                      ),
                      onSelected: (selected) {
                        if (!selected) return;
                        setState(() {
                          _selectedFilter = category;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // EXPENSE RECORDS HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$itemNoun Records (${filtered.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // EXPENSE LIST
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(itemIcon, size: 36, color: const Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFilter == 'All'
                          ? 'No ${itemNoun.toLowerCase()}s recorded yet. Tap + to add one!'
                          : 'No ${itemNoun.toLowerCase()}s in "$_selectedFilter".',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final expense = filtered[index];
                  final formattedDate = DateFormat(
                    'dd MMM yyyy',
                  ).format(expense.date);

                  return Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: themeColor.withValues(alpha: 0.1),
                        child: Icon(
                          expense.categoryIcon,
                          color: themeColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        expense.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      subtitle: Text(
                        '${expense.category} • $formattedDate',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatCurrency(expense.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            tooltip: 'Delete $itemNoun',
                            onPressed: () => _handleDelete(expense),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
