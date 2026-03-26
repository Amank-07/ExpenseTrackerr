import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onTap,
  });

  final TransactionModel transaction;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amountText = NumberFormat.currency(symbol: 'Rs ').format(transaction.amount);
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? Colors.green : Colors.redAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 340;
          return ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: amountColor.withValues(alpha: 0.16),
              child: Icon(
                isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: amountColor,
              ),
            ),
            title: Text(
              transaction.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${transaction.category}  •  ${DateFormat('dd MMM yyyy').format(transaction.date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isNarrow ? 92 : 120,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}$amountText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w600,
                      fontSize: isNarrow ? 12 : 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: onDelete,
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: isNarrow ? 11 : 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
