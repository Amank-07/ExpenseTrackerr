import 'package:flutter/material.dart';

enum InsightKind {
  spentMoreThanLastWeek,
  highestSpendingCategory,
  savingChangeThisMonth,
}

class InsightResult {
  InsightResult({
    required this.kind,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final InsightKind kind;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

