import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/order.dart' as OrderModel;
import '../models/order_session.dart';
import '../models/payment.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER PROFILE ====================

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? photoUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (name != null) {
        updates['name'] = name;
      }

      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
      }
    } catch (e) {
      throw 'Failed to update profile. Please try again.';
    }
  }

  // Get user by ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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
    String? notes,
  }) async {
    try {
      OrderModel.Order order = OrderModel.Order(
        id: '',
        sessionId: sessionId,
        groupId: groupId,
        userId: userId,
        userName: userName,
        itemName: itemName,
        basePrice: price,
        quantity: quantity,
        imageUrl: imageUrl,
        notes: notes,
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

  // Get ALL orders for a specific user (across all groups and sessions)
  Stream<List<OrderModel.Order>> getOrdersForUser(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) => OrderModel.Order.fromFirestore(doc)).toList();
      // Sort by date descending (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // Update order
  Future<void> updateOrder(OrderModel.Order order) async {
    try {
      await _firestore.collection('orders').doc(order.id).update(order.toFirestore());
    } catch (e) {
      throw 'Failed to update order. Please try again.';
    }
  }

  // Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    required String updatedBy,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': updatedBy,
      });
    } catch (e) {
      throw 'Failed to update order status. Please try again.';
    }
  }

  // Bulk update order status for multiple orders
  Future<void> updateMultipleOrdersStatus({
    required List<String> orderIds,
    required String status,
    required String updatedBy,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final orderId in orderIds) {
        final docRef = _firestore.collection('orders').doc(orderId);
        batch.update(docRef, {
          'status': status,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
          'statusUpdatedBy': updatedBy,
        });
      }

      await batch.commit();
    } catch (e) {
      throw 'Failed to update order statuses. Please try again.';
    }
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
      } else {
        throw 'Payment record not found for this user';
      }
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Failed to mark payment as paid. Please try again.';
    }
  }

  // Get payments for a group within a date range
  Future<List<Payment>> getPaymentsForGroupByDateRange({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('payments')
          .where('groupId', isEqualTo: groupId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return query.docs.map((doc) => Payment.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Failed to fetch payments. Please try again.';
    }
  }

  // Get payment statistics for a group
  Future<Map<String, dynamic>> getGroupPaymentStatistics(String groupId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('payments')
          .where('groupId', isEqualTo: groupId)
          .get();

      final payments = query.docs.map((doc) => Payment.fromFirestore(doc)).toList();

      double totalAmount = 0;
      double paidAmount = 0;
      double unpaidAmount = 0;
      int totalCount = payments.length;
      int paidCount = 0;

      for (var payment in payments) {
        totalAmount += payment.amount;
        if (payment.paid) {
          paidAmount += payment.amount;
          paidCount++;
        } else {
          unpaidAmount += payment.amount;
        }
      }

      return {
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'unpaidAmount': unpaidAmount,
        'totalCount': totalCount,
        'paidCount': paidCount,
        'unpaidCount': totalCount - paidCount,
        'payments': payments,
      };
    } catch (e) {
      throw 'Failed to fetch payment statistics. Please try again.';
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

  // ==================== USER STATISTICS ====================

  // Get user's orders for current month
  Future<Map<String, dynamic>> getUserMonthlyStats(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      QuerySnapshot query = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      final orders = query.docs.map((doc) => OrderModel.Order.fromFirestore(doc)).toList();

      double totalSpent = 0;
      for (var order in orders) {
        totalSpent += order.totalPrice;
      }

      return {
        'orderCount': orders.length,
        'totalSpent': totalSpent,
        'orders': orders,
      };
    } catch (e) {
      return {
        'orderCount': 0,
        'totalSpent': 0.0,
        'orders': [],
      };
    }
  }

  // Get user's orders for today
  Future<List<OrderModel.Order>> getUserTodayOrders(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      QuerySnapshot query = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => OrderModel.Order.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get active groups for today (groups with isActive = true)
  Future<List<String>> getActiveGroupIds(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  // Get user's recent orders for a specific group (for reorder functionality)
  Future<List<OrderModel.Order>> getUserRecentOrdersForGroup(
    String userId,
    String groupId, {
    int limit = 10,
  }) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final orders = query.docs
          .map((doc) => OrderModel.Order.fromFirestore(doc))
          .toList();

      // Remove duplicates based on itemName (keep most recent)
      final uniqueOrders = <String, OrderModel.Order>{};
      for (var order in orders) {
        if (!uniqueOrders.containsKey(order.itemName)) {
          uniqueOrders[order.itemName] = order;
        }
      }

      return uniqueOrders.values.toList();
    } catch (e) {
      return [];
    }
  }
}
