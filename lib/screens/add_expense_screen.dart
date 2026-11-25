import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../team_crud_template.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _amountController = TextEditingController();

  String _selectedCategory = itemCategories.first;

  DateTime _selectedDate = DateTime.now();

  final bool _isSaving = false;

  // DATE PICKER

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,

      initialDate: _selectedDate,

      firstDate: DateTime(2000),

      lastDate: DateTime(2030, 12, 31),

      helpText: 'Select expense date',

      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: themeColor)),
          child: child!,
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedDate = selected;
      });
    }
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // SAVE EXPENSE

  void _submitData() {
    if (_isSaving) return;

    final title = _titleController.text.trim();

    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    if (title.isEmpty) {
      _showValidationMessage('Please enter a valid $itemNoun name!');
      return;
    }

    if (amount == null || amount <= 0 || !amount.isFinite) {
      _showValidationMessage('Please enter an amount greater than zero.');
      return;
    }

    final newExpense = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),

      title: title,

      amount: amount,

      category: _selectedCategory,

      date: _selectedDate,
    );

    Navigator.of(context).pop(newExpense);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy').format(_selectedDate);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: Text('$appTitle • Add $itemNoun'),

        backgroundColor: themeColor,

        foregroundColor: Colors.white,

        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

          // Scaffold resizes its body when the keyboard opens. Keep a
          // normal bottom inset here so the keyboard height is not counted twice.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              // EXPENSE DESCRIPTION
              TextField(
                controller: _titleController,

                textCapitalization: TextCapitalization.sentences,

                textInputAction: TextInputAction.next,

                decoration: InputDecoration(
                  labelText: '$itemNoun name',

                  hintText: inputHintText,

                  prefixIcon: Icon(itemIcon, color: themeColor),

                  border: const OutlineInputBorder(),

                  filled: true,

                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // EXPENSE AMOUNT
              TextField(
                controller: _amountController,

                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),

                textInputAction: TextInputAction.done,

                onSubmitted: (_) => _submitData(),

                decoration: InputDecoration(
                  labelText: 'Amount (Rp)',

                  prefixIcon: Icon(Icons.payments_outlined, color: themeColor),

                  border: const OutlineInputBorder(),

                  filled: true,

                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // CATEGORY SELECTION
              Text(
                'Category',

                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,

                children: itemCategories.map((category) {
                  final isSelected = _selectedCategory == category;

                  return ChoiceChip(
                    label: Text(category),

                    selected: isSelected,

                    showCheckmark: true,

                    selectedColor: themeColor,

                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : themeColor,

                      fontWeight: FontWeight.w600,
                    ),

                    side: BorderSide(color: themeColor.withValues(alpha: 0.35)),

                    onSelected: (selected) {
                      if (!selected) return;

                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // CALENDAR / DATE SELECTION
              Card(
                elevation: 0,

                color: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),

                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),

                child: ListTile(
                  leading: Icon(
                    Icons.calendar_month_outlined,
                    color: themeColor,
                  ),

                  title: const Text('Expense date'),

                  subtitle: Text(formattedDate),

                  trailing: TextButton(
                    onPressed: _pickDate,
                    child: const Text('Change'),
                  ),

                  onTap: _pickDate,
                ),
              ),

              const SizedBox(height: 24),

              // SAVE BUTTON
              SizedBox(
                height: 52,

                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitData,

                  icon: const Icon(Icons.save_outlined),

                  label: Text('Save $itemNoun'),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
