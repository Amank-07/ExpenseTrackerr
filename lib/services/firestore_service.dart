import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_app/models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userTransactionsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }

  DocumentReference<Map<String, dynamic>> _userBudgetProfileRef(String userId) {
    // Path: users/{userId}/profile/budget
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('budget');
  }

  Future<List<TransactionModel>> fetchTransactions(String userId) async {
    final snapshot = await _userTransactionsRef(userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => TransactionModel.fromMap(
            id: doc.id,
            map: doc.data(),
          ),
        )
        .toList();
  }

  Future<void> addTransaction({
    required String userId,
    required TransactionModel transaction,
  }) async {
    await _userTransactionsRef(userId).doc(transaction.id).set(transaction.toMap());
  }

  Future<void> updateTransaction({
    required String userId,
    required TransactionModel transaction,
  }) async {
    await _userTransactionsRef(userId)
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    await _userTransactionsRef(userId).doc(transactionId).delete();
  }

  Future<double?> fetchMonthlyBudget(String userId) async {
    final snapshot = await _userBudgetProfileRef(userId).get();
    if (!snapshot.exists) return null;
    final raw = snapshot.data()?['budget'];
    if (raw is num) return raw.toDouble();
    return null;
  }

  Future<void> setMonthlyBudget({
    required String userId,
    required double budget,
  }) async {
    await _userBudgetProfileRef(userId).set(
      <String, dynamic>{'budget': budget},
      // Use merge so future profile fields don't get overwritten.
      SetOptions(merge: true),
    );
  }
}
