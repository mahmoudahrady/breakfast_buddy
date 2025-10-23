import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
  });

  // Convert from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy with updated fields
  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
