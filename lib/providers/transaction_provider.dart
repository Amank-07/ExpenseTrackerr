import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/services/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider(this._firestoreService);

  final FirestoreService _firestoreService;
  final List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  final Uuid _uuid = const Uuid();
  String? _activeUserId;
  String? _errorMessage;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalIncome {
    return _transactions
        .where((item) => item.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((item) => item.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalBalance => totalIncome - totalExpense;

  double get currentMonthSpending {
    final now = DateTime.now();
    return _transactions
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              item.date.year == now.year &&
              item.date.month == now.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // ----- Helpers for analytics on an arbitrary list -----
  static double totalIncomeOf(List<TransactionModel> items) {
    return items
        .where((item) => item.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  static double totalExpenseOf(List<TransactionModel> items) {
    return items
        .where((item) => item.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  static double currentMonthExpenseOf(List<TransactionModel> items) {
    final now = DateTime.now();
    return items
        .where((item) =>
            item.type == TransactionType.expense &&
            item.date.year == now.year &&
            item.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> ensureForUser(String userId) async {
    if (_activeUserId == userId && !_isLoading) return;
    _activeUserId = userId;
    await initialize();
  }

  Future<void> initialize() async {
    if (_activeUserId == null) {
      clearForLogout();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _firestoreService.fetchTransactions(_activeUserId!);
      _transactions
        ..clear()
        ..addAll(data);
    } catch (e) {
      // If Firestore fails (missing rules, offline, or project not configured),
      // we show an error UI instead of leaving the screen blank/loading forever.
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String category,
    required DateTime date,
  }) async {
    if (_activeUserId == null) return;
    _errorMessage = null;
    final newTransaction = TransactionModel(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: date,
    );

    try {
      await _firestoreService.addTransaction(
        userId: _activeUserId!,
        transaction: newTransaction,
      );
      _transactions.insert(0, newTransaction);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    if (_activeUserId == null) return;
    _errorMessage = null;

    try {
      await _firestoreService.updateTransaction(
        userId: _activeUserId!,
        transaction: transaction,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    if (index == -1) return;
    _transactions[index] = transaction;
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    if (_activeUserId == null) return;
    _errorMessage = null;
    try {
      await _firestoreService.deleteTransaction(
        userId: _activeUserId!,
        transactionId: id,
      );
      _transactions.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Map<DateTime, double> weeklyExpenseData({List<TransactionModel>? items}) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final Map<DateTime, double> data = {};

    for (int i = 0; i < 7; i++) {
      final day = DateTime(
        sevenDaysAgo.year,
        sevenDaysAgo.month,
        sevenDaysAgo.day + i,
      );
      data[day] = 0;
    }

    final source = items ?? _transactions;
    for (final transaction in source) {
      if (transaction.type == TransactionType.expense &&
          transaction.date.isAfter(
            DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day - 1),
          )) {
        final key = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        if (data.containsKey(key)) {
          data[key] = (data[key] ?? 0) + transaction.amount;
        }
      }
    }

    return data;
  }

  Map<String, double> weeklyCategoryExpenseData({List<TransactionModel>? items}) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final Map<String, double> data = {};
    final source = items ?? _transactions;

    for (final transaction in source) {
      if (transaction.type != TransactionType.expense) continue;
      final inWeek = transaction.date.isAfter(
        DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day - 1),
      );
      if (!inWeek) continue;

      data[transaction.category] =
          (data[transaction.category] ?? 0) + transaction.amount;
    }

    return data;
  }

  Map<String, double> monthlyCategoryExpenseData({List<TransactionModel>? items}) {
    final now = DateTime.now();
    final Map<String, double> data = {};

    final source = items ?? _transactions;
    for (final transaction in source) {
      final isCurrentMonth = transaction.date.year == now.year &&
          transaction.date.month == now.month;
      if (transaction.type == TransactionType.expense && isCurrentMonth) {
        data[transaction.category] =
            (data[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return data;
  }

  /// Total expense per month for the last [months] months (oldest -> newest).
  /// Used for a monthly bar chart.
  Map<DateTime, double> monthlyExpenseTotals({
    int months = 6,
    List<TransactionModel>? items,
  }) {
    final safeMonths = months < 1 ? 1 : months;
    final Map<DateTime, double> data = {};

    // Helper to compute the first day of a month (month "bucket").
    DateTime monthKey(DateTime date) => DateTime(date.year, date.month, 1);

    // Insert month buckets in chronological order (oldest -> newest).
    final now = DateTime.now();
    final currentMonthKey = monthKey(now);

    for (int back = safeMonths - 1; back >= 0; back--) {
      final keyMonth = currentMonthKey.month - back;
      var year = currentMonthKey.year;
      var month = keyMonth;
      while (month <= 0) {
        month += 12;
        year -= 1;
      }
      data[DateTime(year, month, 1)] = 0;
    }

    final source = items ?? _transactions;
    for (final transaction in source) {
      if (transaction.type != TransactionType.expense) continue;

      final key = monthKey(transaction.date);
      if (data.containsKey(key)) {
        data[key] = (data[key] ?? 0) + transaction.amount;
      }
    }

    return data;
  }

  void clearForLogout() {
    _activeUserId = null;
    _transactions.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
