import 'package:cloud_firestore/cloud_firestore.dart';
import 'selected_modifier.dart';
import 'order_status.dart';

class Order {
  final String id;
  final String? sessionId; // Optional for backward compatibility
  final String? groupId; // Group this order belongs to
  final String userId;
  final String userName; // Denormalized for easier display
  final String itemName;
  final double basePrice; // Base price without modifiers
  final int quantity;
  final List<SelectedModifier>? selectedModifiers; // Selected modifiers
  final OrderStatus status; // Current status of the order
  final DateTime? statusUpdatedAt; // When status was last changed
  final String? statusUpdatedBy; // Who changed the status
  final String? imageUrl;
  final String? notes; // Special instructions or customizations
  final DateTime createdAt;

  Order({
    required this.id,
    this.sessionId,
    this.groupId,
    required this.userId,
    required this.userName,
    required this.itemName,
    required this.basePrice,
    this.quantity = 1,
    this.selectedModifiers,
    this.status = OrderStatus.pending,
    this.statusUpdatedAt,
    this.statusUpdatedBy,
    this.imageUrl,
    this.notes,
    required this.createdAt,
  });

  /// Calculate total price including modifiers
  double get totalPrice {
    double modifierTotal = 0;
    if (selectedModifiers != null) {
      for (var modifier in selectedModifiers!) {
        modifierTotal += modifier.price;
      }
    }
    return (basePrice + modifierTotal) * quantity;
  }

  /// Get price (backward compatibility - returns basePrice)
  @Deprecated('Use basePrice or totalPrice instead')
  double get price => basePrice;

  // Convert from Firestore document
  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse selected modifiers
    List<SelectedModifier>? modifiers;
    if (data['selectedModifiers'] != null) {
      modifiers = (data['selectedModifiers'] as List)
          .map((m) => SelectedModifier.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return Order(
      id: doc.id,
      sessionId: data['sessionId'], // Keep null if not present
      groupId: data['groupId'], // Keep null if not present - important for queries!
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      itemName: data['itemName'] ?? '',
      // Support both old 'price' field and new 'basePrice' field for backward compatibility
      basePrice: (data['basePrice'] ?? data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      selectedModifiers: modifiers,
      status: OrderStatus.fromString(data['status']),
      statusUpdatedAt: data['statusUpdatedAt'] != null
          ? (data['statusUpdatedAt'] as Timestamp).toDate()
          : null,
      statusUpdatedBy: data['statusUpdatedBy'],
      imageUrl: data['imageUrl'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      if (sessionId != null) 'sessionId': sessionId,
      if (groupId != null) 'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'itemName': itemName,
      'basePrice': basePrice,
      'price': basePrice, // Keep for backward compatibility
      'quantity': quantity,
      if (selectedModifiers != null && selectedModifiers!.isNotEmpty)
        'selectedModifiers': selectedModifiers!.map((m) => m.toJson()).toList(),
      'status': status.name,
      if (statusUpdatedAt != null)
        'statusUpdatedAt': Timestamp.fromDate(statusUpdatedAt!),
      if (statusUpdatedBy != null) 'statusUpdatedBy': statusUpdatedBy,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy with updated fields
  Order copyWith({
    String? id,
    String? sessionId,
    String? groupId,
    String? userId,
    String? userName,
    String? itemName,
    double? basePrice,
    int? quantity,
    List<SelectedModifier>? selectedModifiers,
    OrderStatus? status,
    DateTime? statusUpdatedAt,
    String? statusUpdatedBy,
    String? imageUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      itemName: itemName ?? this.itemName,
      basePrice: basePrice ?? this.basePrice,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      status: status ?? this.status,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      statusUpdatedBy: statusUpdatedBy ?? this.statusUpdatedBy,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
