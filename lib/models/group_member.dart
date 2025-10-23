import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final DateTime joinedAt;
  final bool isAdmin;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    required this.joinedAt,
    required this.isAdmin,
  });

  // Factory constructor to create GroupMember from Firestore document
  factory GroupMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMember(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  // Convert GroupMember to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isAdmin': isAdmin,
    };
  }

  // Create a copy with updated fields
  GroupMember copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhotoUrl,
    DateTime? joinedAt,
    bool? isAdmin,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
