enum BudgetStatus { ok, warning, exceeded }

class BudgetProgress {
  BudgetProgress({
    required this.budgetAmount,
    required this.monthlyExpense,
    required this.usedPercent,
    required this.remaining,
    required this.status,
  });

  final double budgetAmount;
  final double monthlyExpense;
  final double usedPercent; // 0 - 100+
  final double remaining;
  final BudgetStatus status;
}

/// Pure calculation helpers for budget progress.
class BudgetService {
  BudgetProgress calculate({
    required double budgetAmount,
    required double monthlyExpense,
  }) {
    final usedPercent =
        budgetAmount <= 0 ? 0.0 : (monthlyExpense / budgetAmount) * 100.0;
    final remaining = budgetAmount - monthlyExpense;

    final status = usedPercent >= 100
        ? BudgetStatus.exceeded
        : usedPercent >= 80
            ? BudgetStatus.warning
            : BudgetStatus.ok;

    return BudgetProgress(
      budgetAmount: budgetAmount,
      monthlyExpense: monthlyExpense,
      usedPercent: usedPercent,
      remaining: remaining,
      status: status,
    );
  }
}

