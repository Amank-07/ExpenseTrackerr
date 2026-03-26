import 'package:expense_tracker_app/models/insight_result.dart';
import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// Generates smart, user-friendly insights from a list of transactions.
class InsightsService {
  InsightsService({DateTime? now}) : _now = now ?? DateTime.now();

  final DateTime _now;

  List<InsightResult> buildInsights(List<TransactionModel> transactions) {
    final currency = NumberFormat.currency(symbol: 'Rs ');

    final nowDay = DateTime(_now.year, _now.month, _now.day);

    // ----- Weekly comparison (expense only) -----
    final startThisWeek = nowDay.subtract(const Duration(days: 6));
    final endThisWeek = nowDay;
    final startPrevWeek = startThisWeek.subtract(const Duration(days: 7));
    final endPrevWeek = startPrevWeek.add(const Duration(days: 6));

    double spentThisWeek = 0;
    double spentPrevWeek = 0;

    for (final t in transactions) {
      if (t.type != TransactionType.expense) continue;
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      if (d.isBefore(startThisWeek) || d.isAfter(endThisWeek)) {
        // previous week check
        if (!d.isBefore(startPrevWeek) && !d.isAfter(endPrevWeek)) {
          spentPrevWeek += t.amount;
        }
      } else {
        spentThisWeek += t.amount;
      }
    }

    final weeklyDelta = spentPrevWeek <= 0
        ? (spentThisWeek > 0 ? 100.0 : 0.0)
        : ((spentThisWeek - spentPrevWeek) / spentPrevWeek) * 100.0;

    final spentMore = weeklyDelta > 5; // small threshold to reduce noise

    final weeklyInsight = InsightResult(
      kind: InsightKind.spentMoreThanLastWeek,
      title: spentMore ? 'Spending increased' : 'Spending is stable',
      description: spentPrevWeek <= 0
          ? 'You spent ${currency.format(spentThisWeek)} in the last 7 days.'
          : 'You spent ${weeklyDelta.abs().toStringAsFixed(0)}% '
              '${spentMore ? 'more' : 'less'} than last week '
              '(${currency.format(spentThisWeek)} vs ${currency.format(spentPrevWeek)}).',
      icon: spentMore ? Icons.trending_up : Icons.trending_down,
      color: spentMore ? Colors.redAccent : Colors.green,
    );

    // ----- Highest spending category (current month, expense only) -----
    final currentMonth = DateTime(_now.year, _now.month, 1);
    final nextMonth = DateTime(_now.year, _now.month + 1, 1);

    final Map<String, double> categoryTotals = {};
    for (final t in transactions) {
      if (t.type != TransactionType.expense) continue;
      final d = t.date;
      if (d.isBefore(currentMonth) || !d.isBefore(nextMonth)) continue;
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    String topCategory = 'N/A';
    double topCategoryValue = 0;
    for (final entry in categoryTotals.entries) {
      if (entry.value > topCategoryValue) {
        topCategoryValue = entry.value;
        topCategory = entry.key;
      }
    }

    final highestCategoryInsight = InsightResult(
      kind: InsightKind.highestSpendingCategory,
      title: 'Top spending category',
      description: topCategoryValue <= 0
          ? 'No expenses found this month.'
          : '$topCategory (${currency.format(topCategoryValue)} this month)',
      icon: Icons.category_outlined,
      color: Colors.amber.shade700,
    );

    // ----- Saving change (income - expense) this month vs last month -----
    final lastMonth = DateTime(_now.year, _now.month - 1, 1);
    final lastMonthNext = DateTime(_now.year, _now.month, 1);

    double incomeThisMonth = 0;
    double expenseThisMonth = 0;
    double incomeLastMonth = 0;
    double expenseLastMonth = 0;

    for (final t in transactions) {
      final d = t.date;
      final isThisMonth = d.isAfter(currentMonth.subtract(const Duration(milliseconds: 1))) &&
          d.isBefore(nextMonth);
      final isLastMonth = !d.isBefore(lastMonth) && d.isBefore(lastMonthNext);

      if (isThisMonth) {
        if (t.type == TransactionType.income) {
          incomeThisMonth += t.amount;
        } else {
          expenseThisMonth += t.amount;
        }
      } else if (isLastMonth) {
        if (t.type == TransactionType.income) {
          incomeLastMonth += t.amount;
        } else {
          expenseLastMonth += t.amount;
        }
      }
    }

    final savingThisMonth = incomeThisMonth - expenseThisMonth;
    final savingLastMonth = incomeLastMonth - expenseLastMonth;

    final savingDelta = savingLastMonth == 0
        ? (savingThisMonth > 0 ? 100.0 : 0.0)
        : ((savingThisMonth - savingLastMonth) / savingLastMonth) * 100.0;

    final savingImproved = savingDelta >= 5;

    final savingInsight = InsightResult(
      kind: InsightKind.savingChangeThisMonth,
      title: savingImproved ? 'You’re saving more' : 'Saving is down',
      description: savingLastMonth == 0
          ? 'Your savings this month are ${currency.format(savingThisMonth)}.'
          : 'Your savings changed by ${savingDelta.abs().toStringAsFixed(0)}% '
              '${savingImproved ? 'up' : 'down'} '
              '(${currency.format(savingThisMonth)} vs ${currency.format(savingLastMonth)}).',
      icon: Icons.savings_outlined,
      color: savingImproved ? Colors.green : Colors.redAccent,
    );

    return [weeklyInsight, highestCategoryInsight, savingInsight];
  }
}

