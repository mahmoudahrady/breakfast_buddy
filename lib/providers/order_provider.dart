import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/order_session.dart';
import '../models/payment.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';

class OrderProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  OrderSession? _currentSession;
  List<Order> _orders = [];
  List<Payment> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;

  OrderSession? get currentSession => _currentSession;
  List<Order> get orders => _orders;
  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasActiveSession => _currentSession != null && _currentSession!.isOpen;

  // Get or create today's session
  Future<void> initTodaySession(String userId, String userName) async {
    AppLogger.info('initTodaySession called for user: $userName ($userId)');
    _setLoading(true);
    _errorMessage = null;

    try {
      AppLogger.debug('Fetching today\'s session from database...');
      // Try to get today's session
      _currentSession = await _databaseService.getTodayOrderSession();
      AppLogger.debug('Existing session: $_currentSession');

      // If no session exists, create one
      if (_currentSession == null) {
        AppLogger.info('No existing session, creating new one...');
        String sessionId = await _databaseService.createOrderSession(
          userId: userId,
          userName: userName,
        );
        AppLogger.info('New session created with ID: $sessionId');
        _currentSession = await _databaseService.getOrderSession(sessionId);
        AppLogger.debug('Session loaded: $_currentSession');
      }

      // Subscribe to session updates
      if (_currentSession != null) {
        AppLogger.debug('Subscribing to session updates...');
        _subscribeToSession(_currentSession!.id);
        AppLogger.debug('Subscription complete');
      } else {
        AppLogger.error('Session is still null after creation!');
      }

      _setLoading(false);
      AppLogger.info('initTodaySession completed successfully');
      AppLogger.debug('hasActiveSession: $hasActiveSession');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error in initTodaySession', e);
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Subscribe to session updates
  void _subscribeToSession(String sessionId) {
    // Listen to session changes
    _databaseService.orderSessionStream(sessionId).listen((session) {
      _currentSession = session;
      notifyListeners();
    });

    // Listen to orders
    _databaseService.getOrdersForSession(sessionId).listen((orders) {
      _orders = orders;
      notifyListeners();
    });

    // Listen to payments
    _databaseService.getPaymentsForSession(sessionId).listen((payments) {
      _payments = payments;
      notifyListeners();
    });
  }

  // Create order
  Future<bool> createOrder({
    required String userId,
    required String userName,
    required String itemName,
    required double price,
    int quantity = 1,
    String? imageUrl,
    String? groupId,
    String? notes,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Auto-create session if it doesn't exist
      if (_currentSession == null) {
        AppLogger.info('No active session, creating one...');
        await initTodaySession(userId, userName);
      }

      // Double-check session exists
      if (_currentSession == null) {
        _errorMessage = 'Failed to initialize session';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      await _databaseService.createOrder(
        sessionId: _currentSession!.id,
        groupId: groupId,
        userId: userId,
        userName: userName,
        itemName: itemName,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
        notes: notes,
      );

      // Update payment tracking
      double userTotal = await _calculateUserTotal(userId);
      await _databaseService.createOrUpdatePayment(
        sessionId: _currentSession!.id,
        groupId: groupId,
        userId: userId,
        userName: userName,
        amount: userTotal,
        paid: false,
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete order
  // Simple delete order method (for group-based orders without sessions)
  Future<bool> deleteOrder(String orderId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _databaseService.deleteOrder(orderId);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Legacy delete order method (for session-based orders - backward compatibility)
  Future<bool> deleteOrderWithSession(String orderId, String userId, String userName) async {
    if (_currentSession == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _databaseService.deleteOrder(orderId, _currentSession!.id);

      // Update payment tracking
      double userTotal = await _calculateUserTotal(userId);
      await _databaseService.createOrUpdatePayment(
        sessionId: _currentSession!.id,
        userId: userId,
        userName: userName,
        amount: userTotal,
        paid: false,
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Close session
  Future<bool> closeSession() async {
    if (_currentSession == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _databaseService.updateOrderSessionStatus(
        _currentSession!.id,
        SessionStatus.closed,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Mark payment as paid
  Future<bool> markPaymentAsPaid(String userId) async {
    if (_currentSession == null) {
      _errorMessage = 'No active session found. Please refresh and try again.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _databaseService.markPaymentAsPaid(_currentSession!.id, userId);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Create or update payment
  Future<bool> createOrUpdatePayment({
    required String userId,
    required String userName,
    required double amount,
    required bool paid,
    String? groupId,
  }) async {
    if (_currentSession == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _databaseService.createOrUpdatePayment(
        sessionId: _currentSession!.id,
        groupId: groupId,
        userId: userId,
        userName: userName,
        amount: amount,
        paid: paid,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Calculate user total
  Future<double> _calculateUserTotal(String userId) async {
    double total = 0.0;
    for (var order in _orders) {
      if (order.userId == userId) {
        total += order.price * order.quantity;
      }
    }
    return total;
  }

  // Get orders by user
  List<Order> getOrdersByUser(String userId) {
    return _orders.where((order) => order.userId == userId).toList();
  }

  // Get total by user
  double getTotalByUser(String userId) {
    double total = 0.0;
    for (var order in _orders) {
      if (order.userId == userId) {
        total += order.price * order.quantity;
      }
    }
    return total;
  }

  // Get payment status for user
  bool isUserPaid(String userId) {
    for (var payment in _payments) {
      if (payment.userId == userId) {
        return payment.paid;
      }
    }
    return false;
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set loading
  void _setLoading(bool value) {
    _isLoading = value;
  }

  // Clear session
  void clearSession() {
    _currentSession = null;
    _orders = [];
    _payments = [];
    notifyListeners();
  }
}
