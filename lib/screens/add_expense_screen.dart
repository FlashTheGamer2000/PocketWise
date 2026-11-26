import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../team_crud_template.dart';

class AddExpenseScreen extends StatefulWidget {
  final List<String> categories;
  final Future<void> Function(List<String> categories)? onCategoriesChanged;

  const AddExpenseScreen({
    super.key,
    this.categories = itemCategories,
    this.onCategoriesChanged,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late List<String> _categories;
  late String _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _categories = _cleanCategories(widget.categories);
    _selectedCategory = _categories.first;
  }

  List<String> _cleanCategories(List<String> source) {
    final cleaned = source
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    return cleaned.isEmpty ? List<String>.from(itemCategories) : cleaned;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030, 12, 31),
      helpText: 'Select expense date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: themeColor),
        ),
        child: child!,
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedDate = selected);
    }
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _manageCategories() async {
    final controller = TextEditingController();
    final editedCategories = List<String>.from(_categories);

    final didSave = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              void addCategory() {
                final category = controller.text.trim();
                if (category.isEmpty) return;
                if (editedCategories.length >= 30) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('You can create up to 30 categories.'),
                    ),
                  );
                  return;
                }
                if (editedCategories.any(
                  (existing) =>
                      existing.toLowerCase() == category.toLowerCase(),
                )) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('That category already exists.'),
                    ),
                  );
                  return;
                }
                setDialogState(() {
                  editedCategories.add(category);
                  controller.clear();
                });
              }

              return AlertDialog(
                scrollable: true,
                title: const Text('Manage Categories'),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add categories you use. Removing a category only removes it from future selections; existing transactions keep their original category.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => addCategory(),
                              decoration: const InputDecoration(
                                labelText: 'New category',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Add category',
                            onPressed: addCategory,
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 230),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: editedCategories
                                .map(
                                  (category) => InputChip(
                                    label: Text(category),
                                    onDeleted: editedCategories.length <= 1
                                        ? null
                                        : () => setDialogState(
                                              () => editedCategories.remove(category),
                                            ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${editedCategories.length}/30 categories',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Categories'),
                  ),
                ],
              );
            },
          ),
        ) ??
        false;

    controller.dispose();
    if (!didSave || !mounted) return;

    try {
      final updated = _cleanCategories(editedCategories);
      await widget.onCategoriesChanged?.call(updated);
      if (!mounted) return;
      setState(() {
        _categories = updated;
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = _categories.first;
        }
      });
      _showValidationMessage('Expense categories updated.');
    } catch (error) {
      if (mounted) {
        _showValidationMessage('Could not save categories: $error');
      }
    }
  }

  void _submitData() {
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextButton.icon(
                    onPressed: _manageCategories,
                    icon: const Icon(Icons.tune, size: 17),
                    label: const Text('Manage'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
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
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  leading: Icon(Icons.calendar_month_outlined, color: themeColor),
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
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _submitData,
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
