import 'package:expense_tracker_app/services/budget_service.dart';
import 'package:expense_tracker_app/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

class BudgetProvider extends ChangeNotifier {
  BudgetProvider({
    required this.firestoreService,
    required this.budgetService,
  });

  final FirestoreService firestoreService;
  final BudgetService budgetService;

  double? _monthlyBudget;
  bool _isLoading = false;
  String? _errorMessage;

  double? get monthlyBudget => _monthlyBudget;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initializeForUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _monthlyBudget = await firestoreService.fetchMonthlyBudget(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setMonthlyBudget(String userId, double budget) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await firestoreService.setMonthlyBudget(
        userId: userId,
        budget: budget,
      );
      _monthlyBudget = budget;
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        debugPrint('Failed to set budget: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  BudgetProgress? calculateProgress({
    required double monthlyExpense,
  }) {
    final budget = _monthlyBudget;
    if (budget == null) return null;
    return budgetService.calculate(
      budgetAmount: budget,
      monthlyExpense: monthlyExpense,
    );
  }

  void clear() {
    _monthlyBudget = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

