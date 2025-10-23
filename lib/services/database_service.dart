import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/order.dart' as OrderModel;
import '../models/order_session.dart';
import '../models/payment.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== ORDER SESSIONS ====================

  // Create a new order session
  Future<String> createOrderSession({
    required String userId,
    required String userName,
  }) async {
    try {
      OrderSession session = OrderSession(
        id: '',
        date: DateTime.now(),
        createdBy: userId,
        createdByName: userName,
        status: SessionStatus.open,
        totalAmount: 0.0,
        participants: [],
        createdAt: DateTime.now(),
      );

      DocumentReference docRef = await _firestore
          .collection('orderSessions')
          .add(session.toFirestore());

      return docRef.id;
    } catch (e) {
      throw 'Failed to create order session. Please try again.';
    }
  }

  // Get today's order session
  Future<OrderSession?> getTodayOrderSession() async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      QuerySnapshot query = await _firestore
          .collection('orderSessions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return OrderSession.fromFirestore(query.docs.first);
    } catch (e) {
      return null;
    }
  }

  // Get order session by ID
  Future<OrderSession?> getOrderSession(String sessionId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('orderSessions').doc(sessionId).get();

      if (!doc.exists) return null;

      return OrderSession.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // Stream of order session
  Stream<OrderSession?> orderSessionStream(String sessionId) {
    return _firestore
        .collection('orderSessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return OrderSession.fromFirestore(doc);
    });
  }

  // Update order session status
  Future<void> updateOrderSessionStatus(
      String sessionId, SessionStatus status) async {
    try {
      await _firestore.collection('orderSessions').doc(sessionId).update({
        'status': status == SessionStatus.closed ? 'closed' : 'open',
      });
    } catch (e) {
      throw 'Failed to update session status. Please try again.';
    }
  }

  // Update order session total amount
  Future<void> updateOrderSessionTotal(
      String sessionId, double totalAmount) async {
    try {
      await _firestore.collection('orderSessions').doc(sessionId).update({
        'totalAmount': totalAmount,
      });
    } catch (e) {
      throw 'Failed to update session total. Please try again.';
    }
  }

  // ==================== ORDERS ====================

  // Create a new order
  Future<String> createOrder({
    required String sessionId,
    String? groupId,
    required String userId,
    required String userName,
    required String itemName,
    required double price,
    int quantity = 1,
    String? imageUrl,
  }) async {
    try {
      OrderModel.Order order = OrderModel.Order(
        id: '',
        sessionId: sessionId,
        groupId: groupId,
        userId: userId,
        userName: userName,
        itemName: itemName,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      DocumentReference docRef =
          await _firestore.collection('orders').add(order.toFirestore());

      // Update session participants if not already included
      await _updateSessionParticipants(sessionId, userId);

      // Update session total
      await _recalculateSessionTotal(sessionId);

      return docRef.id;
    } catch (e) {
      throw 'Failed to create order. Please try again.';
    }
  }

  // Get orders for a session
  Stream<List<OrderModel.Order>> getOrdersForSession(String sessionId) {
    return _firestore
        .collection('orders')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.Order.fromFirestore(doc)).toList();
    });
  }

  // Get orders for a user in a session
  Stream<List<OrderModel.Order>> getOrdersForUserInSession(
      String sessionId, String userId) {
    return _firestore
        .collection('orders')
        .where('sessionId', isEqualTo: sessionId)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.Order.fromFirestore(doc)).toList();
    });
  }

  // Get orders for a group
  Stream<List<OrderModel.Order>> getOrdersForGroup(String groupId) {
    return _firestore
        .collection('orders')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) => OrderModel.Order.fromFirestore(doc)).toList();
      // Sort in memory since Firestore index might not be created yet
      orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return orders;
    });
  }

  // Delete order
  Future<void> deleteOrder(String orderId, [String? sessionId]) async {
    try {
      await _firestore.collection('orders').doc(orderId).delete();

      // Update session total if sessionId is provided (for backward compatibility)
      if (sessionId != null) {
        await _recalculateSessionTotal(sessionId);
      }
    } catch (e) {
      throw 'Failed to delete order. Please try again.';
    }
  }

  // ==================== PAYMENTS ====================

  // Create or update payment for user
  Future<void> createOrUpdatePayment({
    required String sessionId,
    String? groupId,
    required String userId,
    required String userName,
    required double amount,
    required bool paid,
  }) async {
    try {
      // Check if payment exists
      QuerySnapshot existingPayments = await _firestore
          .collection('payments')
          .where('sessionId', isEqualTo: sessionId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingPayments.docs.isNotEmpty) {
        // Update existing payment
        await _firestore
            .collection('payments')
            .doc(existingPayments.docs.first.id)
            .update({
          'amount': amount,
          'paid': paid,
          'paidAt': paid ? Timestamp.fromDate(DateTime.now()) : null,
          'groupId': groupId,
        });
      } else {
        // Create new payment
        Payment payment = Payment(
          id: '',
          sessionId: sessionId,
          groupId: groupId,
          userId: userId,
          userName: userName,
          amount: amount,
          paid: paid,
          paidAt: paid ? DateTime.now() : null,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('payments').add(payment.toFirestore());
      }
    } catch (e) {
      throw 'Failed to update payment. Please try again.';
    }
  }

  // Get payments for a session
  Stream<List<Payment>> getPaymentsForSession(String sessionId) {
    return _firestore
        .collection('payments')
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
    });
  }

  // Mark payment as paid
  Future<void> markPaymentAsPaid(String sessionId, String userId) async {
    try {
      QuerySnapshot payments = await _firestore
          .collection('payments')
          .where('sessionId', isEqualTo: sessionId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (payments.docs.isNotEmpty) {
        await _firestore.collection('payments').doc(payments.docs.first.id).update({
          'paid': true,
          'paidAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw 'Failed to mark payment as paid. Please try again.';
    }
  }

  // ==================== USERS ====================

  // Get user by ID
  Future<AppUser?> getUser(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) return null;

      return AppUser.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // Get all users
  Stream<List<AppUser>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    });
  }

  // ==================== HELPER METHODS ====================

  // Update session participants
  Future<void> _updateSessionParticipants(
      String sessionId, String userId) async {
    DocumentSnapshot sessionDoc =
        await _firestore.collection('orderSessions').doc(sessionId).get();

    if (sessionDoc.exists) {
      List<String> participants =
          List<String>.from(sessionDoc.get('participants') ?? []);

      if (!participants.contains(userId)) {
        participants.add(userId);
        await _firestore.collection('orderSessions').doc(sessionId).update({
          'participants': participants,
        });
      }
    }
  }

  // Recalculate session total
  Future<void> _recalculateSessionTotal(String sessionId) async {
    QuerySnapshot orders = await _firestore
        .collection('orders')
        .where('sessionId', isEqualTo: sessionId)
        .get();

    double total = 0.0;
    for (var doc in orders.docs) {
      double price = (doc.get('price') ?? 0).toDouble();
      int quantity = doc.get('quantity') ?? 1;
      total += price * quantity;
    }

    await updateOrderSessionTotal(sessionId, total);
  }
}
