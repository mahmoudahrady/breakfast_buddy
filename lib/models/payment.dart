import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String sessionId;
  final String? groupId; // Group this payment belongs to (optional for backward compatibility)
  final String userId;
  final String userName; // Denormalized for easier display
  final double amount;
  final bool paid;
  final DateTime? paidAt;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.sessionId,
    this.groupId,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.paid,
    this.paidAt,
    required this.createdAt,
  });

  // Convert from Firestore document
  factory Payment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      groupId: data['groupId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paid: data['paid'] ?? false,
      paidAt: data['paidAt'] != null ? (data['paidAt'] as Timestamp).toDate() : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'paid': paid,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy with updated fields
  Payment copyWith({
    String? id,
    String? sessionId,
    String? groupId,
    String? userId,
    String? userName,
    double? amount,
    bool? paid,
    DateTime? paidAt,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      paid: paid ?? this.paid,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
