class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String paidBy;
  final List<String> participants;
  final DateTime dateTime;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.participants,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'participants': participants,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      paidBy: json['paidBy'],
      participants: List<String>.from(json['participants']),
      dateTime: DateTime.parse(json['dateTime']),
    );
  }
}
