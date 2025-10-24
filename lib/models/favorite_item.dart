import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteItem {
  final String id;
  final String userId;
  final String groupId; // Optional - favorites can be group-specific
  final String itemName;
  final String? itemDescription;
  final double price;
  final String? imageUrl;
  final String? notes; // Default customization notes
  final DateTime createdAt;

  FavoriteItem({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.itemName,
    this.itemDescription,
    required this.price,
    this.imageUrl,
    this.notes,
    required this.createdAt,
  });

  // Convert from Firestore document
  factory FavoriteItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FavoriteItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      groupId: data['groupId'] ?? '',
      itemName: data['itemName'] ?? '',
      itemDescription: data['itemDescription'],
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'groupId': groupId,
      'itemName': itemName,
      if (itemDescription != null) 'itemDescription': itemDescription,
      'price': price,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with updated fields
  FavoriteItem copyWith({
    String? id,
    String? userId,
    String? groupId,
    String? itemName,
    String? itemDescription,
    double? price,
    String? imageUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      itemName: itemName ?? this.itemName,
      itemDescription: itemDescription ?? this.itemDescription,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
