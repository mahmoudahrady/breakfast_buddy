import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String? sessionId; // Optional for backward compatibility
  final String? groupId; // Group this order belongs to
  final String userId;
  final String userName; // Denormalized for easier display
  final String itemName;
  final double price;
  final int quantity;
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
    required this.price,
    this.quantity = 1,
    this.imageUrl,
    this.notes,
    required this.createdAt,
  });

  // Convert from Firestore document
  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      sessionId: data['sessionId'], // Keep null if not present
      groupId: data['groupId'], // Keep null if not present - important for queries!
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      itemName: data['itemName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
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
      'price': price,
      'quantity': quantity,
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
    double? price,
    int? quantity,
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
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
