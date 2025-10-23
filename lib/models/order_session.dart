import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus { open, closed }

class OrderSession {
  final String id;
  final String? groupId; // Group this session belongs to (optional for backward compatibility)
  final DateTime date;
  final String createdBy;
  final String createdByName; // Denormalized for easier display
  final SessionStatus status;
  final double totalAmount;
  final List<String> participants;
  final DateTime createdAt;

  OrderSession({
    required this.id,
    this.groupId,
    required this.date,
    required this.createdBy,
    required this.createdByName,
    required this.status,
    required this.totalAmount,
    required this.participants,
    required this.createdAt,
  });

  // Convert from Firestore document
  factory OrderSession.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderSession(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      status: data['status'] == 'closed' ? SessionStatus.closed : SessionStatus.open,
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'date': Timestamp.fromDate(date),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'status': status == SessionStatus.closed ? 'closed' : 'open',
      'totalAmount': totalAmount,
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy with updated fields
  OrderSession copyWith({
    String? id,
    String? groupId,
    DateTime? date,
    String? createdBy,
    String? createdByName,
    SessionStatus? status,
    double? totalAmount,
    List<String>? participants,
    DateTime? createdAt,
  }) {
    return OrderSession(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      date: date ?? this.date,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isOpen => status == SessionStatus.open;
  bool get isClosed => status == SessionStatus.closed;
}
