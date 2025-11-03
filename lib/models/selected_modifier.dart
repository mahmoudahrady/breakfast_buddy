/// Represents a modifier that has been selected for an order item
class SelectedModifier {
  final String modifierId;
  final String modifierName;
  final double price;

  SelectedModifier({
    required this.modifierId,
    required this.modifierName,
    required this.price,
  });

  /// Create from Firestore document
  factory SelectedModifier.fromJson(Map<String, dynamic> json) {
    return SelectedModifier(
      modifierId: json['modifierId'] as String? ?? '',
      modifierName: json['modifierName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'modifierId': modifierId,
      'modifierName': modifierName,
      'price': price,
    };
  }

  /// Create a copy with modified fields
  SelectedModifier copyWith({
    String? modifierId,
    String? modifierName,
    double? price,
  }) {
    return SelectedModifier(
      modifierId: modifierId ?? this.modifierId,
      modifierName: modifierName ?? this.modifierName,
      price: price ?? this.price,
    );
  }

  @override
  String toString() {
    return 'SelectedModifier(id: $modifierId, name: $modifierName, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SelectedModifier &&
        other.modifierId == modifierId &&
        other.modifierName == modifierName &&
        other.price == price;
  }

  @override
  int get hashCode {
    return modifierId.hashCode ^ modifierName.hashCode ^ price.hashCode;
  }
}
