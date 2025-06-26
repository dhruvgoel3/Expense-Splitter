class PersonModel {
  final String id;
  final String name;
  final double totalPaid;
  final double totalOwes;

  PersonModel({
    required this.id,
    required this.name,
    this.totalPaid = 0.0,
    this.totalOwes = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalPaid': totalPaid,
      'totalOwes': totalOwes,
    };
  }

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'],
      name: json['name'],
      totalPaid: json['totalPaid'] ?? 0.0,
      totalOwes: json['totalOwes'] ?? 0.0,
    );
  }
}

