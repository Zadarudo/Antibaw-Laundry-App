class Transaction {
  final String id;
  final String date;
  final int amount;
  final String description;
  final String type; // 'income' or 'expense'
  final String status; // 'completed', 'pending', 'failed'

  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    required this.type,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'amount': amount,
      'description': description,
      'type': type,
      'status': status,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      date: map['date'],
      amount: map['amount'],
      description: map['description'],
      type: map['type'],
      status: map['status'],
    );
  }
}
