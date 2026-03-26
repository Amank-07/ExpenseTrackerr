import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.existingTransaction,
  });

  final TransactionModel? existingTransaction;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSaving = false;

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = const [
    'Food',
    'Travel',
    'Shopping',
    'Health',
    'Education',
    'Bills',
    'Entertainment',
    'Salary',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      _titleController.text = existing.title;
      _amountController.text = existing.amount.toString();
      _selectedType = existing.type;
      _selectedCategory = existing.category;
      _selectedDate = existing.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TransactionProvider>();
    final existing = widget.existingTransaction;
    setState(() => _isSaving = true);
    try {
      if (existing == null) {
        await provider.addTransaction(
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          type: _selectedType,
          category: _selectedCategory,
          date: _selectedDate,
        );
      } else {
        await provider.updateTransaction(
          existing.copyWith(
            title: _titleController.text.trim(),
            amount: double.parse(_amountController.text.trim()),
            type: _selectedType,
            category: _selectedCategory,
            date: _selectedDate,
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Save failed')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingTransaction == null
              ? 'Add Transaction'
              : 'Edit Transaction',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 560;
                      final typeField = DropdownButtonFormField<TransactionType>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TransactionType.income,
                            child: Text('Income'),
                          ),
                          DropdownMenuItem(
                            value: TransactionType.expense,
                            child: Text('Expense'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedType = value;
                          });
                        },
                      );

                      final categoryField = DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      );

                      if (!isWide) {
                        return Column(
                          children: [
                            typeField,
                            const SizedBox(height: 12),
                            categoryField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: typeField),
                          const SizedBox(width: 12),
                          Expanded(child: categoryField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      child: Text(
                        widget.existingTransaction == null
                            ? 'Save Transaction'
                            : 'Update Transaction',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
