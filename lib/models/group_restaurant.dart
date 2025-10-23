import 'package:cloud_firestore/cloud_firestore.dart';

class GroupRestaurant {
  final String id;
  final String groupId;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantApiUrl;
  final String? restaurantImageUrl;
  final String? restaurantDescription;
  final String addedBy;
  final String addedByName;
  final DateTime addedAt;

  GroupRestaurant({
    required this.id,
    required this.groupId,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantApiUrl,
    this.restaurantImageUrl,
    this.restaurantDescription,
    required this.addedBy,
    required this.addedByName,
    required this.addedAt,
  });

  // Factory constructor to create GroupRestaurant from Firestore document
  factory GroupRestaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupRestaurant(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      restaurantApiUrl: data['restaurantApiUrl'],
      restaurantImageUrl: data['restaurantImageUrl'],
      restaurantDescription: data['restaurantDescription'],
      addedBy: data['addedBy'] ?? '',
      addedByName: data['addedByName'] ?? '',
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  // Convert GroupRestaurant to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantApiUrl': restaurantApiUrl,
      'restaurantImageUrl': restaurantImageUrl,
      'restaurantDescription': restaurantDescription,
      'addedBy': addedBy,
      'addedByName': addedByName,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  // Create a copy with updated fields
  GroupRestaurant copyWith({
    String? id,
    String? groupId,
    String? restaurantId,
    String? restaurantName,
    String? restaurantApiUrl,
    String? restaurantImageUrl,
    String? restaurantDescription,
    String? addedBy,
    String? addedByName,
    DateTime? addedAt,
  }) {
    return GroupRestaurant(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantApiUrl: restaurantApiUrl ?? this.restaurantApiUrl,
      restaurantImageUrl: restaurantImageUrl ?? this.restaurantImageUrl,
      restaurantDescription:
          restaurantDescription ?? this.restaurantDescription,
      addedBy: addedBy ?? this.addedBy,
      addedByName: addedByName ?? this.addedByName,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
