import 'package:expense_tracker_app/providers/auth_provider.dart';
import 'package:expense_tracker_app/providers/budget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final authProvider = context.watch<AuthProvider>();

    final existingBudget = budgetProvider.monthlyBudget;

    // Prefill when budget is loaded the first time.
    if (_budgetController.text.isEmpty &&
        existingBudget != null &&
        !budgetProvider.isLoading) {
      _budgetController.text = existingBudget.toStringAsFixed(0);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Budget')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: budgetProvider.isLoading && existingBudget == null
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _budgetController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Budget Amount (monthly)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final amount = double.tryParse(value ?? '');
                          if (amount == null || amount <= 0) {
                            return 'Enter a valid budget amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (budgetProvider.errorMessage != null)
                        Text(
                          budgetProvider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                final budget = double.parse(
                                  _budgetController.text.trim(),
                                );
                                final userId = authProvider.userId;
                                if (userId == null) return;

                                final navigator = Navigator.of(context);
                                setState(() => _isSaving = true);
                                try {
                                  await budgetProvider.setMonthlyBudget(
                                    userId,
                                    budget,
                                  );
                                  if (!mounted) return;
                                  navigator.pop();
                                } finally {
                                  if (mounted) setState(() => _isSaving = false);
                                }
                              },
                        child: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Budget'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

