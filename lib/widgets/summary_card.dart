import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Rs ');
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Balance', style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              currency.format(balance),
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 360;
                if (isSmall) {
                  return Column(
                    children: [
                      _SummaryValue(
                        label: 'Income',
                        value: currency.format(income),
                        color: Colors.green,
                      ),
                      const SizedBox(height: 10),
                      _SummaryValue(
                        label: 'Expense',
                        value: currency.format(expense),
                        color: Colors.redAccent,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _SummaryValue(
                        label: 'Income',
                        value: currency.format(income),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryValue(
                        label: 'Expense',
                        value: currency.format(expense),
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
