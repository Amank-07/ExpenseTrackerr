import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/providers/auth_provider.dart';
import 'package:expense_tracker_app/providers/budget_provider.dart';
import 'package:expense_tracker_app/providers/theme_provider.dart';
import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:expense_tracker_app/screens/add_transaction_screen.dart';
import 'package:expense_tracker_app/screens/budget_screen.dart';
import 'package:expense_tracker_app/services/insights_service.dart';
import 'package:expense_tracker_app/services/budget_service.dart';
import 'package:expense_tracker_app/widgets/chart_section.dart';
import 'package:expense_tracker_app/widgets/empty_state.dart';
import 'package:expense_tracker_app/widgets/summary_card.dart';
import 'package:expense_tracker_app/widgets/transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _categoryWeekly = false;

  // Filter state (optional).
  DateTime? _filterStart;
  DateTime? _filterEnd;
  TransactionType? _filterType;
  String? _filterCategory;

  List<TransactionModel> _applyFilters(List<TransactionModel> input) {
    if (_filterStart == null &&
        _filterEnd == null &&
        _filterType == null &&
        _filterCategory == null) {
      return input;
    }

    final startDay = _filterStart != null
        ? DateTime(_filterStart!.year, _filterStart!.month, _filterStart!.day)
        : null;
    final endDay = _filterEnd != null
        ? DateTime(_filterEnd!.year, _filterEnd!.month, _filterEnd!.day, 23, 59, 59, 999)
        : null;

    return input.where((t) {
      if (_filterType != null && t.type != _filterType) return false;
      if (_filterCategory != null && t.category != _filterCategory) return false;

      if (startDay != null && t.date.isBefore(startDay)) return false;
      if (endDay != null && t.date.isAfter(endDay)) return false;
      return true;
    }).toList();
  }

  bool _hasActiveFilters() {
    return _filterStart != null ||
        _filterEnd != null ||
        _filterType != null ||
        _filterCategory != null;
  }

  Future<void> _openFilterSheet({
    required List<TransactionModel> currentTransactions,
  }) async {
    final categories = currentTransactions
        .map((e) => e.category)
        .toSet()
        .toList()
      ..sort();

    DateTime? tempStart = _filterStart;
    DateTime? tempEnd = _filterEnd;
    TransactionType? tempType = _filterType;
    String? tempCategory = _filterCategory;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setStateTemp) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Filter transactions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    // Date range
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempStart ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked == null) return;
                              setStateTemp(() => tempStart = picked);
                            },
                            child: Text(
                              tempStart == null
                                  ? 'Start date'
                                  : DateFormat('dd MMM yyyy').format(tempStart!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempEnd ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked == null) return;
                              setStateTemp(() => tempEnd = picked);
                            },
                            child: Text(
                              tempEnd == null
                                  ? 'End date'
                                  : DateFormat('dd MMM yyyy').format(tempEnd!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Type filter
                    DropdownButtonFormField<TransactionType?>(
                      key: ValueKey(tempType),
                      initialValue: tempType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<TransactionType?>(
                          value: null,
                          child: Text('All'),
                        ),
                        DropdownMenuItem<TransactionType?>(
                          value: TransactionType.income,
                          child: const Text('Income'),
                        ),
                        DropdownMenuItem<TransactionType?>(
                          value: TransactionType.expense,
                          child: const Text('Expense'),
                        ),
                      ],
                      onChanged: (value) {
                        setStateTemp(() => tempType = value);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Category filter
                    DropdownButtonFormField<String?>(
                      key: ValueKey(tempCategory),
                      initialValue: tempCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All'),
                        ),
                        ...categories.map(
                          (cat) => DropdownMenuItem<String?>(
                            value: cat,
                            child: Text(cat),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setStateTemp(() => tempCategory = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.clear_rounded),
                            label: const Text('Clear'),
                            onPressed: () {
                              setStateTemp(() {
                                tempStart = null;
                                tempEnd = null;
                                tempType = null;
                                tempCategory = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Apply'),
                            onPressed: () {
                              setState(() {
                                _filterStart = tempStart;
                                _filterEnd = tempEnd;
                                _filterType = tempType;
                                _filterCategory = tempCategory;
                              });
                              Navigator.pop(sheetContext);
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            onPressed: () {
              // Filter sheet is opened after we load transactions.
              // Here we just show a message if loading.
              final txProvider = context.read<TransactionProvider>();
              if (txProvider.isLoading) return;
              _openFilterSheet(currentTransactions: txProvider.transactions);
            },
            icon: Icon(
              _hasActiveFilters() ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            icon: Icon(
              themeProvider.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, txProvider, child) {
          final authProvider = context.read<AuthProvider>();
          final budgetProvider = context.watch<BudgetProvider>();

          if (txProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (txProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Could not load your transactions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            txProvider.errorMessage!,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => txProvider.initialize(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: () => authProvider.logout(),
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Logout'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final filteredTransactions = _applyFilters(txProvider.transactions);
          final currency = NumberFormat.currency(symbol: 'Rs ');

          final insights = InsightsService().buildInsights(filteredTransactions);

          final monthlyExpense = txProvider.currentMonthSpending;
          final progress = budgetProvider.calculateProgress(
            monthlyExpense: monthlyExpense,
          );

          // Build a simple category toggle for the pie chart.
          final categoryToggle = SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: false,
                label: const Text('Monthly'),
                icon: const Icon(Icons.calendar_month_rounded),
              ),
              ButtonSegment<bool>(
                value: true,
                label: const Text('Weekly'),
                icon: const Icon(Icons.calendar_view_week_rounded),
              ),
            ],
            selected: {_categoryWeekly},
            onSelectionChanged: (newSelection) {
              final selectedWeekly = newSelection.isNotEmpty ? newSelection.first : false;
              setState(() => _categoryWeekly = selectedWeekly);
            },
          );

          return RefreshIndicator(
            onRefresh: txProvider.initialize,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1024;
                final contentWidth = isDesktop ? 980.0 : 700.0;

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Logged in as'),
                            subtitle: Text(authProvider.userEmail),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ---- Budget card ----
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.account_balance_wallet_rounded),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Monthly Budget',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (progress == null)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Set your monthly budget to get alerts and progress.',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const BudgetScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text('Set Budget'),
                                      ),
                                    ],
                                  )
                                else ...[
                                  Text(
                                    'Budget: ${currency.format(progress.budgetAmount)}',
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Used: ${progress.usedPercent.toStringAsFixed(0)}%  •  Remaining: ${currency.format(progress.remaining)}',
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: (progress.usedPercent / 100).clamp(0.0, 1.0),
                                    minHeight: 10,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.surfaceContainerHighest,
                                    color: switch (progress.status) {
                                      BudgetStatus.ok => Colors.green,
                                      BudgetStatus.warning => Colors.amber,
                                      BudgetStatus.exceeded => Colors.redAccent,
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  if (progress.status == BudgetStatus.warning)
                                    const Text(
                                      'Warning: You are using 80% of your budget.',
                                      style: TextStyle(color: Colors.amber),
                                    ),
                                  if (progress.status == BudgetStatus.exceeded)
                                    const Text(
                                      'Alert: You have exceeded your monthly budget.',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const BudgetScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text('Edit'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ---- Smart insights ----
                        Text(
                          'Smart Insights',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (insights.isEmpty)
                          const Text('No insights yet. Add transactions to see analytics.')
                        else
                          ...insights.map(
                            (insight) => Card(
                              child: ListTile(
                                leading: Icon(insight.icon, color: insight.color),
                                title: Text(insight.title),
                                subtitle: Text(insight.description),
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        SummaryCard(
                          balance: TransactionProvider
                              .totalIncomeOf(filteredTransactions) -
                              TransactionProvider.totalExpenseOf(filteredTransactions),
                          income: TransactionProvider.totalIncomeOf(filteredTransactions),
                          expense:
                              TransactionProvider.totalExpenseOf(filteredTransactions),
                        ),

                        const SizedBox(height: 12),

                        // ---- Charts ----
                        categoryToggle,
                        const SizedBox(height: 12),
                        ChartSection(
                          weeklyExpenseData: txProvider.weeklyExpenseData(
                            items: filteredTransactions,
                          ),
                          categoryData: _categoryWeekly
                              ? txProvider.weeklyCategoryExpenseData(
                                  items: filteredTransactions,
                                )
                              : txProvider.monthlyCategoryExpenseData(
                                  items: filteredTransactions,
                                ),
                          monthlyExpenseData: txProvider.monthlyExpenseTotals(
                            months: 6,
                            items: filteredTransactions,
                          ),
                          categoryRangeLabel: _categoryWeekly ? 'Weekly' : 'Monthly',
                        ),

                        const SizedBox(height: 14),

                        // ---- Recent transactions ----
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Transactions',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (_hasActiveFilters())
                              Text(
                                'Filtered (${filteredTransactions.length})',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (filteredTransactions.isEmpty)
                          const SizedBox(height: 220, child: EmptyState())
                        else
                          ...filteredTransactions.map(
                            (transaction) => TransactionCard(
                              transaction: transaction,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddTransactionScreen(
                                      existingTransaction: transaction,
                                    ),
                                  ),
                                );
                              },
                              onDelete: () =>
                                  txProvider.deleteTransaction(transaction.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
