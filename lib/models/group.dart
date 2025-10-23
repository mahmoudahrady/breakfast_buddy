import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String adminId;
  final String adminName;
  final List<String> memberIds;
  final bool allowMembersToAddItems;
  final bool isActive;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.adminName,
    required this.memberIds,
    required this.allowMembersToAddItems,
    required this.isActive,
    required this.createdAt,
  });

  // Check if a user is the admin
  bool isAdmin(String userId) => adminId == userId;

  // Check if a user is a member
  bool isMember(String userId) => memberIds.contains(userId);

  // Check if a user can add items
  bool canAddItems(String userId) =>
      isAdmin(userId) || (isMember(userId) && allowMembersToAddItems);

  // Factory constructor to create Group from Firestore document
  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      adminId: data['adminId'] ?? '',
      adminName: data['adminName'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      allowMembersToAddItems: data['allowMembersToAddItems'] ?? false,
      isActive: data['isActive'] ?? true, // Default to true for backward compatibility
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert Group to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'adminId': adminId,
      'adminName': adminName,
      'memberIds': memberIds,
      'allowMembersToAddItems': allowMembersToAddItems,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy with updated fields
  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? adminId,
    String? adminName,
    List<String>? memberIds,
    bool? allowMembersToAddItems,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      memberIds: memberIds ?? this.memberIds,
      allowMembersToAddItems:
          allowMembersToAddItems ?? this.allowMembersToAddItems,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
