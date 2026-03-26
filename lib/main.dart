import 'package:expense_tracker_app/providers/auth_provider.dart';
import 'package:expense_tracker_app/providers/budget_provider.dart';
import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:expense_tracker_app/providers/theme_provider.dart';
import 'package:expense_tracker_app/screens/home_screen.dart';
import 'package:expense_tracker_app/screens/login_screen.dart';
import 'package:expense_tracker_app/services/auth_service.dart';
import 'package:expense_tracker_app/services/budget_service.dart';
import 'package:expense_tracker_app/services/firestore_service.dart';
import 'package:expense_tracker_app/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase config is required for Auth + Firestore.
  // If the user hasn't run `flutterfire configure`, Firebase.initializeApp()
  // will throw, which would otherwise cause a blank (white) screen.
  try {
    await Firebase.initializeApp();
    runApp(const ExpenseTrackerApp());
  } catch (e) {
    runApp(_FirebaseInitErrorApp(error: e.toString()));
  }
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService())..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(FirestoreService()),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(
            firestoreService: FirestoreService(),
            budgetService: BudgetService(),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Expense Tracker',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _FirebaseInitErrorApp extends StatelessWidget {
  const _FirebaseInitErrorApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase not configured')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text(
                'Your Firebase configuration files are missing or incorrect.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Fix (recommended):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '1) Install FlutterFire CLI',
                style: TextStyle(height: 1.5),
              ),
              const Text(
                '   dart pub global activate flutterfire_cli',
              ),
              const Text(
                '2) Run configuration for your project:',
                style: TextStyle(height: 1.5),
              ),
              const Text(
                '   flutterfire configure',
              ),
              const Text(
                '3) Make sure Android has generated resources (google-services.json + values.xml).',
              ),
              const Divider(height: 28),
              Text(
                'Error details:\n$error',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthGateState extends State<_AuthGate> {
  String? _handledUserId;
  bool _clearedOnLogout = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userId = auth.isAuthenticated ? auth.userId : null;
        if (userId != null) {
          // Ensure Firestore transactions load only once per user session.
          if (_handledUserId != userId) {
            _handledUserId = userId;
            _clearedOnLogout = false;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              final txProvider = context.read<TransactionProvider>();
              final budgetProvider = context.read<BudgetProvider>();
              await txProvider.ensureForUser(userId);
              await budgetProvider.initializeForUser(userId);
            });
          }
          return const HomeScreen();
        }

        // Clear local transaction state only once when user logs out.
        if (!_clearedOnLogout) {
          _clearedOnLogout = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<TransactionProvider>().clearForLogout();
            context.read<BudgetProvider>().clear();
          });
        }
        return const LoginScreen();
      },
    );
  }
}
