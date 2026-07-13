class CategoryModel {
  final String ctgID;
  final String uID;
  final String name;
  final String type; // 'Thu' (Income) or 'Chi' (Expense)
  final String iconKey; // Store key representing the icon name/symbol

  CategoryModel({
    required this.ctgID,
    required this.uID,
    required this.name,
    required this.type,
    required this.iconKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'ctgID': ctgID,
      'uID': uID,
      'name': name,
      'type': type,
      'iconKey': iconKey,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      ctgID: map['ctgID'] ?? '',
      uID: map['uID'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'Chi',
      iconKey: map['iconKey'] ?? 'payment',
    );
  }

  CategoryModel copyWith({
    String? ctgID,
    String? uID,
    String? name,
    String? type,
    String? iconKey,
  }) {
    return CategoryModel(
      ctgID: ctgID ?? this.ctgID,
      uID: uID ?? this.uID,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
    );
  }
}
