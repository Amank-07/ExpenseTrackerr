enum TransactionType { income, expense }

class TransactionModel {
  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date,
    };
  }

  factory TransactionModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final rawDate = map['date'];
    DateTime parsedDate = DateTime.now();
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate != null && rawDate.toString().contains('Timestamp')) {
      // Firestore returns Timestamp; use dynamic call to keep model lightweight.
      parsedDate = (rawDate as dynamic).toDate() as DateTime;
    }

    return TransactionModel(
      id: id,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: (map['type'] as String) == TransactionType.income.name
          ? TransactionType.income
          : TransactionType.expense,
      category: map['category'] as String,
      date: parsedDate,
    );
  }
}
