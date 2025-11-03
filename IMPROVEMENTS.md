# Breakfast Buddy - Improvement Roadmap

> Comprehensive guide for enhancing logic and design

**Last Updated**: November 2, 2025
**Current Assessment**: B+ (Good, Production-Ready with Improvements)
**Production Readiness**: 65%

---

## Table of Contents

- [Executive Summary](#executive-summary)
- [Critical Issues (Fix Immediately)](#critical-issues-fix-immediately)
- [Important Logic Enhancements](#important-logic-enhancements)
- [UI/UX Design Improvements](#uiux-design-improvements)
- [Architecture Refactoring](#architecture-refactoring)
- [Implementation Plan](#implementation-plan)
- [Quick Wins](#quick-wins)
- [Detailed Recommendations](#detailed-recommendations)
- [Priority Matrix](#priority-matrix)

---

## Executive Summary

### Overall Assessment

**Grade**: B+ (Good with room for improvement)

Your Breakfast Buddy app demonstrates **solid Flutter architecture** and **modern Firebase integration** with a polished UI. However, several critical areas need attention before full production deployment.

### Key Strengths ✅

- ✅ Clean architecture with proper separation of concerns
- ✅ Good use of Firebase for real-time collaboration
- ✅ Modern, polished Material 3 UI design
- ✅ Comprehensive features for team breakfast ordering
- ✅ Real-time updates work seamlessly
- ✅ Provider-based state management implemented correctly

### Critical Gaps ⚠️

- ❌ **No testing** (0% coverage)
- ❌ **No offline support** (app fails without internet)
- ❌ **Security rules need fixing** (blocking group features)
- ❌ **One restaurant per group** (major limitation)
- ❌ **Order modifiers not persisted** (UX issue)
- ❌ **Large, monolithic screen files** (maintenance issue)

---

## Critical Issues (Fix Immediately)

### 1. 🔒 Security Rules Problem

**File**: `firestore.rules:6`
**Severity**: CRITICAL
**Impact**: Blocks group member features

**Issue**:
```javascript
// Current (TOO RESTRICTIVE)
match /users/{userId} {
  allow read: if request.auth.uid == userId;  // ❌ Users can't see other members
  allow write: if request.auth.uid == userId;
}
```

Users can only read their own profile, preventing group member lists from displaying other users' information.

**Fix**:
```javascript
// Recommended
match /users/{userId} {
  allow read: if request.auth != null;  // ✅ All authenticated users can read
  allow write: if request.auth.uid == userId;

  // Only allow reading basic public profile fields
  allow get: if request.auth != null
    && request.resource.data.keys().hasOnly(['name', 'email', 'photoUrl']);
}
```

**Estimated Time**: 15 minutes
**Priority**: P0 (Critical)

---

### 2. 🔄 Dual Order System Confusion

**Files**:
- `lib/models/order.dart:5-6`
- `lib/services/database_service.dart:230`

**Severity**: CRITICAL
**Impact**: Data consistency issues, complex queries

**Issue**:
```dart
// Current model has BOTH sessionId and groupId
class Order {
  final String? sessionId;  // Legacy system
  final String? groupId;    // New system
  // ... causes confusion and complex queries
}
```

**Current Query Complexity**:
```dart
// database_service.dart - Complex query needed
Query query = ordersRef.where('groupId', isEqualTo: groupId);
// But some orders still use sessionId, requiring fallback logic
```

**Fix**:
1. **Migrate all existing orders** to use `groupId` only
2. **Remove `sessionId` field** completely
3. **Archive `orderSessions` collection** for historical data
4. **Simplify all queries**

**Migration Script Needed**:
```dart
Future<void> migrateOrdersToGroupSystem() async {
  // 1. Get all orders with sessionId but no groupId
  final ordersSnapshot = await FirebaseFirestore.instance
      .collection('orders')
      .where('sessionId', isNull: false)
      .where('groupId', isNull: true)
      .get();

  // 2. For each order, lookup the session's group and update
  for (var doc in ordersSnapshot.docs) {
    final sessionId = doc.data()['sessionId'];
    // Lookup logic and update
  }
}
```

**Estimated Time**: 4-6 hours (including migration script)
**Priority**: P0 (Critical)

---

### 3. 🍽️ One Restaurant Per Group Limitation

**File**: `lib/services/group_service.dart:238-244`
**Severity**: HIGH
**Impact**: Major feature limitation

**Current Code**:
```dart
Future<void> setGroupRestaurant(/* ... */) async {
  // Check if group already has a restaurant
  final existingRestaurant = await _db
      .collection('groupRestaurants')
      .where('groupId', isEqualTo: groupId)
      .limit(1)
      .get();

  if (existingRestaurant.docs.isNotEmpty) {
    throw Exception('Group already has a restaurant'); // ❌ HARD LIMIT
  }
  // ...
}
```

**Fix - Multi-Restaurant Support**:

**Option A: Simple (Keep one active restaurant)**
```dart
Future<void> setGroupRestaurant(/* ... */) async {
  // Don't check for existing - allow multiple
  // Just add 'isActive' field
  await _db.collection('groupRestaurants').add({
    // ...existing fields
    'isActive': true,
    'addedAt': FieldValue.serverTimestamp(),
  });
}

// Add method to switch active restaurant
Future<void> setActiveRestaurant(String groupId, String restaurantId) async {
  final batch = _db.batch();

  // Deactivate all restaurants
  final restaurants = await _db
      .collection('groupRestaurants')
      .where('groupId', isEqualTo: groupId)
      .get();

  for (var doc in restaurants.docs) {
    batch.update(doc.reference, {'isActive': doc.id == restaurantId});
  }

  await batch.commit();
}
```

**Option B: Advanced (Multiple restaurants per order)**
- Allow users to choose restaurant when ordering
- Each order has `restaurantId` field
- Group can aggregate orders from multiple restaurants

**Estimated Time**:
- Option A: 6-8 hours
- Option B: 12-16 hours

**Priority**: P0 (Critical - major business limitation)

---

### 4. 📱 No Offline Support

**Impact**: App completely unusable without internet

**Current Behavior**:
- Menu fetch fails → blank screen
- Orders don't load → app hangs
- No cached data displayed

**Fix**:

**Step 1: Enable Firestore Persistence**
```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(/* ... */);

  // ✅ Enable offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}
```

**Step 2: Add Local Menu Caching**
```dart
// lib/services/restaurant_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class RestaurantService {
  Future<List<MenuItem>> getMenuItems(String restaurantId) async {
    try {
      // Try fetching from API
      final items = await _fetchFromAPI(restaurantId);

      // ✅ Cache to local storage
      await _cacheMenuItems(restaurantId, items);
      return items;

    } catch (e) {
      // ✅ Fallback to cached data
      final cached = await _getCachedMenuItems(restaurantId);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<void> _cacheMenuItems(String id, List<MenuItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString('menu_$id', json);
  }

  Future<List<MenuItem>?> _getCachedMenuItems(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('menu_$id');
    if (json == null) return null;

    final list = jsonDecode(json) as List;
    return list.map((e) => MenuItem.fromJson(e)).toList();
  }
}
```

**Step 3: Add Connectivity Detection**
```dart
// pubspec.yaml
dependencies:
  connectivity_plus: ^5.0.2

// lib/utils/connectivity_utils.dart
class ConnectivityUtils {
  static Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Stream<bool> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }
}
```

**Step 4: Update UI for Offline Mode**
```dart
// Add banner when offline
class OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityUtils.onConnectivityChanged,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        if (isOnline) return const SizedBox.shrink();

        return MaterialBanner(
          content: const Text('You are offline. Showing cached data.'),
          backgroundColor: Colors.orange.shade100,
          actions: [
            TextButton(
              onPressed: () {/* Retry */},
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }
}
```

**Estimated Time**: 8-10 hours
**Priority**: P0 (Critical)

**Dependencies to Add**:
```yaml
dependencies:
  shared_preferences: ^2.2.2
  connectivity_plus: ^5.0.2
```

---

### 5. ❌ Zero Test Coverage

**Current State**:
- Only `test/widget_test.dart` exists (default Flutter template)
- No unit tests for services, models, or business logic
- No widget tests for custom components
- No integration tests

**Fix - Testing Strategy**:

**Step 1: Unit Tests for Models**
```dart
// test/models/order_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:breakfast_buddy/models/order.dart';

void main() {
  group('Order Model', () {
    test('should create order from JSON', () {
      final json = {
        'id': 'order123',
        'userId': 'user123',
        'userName': 'John Doe',
        'groupId': 'group123',
        'itemName': 'Pancakes',
        'price': 25.0,
        'quantity': 2,
        'createdAt': Timestamp.now(),
      };

      final order = Order.fromJson(json);

      expect(order.id, 'order123');
      expect(order.itemName, 'Pancakes');
      expect(order.totalPrice, 50.0);
    });

    test('should calculate total price correctly', () {
      final order = Order(
        id: 'test',
        userId: 'user1',
        userName: 'Test User',
        itemName: 'Coffee',
        price: 15.0,
        quantity: 3,
        createdAt: DateTime.now(),
      );

      expect(order.totalPrice, 45.0);
    });
  });
}
```

**Step 2: Unit Tests for Services**
```dart
// test/services/group_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:breakfast_buddy/services/group_service.dart';

void main() {
  late GroupService groupService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    groupService = GroupService(firestore: fakeFirestore);
  });

  group('GroupService', () {
    test('should create group successfully', () async {
      final groupId = await groupService.createGroup(
        name: 'Test Group',
        description: 'Test Description',
        adminId: 'admin123',
        adminName: 'Admin User',
      );

      expect(groupId, isNotNull);

      final doc = await fakeFirestore.collection('groups').doc(groupId).get();
      expect(doc.exists, true);
      expect(doc.data()?['name'], 'Test Group');
    });
  });
}
```

**Step 3: Widget Tests**
```dart
// test/widgets/order_card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:breakfast_buddy/widgets/order_card.dart';

void main() {
  testWidgets('OrderCard displays order information', (tester) async {
    final order = Order(/* ... */);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderCard(order: order),
        ),
      ),
    );

    expect(find.text('Pancakes'), findsOneWidget);
    expect(find.text('50.0 SAR'), findsOneWidget);
  });
}
```

**Step 4: Integration Tests**
```dart
// integration_test/order_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete order flow', (tester) async {
    // 1. Login
    // 2. Navigate to group
    // 3. Select menu item
    // 4. Place order
    // 5. Verify order appears
  });
}
```

**Required Dependencies**:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.8
  fake_cloud_firestore: ^2.4.6
  integration_test:
    sdk: flutter
```

**Test Coverage Goal**: 60%+

**Estimated Time**: 16-20 hours
**Priority**: P0 (Critical for production)

---

## Important Logic Enhancements

### 6. 📝 Missing Order Modifiers

**Files**:
- `lib/models/menu_item.dart` (has modifiers)
- `lib/models/order.dart` (missing modifiers)

**Issue**:
Menu items display modifier groups (extra cheese, size options, etc.), but when users place orders, **selected modifiers aren't saved**.

**Current State**:
```dart
// lib/models/order.dart
class Order {
  final String itemName;
  final double price;
  final int quantity;
  // ❌ No field for selected modifiers
}
```

**Fix**:

**Step 1: Update Order Model**
```dart
// lib/models/order.dart
class Order {
  final String id;
  final String userId;
  final String userName;
  final String? groupId;
  final String itemName;
  final double basePrice;
  final int quantity;
  final List<SelectedModifier>? selectedModifiers;  // ✅ NEW
  final String? imageUrl;
  final String? notes;
  final DateTime createdAt;

  // ✅ NEW: Calculate total with modifiers
  double get totalPrice {
    double modifierTotal = 0;
    if (selectedModifiers != null) {
      for (var modifier in selectedModifiers!) {
        modifierTotal += modifier.price;
      }
    }
    return (basePrice + modifierTotal) * quantity;
  }

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    this.groupId,
    required this.itemName,
    required this.basePrice,
    required this.quantity,
    this.selectedModifiers,
    this.imageUrl,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'groupId': groupId,
    'itemName': itemName,
    'basePrice': basePrice,
    'quantity': quantity,
    'selectedModifiers': selectedModifiers?.map((m) => m.toJson()).toList(),  // ✅ NEW
    'imageUrl': imageUrl,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      groupId: json['groupId'] as String?,
      itemName: json['itemName'] as String,
      basePrice: (json['basePrice'] ?? json['price'] ?? 0).toDouble(),  // Backward compatible
      quantity: json['quantity'] as int? ?? 1,
      selectedModifiers: (json['selectedModifiers'] as List?)
          ?.map((m) => SelectedModifier.fromJson(m))
          .toList(),  // ✅ NEW
      imageUrl: json['imageUrl'] as String?,
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }
}

// ✅ NEW: Model for selected modifiers
class SelectedModifier {
  final String modifierId;
  final String modifierName;
  final double price;

  SelectedModifier({
    required this.modifierId,
    required this.modifierName,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'modifierId': modifierId,
    'modifierName': modifierName,
    'price': price,
  };

  factory SelectedModifier.fromJson(Map<String, dynamic> json) {
    return SelectedModifier(
      modifierId: json['modifierId'] as String,
      modifierName: json['modifierName'] as String,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}
```

**Step 2: Update UI to Collect Modifiers**
```dart
// lib/screens/groups/menu_item_detail_screen.dart (NEW FILE)
class MenuItemDetailScreen extends StatefulWidget {
  final MenuItem menuItem;

  @override
  State<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  final List<SelectedModifier> _selectedModifiers = [];
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.menuItem.name['en'] ?? '')),
      body: Column(
        children: [
          // Item image and description

          // ✅ Modifier selection UI
          ...widget.menuItem.modifierGroups.map((group) {
            return ModifierGroupWidget(
              group: group,
              onModifierSelected: (modifier) {
                setState(() {
                  _selectedModifiers.add(SelectedModifier(
                    modifierId: modifier.id,
                    modifierName: modifier.name['en'] ?? '',
                    price: modifier.price,
                  ));
                });
              },
            );
          }),

          // Quantity selector

          // Total price (with modifiers)
          Text('Total: ${_calculateTotal()} SAR'),

          // Add to order button
          ElevatedButton(
            onPressed: () => _addToOrder(),
            child: const Text('Add to Order'),
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    double base = widget.menuItem.price;
    double modifierTotal = _selectedModifiers.fold(0, (sum, m) => sum + m.price);
    return (base + modifierTotal) * _quantity;
  }

  Future<void> _addToOrder() async {
    final order = Order(
      id: '',
      userId: context.read<AuthProvider>().user!.uid,
      userName: context.read<AuthProvider>().user!.displayName ?? '',
      groupId: widget.groupId,
      itemName: widget.menuItem.name['en'] ?? '',
      basePrice: widget.menuItem.price,
      quantity: _quantity,
      selectedModifiers: _selectedModifiers,  // ✅ Include modifiers
      createdAt: DateTime.now(),
    );

    await context.read<OrderProvider>().createOrder(order);
    Navigator.pop(context);
  }
}
```

**Step 3: Display Modifiers in Order History**
```dart
// lib/widgets/order_card.dart - Update to show modifiers
class OrderCard extends StatelessWidget {
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(order.itemName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Base: ${order.basePrice} SAR'),

            // ✅ Show selected modifiers
            if (order.selectedModifiers != null && order.selectedModifiers!.isNotEmpty)
              ...order.selectedModifiers!.map((modifier) {
                return Text(
                  '  + ${modifier.modifierName} (+${modifier.price} SAR)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                );
              }),

            Text('Quantity: ${order.quantity}'),
            Text('Total: ${order.totalPrice} SAR',
                 style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
```

**Estimated Time**: 8-10 hours
**Priority**: P1 (High - affects UX)

---

### 7. ✏️ No Order Editing

**Current Behavior**:
Users must **delete and recreate** orders to change quantity, notes, or modifiers.

**Fix**:

**Step 1: Add Edit Method to OrderProvider**
```dart
// lib/providers/order_provider.dart
class OrderProvider extends ChangeNotifier {
  // ... existing code

  Future<void> updateOrder(Order updatedOrder) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _db.collection('orders').doc(updatedOrder.id).update(
        updatedOrder.toJson(),
      );

      AppLogger.log('Order updated successfully: ${updatedOrder.id}');

    } catch (e) {
      _errorMessage = 'Failed to update order: $e';
      AppLogger.log('Error updating order: $e', isError: true);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

**Step 2: Add Edit UI**
```dart
// Update OrderCard widget to show edit button
class OrderCard extends StatelessWidget {
  final Order order;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user!.uid;
    final canEdit = order.userId == currentUserId;  // Only owner can edit

    return Card(
      child: ListTile(
        title: Text(order.itemName),
        subtitle: Text('${order.quantity} × ${order.basePrice} SAR'),
        trailing: canEdit ? IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditDialog(context),
        ) : null,
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final quantityController = TextEditingController(
      text: order.quantity.toString(),
    );
    final notesController = TextEditingController(text: order.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedOrder = Order(
                id: order.id,
                userId: order.userId,
                userName: order.userName,
                groupId: order.groupId,
                itemName: order.itemName,
                basePrice: order.basePrice,
                quantity: int.tryParse(quantityController.text) ?? 1,
                selectedModifiers: order.selectedModifiers,
                imageUrl: order.imageUrl,
                notes: notesController.text.isEmpty ? null : notesController.text,
                createdAt: order.createdAt,
              );

              await context.read<OrderProvider>().updateOrder(updatedOrder);
              Navigator.pop(context, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order updated successfully')),
      );
    }
  }
}
```

**Estimated Time**: 4-6 hours
**Priority**: P1 (High - UX improvement)

---

### 8. 📊 No Order Workflow States

**Current Issue**:
Orders are either "created" or "deleted". No tracking of:
- Pending confirmation
- Confirmed by admin
- Being prepared
- Ready for pickup
- Delivered

**Fix**:

**Step 1: Add OrderStatus Enum**
```dart
// lib/models/order_status.dart
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.grey;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.check_circle;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }
}
```

**Step 2: Update Order Model**
```dart
// lib/models/order.dart
class Order {
  // ... existing fields
  final OrderStatus status;
  final DateTime? statusUpdatedAt;
  final String? statusUpdatedBy;

  Order({
    // ... existing parameters
    this.status = OrderStatus.pending,  // ✅ Default to pending
    this.statusUpdatedAt,
    this.statusUpdatedBy,
  });

  Map<String, dynamic> toJson() => {
    // ... existing fields
    'status': status.name,
    'statusUpdatedAt': statusUpdatedAt != null
        ? Timestamp.fromDate(statusUpdatedAt!)
        : null,
    'statusUpdatedBy': statusUpdatedBy,
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      // ... existing fields
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      statusUpdatedAt: json['statusUpdatedAt'] != null
          ? (json['statusUpdatedAt'] as Timestamp).toDate()
          : null,
      statusUpdatedBy: json['statusUpdatedBy'] as String?,
    );
  }
}
```

**Step 3: Add Status Update Methods**
```dart
// lib/providers/order_provider.dart
class OrderProvider extends ChangeNotifier {
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    required String updatedBy,
  }) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus.name,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': updatedBy,
      });

      AppLogger.log('Order status updated: $orderId -> ${newStatus.name}');

      // ✅ Optional: Send notification to user
      // await _sendStatusNotification(orderId, newStatus);

    } catch (e) {
      AppLogger.log('Error updating order status: $e', isError: true);
      rethrow;
    }
  }

  // Bulk status update for admin
  Future<void> updateAllOrdersStatus({
    required String groupId,
    required OrderStatus newStatus,
    required String updatedBy,
  }) async {
    try {
      final orders = await _db
          .collection('orders')
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: OrderStatus.pending.name)
          .get();

      final batch = _db.batch();

      for (var doc in orders.docs) {
        batch.update(doc.reference, {
          'status': newStatus.name,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
          'statusUpdatedBy': updatedBy,
        });
      }

      await batch.commit();
      AppLogger.log('Bulk status update: ${orders.size} orders');

    } catch (e) {
      AppLogger.log('Error bulk updating orders: $e', isError: true);
      rethrow;
    }
  }
}
```

**Step 4: Add Admin Status Control UI**
```dart
// lib/screens/orders/order_status_management_screen.dart
class OrderStatusManagementScreen extends StatelessWidget {
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Order Status')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('groupId', isEqualTo: groupId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs
              .map((doc) => Order.fromJson(doc.data() as Map<String, dynamic>))
              .toList();

          // Group orders by status
          final ordersByStatus = <OrderStatus, List<Order>>{};
          for (var order in orders) {
            ordersByStatus.putIfAbsent(order.status, () => []).add(order);
          }

          return ListView(
            children: [
              // Bulk actions for admin
              _buildBulkActionsCard(context),

              // Orders grouped by status
              ...OrderStatus.values.map((status) {
                final statusOrders = ordersByStatus[status] ?? [];
                if (statusOrders.isEmpty) return const SizedBox.shrink();

                return ExpansionTile(
                  leading: Icon(status.icon, color: status.color),
                  title: Text('${status.displayName} (${statusOrders.length})'),
                  children: statusOrders.map((order) {
                    return OrderStatusCard(
                      order: order,
                      onStatusChanged: (newStatus) async {
                        await context.read<OrderProvider>().updateOrderStatus(
                          orderId: order.id,
                          newStatus: newStatus,
                          updatedBy: context.read<AuthProvider>().user!.uid,
                        );
                      },
                    );
                  }).toList(),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBulkActionsCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bulk Actions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Confirm All'),
                  onPressed: () => _bulkUpdateStatus(context, OrderStatus.confirmed),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Mark Preparing'),
                  onPressed: () => _bulkUpdateStatus(context, OrderStatus.preparing),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark Delivered'),
                  onPressed: () => _bulkUpdateStatus(context, OrderStatus.delivered),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkUpdateStatus(BuildContext context, OrderStatus status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Update'),
        content: Text('Mark all pending orders as "${status.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<OrderProvider>().updateAllOrdersStatus(
        groupId: groupId,
        newStatus: status,
        updatedBy: context.read<AuthProvider>().user!.uid,
      );
    }
  }
}
```

**Estimated Time**: 10-12 hours
**Priority**: P1 (High - improves tracking)

---

### 9. 💳 Manual Payment Tracking

**Current State**:
- Admin manually marks payments as paid
- No payment gateway integration
- No automated reminders

**Fix Options**:

**Option A: Payment Gateway Integration (Stripe)**

```yaml
# pubspec.yaml
dependencies:
  flutter_stripe: ^10.1.1
```

```dart
// lib/services/payment_service.dart
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentService {
  Future<void> initializeStripe() async {
    Stripe.publishableKey = 'pk_test_...';
  }

  Future<PaymentIntent> createPaymentIntent({
    required double amount,
    required String currency,
  }) async {
    // Call your backend to create payment intent
    final response = await http.post(
      Uri.parse('YOUR_BACKEND_URL/create-payment-intent'),
      body: {
        'amount': (amount * 100).toInt().toString(), // Stripe uses cents
        'currency': currency,
      },
    );

    final jsonResponse = jsonDecode(response.body);
    return PaymentIntent.fromJson(jsonResponse);
  }

  Future<bool> processPayment({
    required String paymentId,
    required double amount,
  }) async {
    try {
      // 1. Create payment intent
      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: 'sar',
      );

      // 2. Present payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent.clientSecret,
          merchantDisplayName: 'Breakfast Buddy',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // 3. Update Firestore
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentId)
          .update({
        'paid': true,
        'paidAt': FieldValue.serverTimestamp(),
        'paymentMethod': 'stripe',
      });

      return true;

    } catch (e) {
      AppLogger.log('Payment failed: $e', isError: true);
      return false;
    }
  }
}
```

**Option B: Payment Reminders (Simpler)**

```dart
// lib/services/notification_service.dart
class NotificationService {
  Future<void> sendPaymentReminder({
    required String userId,
    required double amount,
    required String groupName,
  }) async {
    // Using Firebase Cloud Messaging
    await FirebaseMessaging.instance.sendMessage(
      to: userId,
      data: {
        'type': 'payment_reminder',
        'amount': amount.toString(),
        'groupName': groupName,
      },
    );
  }

  Future<void> schedulePaymentReminders() async {
    // Get all unpaid payments older than 3 days
    final unpaidPayments = await FirebaseFirestore.instance
        .collection('payments')
        .where('paid', isEqualTo: false)
        .where('createdAt', isLessThan: DateTime.now().subtract(const Duration(days: 3)))
        .get();

    for (var doc in unpaidPayments.docs) {
      final payment = Payment.fromJson(doc.data());
      await sendPaymentReminder(
        userId: payment.userId,
        amount: payment.amount,
        groupName: 'Your Group',  // Fetch from group
      );
    }
  }
}
```

**Estimated Time**:
- Stripe Integration: 20-24 hours
- Payment Reminders: 8-10 hours

**Priority**: P2 (Medium - nice to have)

---

## UI/UX Design Improvements

### 10. 🗂️ Monolithic Screen Files

**Issue**:
- `lib/screens/groups/group_details_screen.dart` (816 lines, 70KB)
- `lib/screens/groups/group_menu_screen.dart` (34KB)

**Fix - Component Extraction**:

**Before** (group_details_screen.dart):
```dart
class GroupDetailsScreen extends StatefulWidget {
  // 816 lines of code
  // Everything in one file
}
```

**After** - Break into components:

```
lib/screens/groups/
  ├── group_details_screen.dart (main orchestrator - 200 lines)
  └── widgets/
      ├── group_header_card.dart
      ├── group_stats_card.dart
      ├── active_orders_section.dart
      ├── member_list_section.dart
      ├── restaurant_info_card.dart
      └── group_actions_bar.dart
```

**Example Refactoring**:

```dart
// lib/screens/groups/widgets/group_header_card.dart
class GroupHeaderCard extends StatelessWidget {
  final Group group;
  final VoidCallback onSettingsTap;

  const GroupHeaderCard({
    required this.group,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: onSettingsTap,
                ),
              ],
            ),
            if (group.description != null) ...[
              const SizedBox(height: 8),
              Text(group.description!),
            ],
            const SizedBox(height: 16),
            _buildGroupInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfo() {
    return Row(
      children: [
        Icon(Icons.people, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text('${group.memberIds.length} members'),
        const SizedBox(width: 16),
        Icon(
          group.isActive ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: group.isActive ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(group.isActive ? 'Active' : 'Inactive'),
      ],
    );
  }
}

// lib/screens/groups/group_details_screen.dart (REFACTORED)
class GroupDetailsScreen extends StatefulWidget {
  final String groupId;

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final group = groupProvider.currentGroup;

    if (group == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: RefreshIndicator(
        onRefresh: () => groupProvider.loadGroup(widget.groupId),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ✅ Clean, component-based structure
            GroupHeaderCard(
              group: group,
              onSettingsTap: () => _navigateToSettings(),
            ),
            const SizedBox(height: 16),
            GroupStatsCard(groupId: widget.groupId),
            const SizedBox(height: 16),
            RestaurantInfoCard(groupId: widget.groupId),
            const SizedBox(height: 16),
            ActiveOrdersSection(groupId: widget.groupId),
            const SizedBox(height: 16),
            MemberListSection(group: group),
          ],
        ),
      ),
      bottomNavigationBar: GroupActionsBar(
        group: group,
        onOrderTap: () => _navigateToMenu(),
        onPaymentsTap: () => _navigateToPayments(),
      ),
    );
  }

  // Simple navigation methods
  void _navigateToSettings() { /* ... */ }
  void _navigateToMenu() { /* ... */ }
  void _navigateToPayments() { /* ... */ }
}
```

**Benefits**:
- ✅ Easier to test individual components
- ✅ Better code reusability
- ✅ Improved maintainability
- ✅ Faster hot reload during development

**Estimated Time**: 12-16 hours (for all large screens)
**Priority**: P2 (Medium - maintainability)

---

### 11. 🧭 Navigation Improvements

**Current Issues**:
- No named routes (all imperative `Navigator.push`)
- Deep navigation stacks
- No persistent bottom navigation
- Hard to implement deep linking

**Fix**:

**Step 1: Define Named Routes**
```dart
// lib/routes/app_routes.dart
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String groupDetails = '/group/:groupId';
  static const String groupMenu = '/group/:groupId/menu';
  static const String groupSettings = '/group/:groupId/settings';
  static const String profile = '/profile';
  static const String payments = '/payments';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const MainScreen());

      case groupDetails:
        final groupId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => GroupDetailsScreen(groupId: groupId),
        );

      // ... more routes

      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundScreen(),
        );
    }
  }
}
```

**Step 2: Update main.dart**
```dart
// lib/main.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breakfast Buddy',
      theme: /* ... */,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,  // ✅ Named routes
    );
  }
}
```

**Step 3: Add Bottom Navigation**
```dart
// lib/screens/main_screen.dart
class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const GroupListScreen(),
    const PaymentsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment),
            label: 'Payments',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

**Estimated Time**: 8-10 hours
**Priority**: P2 (Medium - UX improvement)

---

### 12. 🔍 Search & Filter Features

**Missing Features**:
- No search for menu items
- No category filtering
- No allergen filtering
- No price range filtering

**Fix**:

```dart
// lib/screens/groups/group_menu_screen.dart - Add search
class GroupMenuScreen extends StatefulWidget {
  @override
  State<GroupMenuScreen> createState() => _GroupMenuScreenState();
}

class _GroupMenuScreenState extends State<GroupMenuScreen> {
  String _searchQuery = '';
  Set<String> _selectedCategories = {};
  Set<String> _selectedAllergens = {};
  double _maxPrice = double.infinity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFilterDialog(),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          final allItems = provider.menuItems;
          final filteredItems = _filterItems(allItems);

          if (filteredItems.isEmpty) {
            return const Center(
              child: Text('No items found'),
            );
          }

          return ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              return MenuItemCard(item: filteredItems[index]);
            },
          );
        },
      ),
    );
  }

  List<MenuItem> _filterItems(List<MenuItem> items) {
    return items.where((item) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = item.name['en']?.toLowerCase() ?? '';
        final description = item.description['en']?.toLowerCase() ?? '';
        if (!name.contains(_searchQuery) &&
            !description.contains(_searchQuery)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategories.isNotEmpty) {
        if (!_selectedCategories.contains(item.categoryId)) {
          return false;
        }
      }

      // Allergen filter (exclude items with selected allergens)
      if (_selectedAllergens.isNotEmpty) {
        if (item.allergens.any((a) => _selectedAllergens.contains(a))) {
          return false;
        }
      }

      // Price filter
      if (item.price > _maxPrice) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => FilterDialog(
        selectedCategories: _selectedCategories,
        selectedAllergens: _selectedAllergens,
        maxPrice: _maxPrice,
        onApply: (categories, allergens, maxPrice) {
          setState(() {
            _selectedCategories = categories;
            _selectedAllergens = allergens;
            _maxPrice = maxPrice;
          });
        },
      ),
    );
  }
}
```

**Estimated Time**: 6-8 hours
**Priority**: P2 (Medium - UX improvement)

---

### 13. ⏳ Loading State Improvements

**Current**: Basic `CircularProgressIndicator`
**Improvement**: Skeleton loaders

```yaml
# pubspec.yaml
dependencies:
  skeletons: ^0.0.3
```

```dart
// lib/widgets/skeleton_menu_item.dart
class SkeletonMenuItemCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SkeletonAvatar(
              style: SkeletonAvatarStyle(
                width: 80,
                height: 80,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(
                    style: SkeletonLineStyle(
                      height: 20,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLine(
                    style: SkeletonLineStyle(
                      height: 16,
                      width: 150,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLine(
                    style: SkeletonLineStyle(
                      height: 16,
                      width: 80,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Usage in menu screen
Widget build(BuildContext context) {
  return Consumer<RestaurantProvider>(
    builder: (context, provider, child) {
      if (provider.isLoading) {
        return ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => SkeletonMenuItemCard(),
        );
      }

      // ... show actual items
    },
  );
}
```

**Estimated Time**: 4-6 hours
**Priority**: P3 (Low - polish)

---

### 14. 🔔 Push Notifications

**Fix**:

```yaml
# pubspec.yaml
dependencies:
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.0
```

```dart
// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Get FCM token
    final token = await _messaging.getToken();
    await _saveTokenToFirestore(token);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'breakfast_buddy',
          'Breakfast Buddy',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'fcmToken': token});
  }

  // Send notification when order is confirmed
  Future<void> sendOrderConfirmationNotification({
    required String userId,
    required String orderId,
  }) async {
    // Get user's FCM token
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final token = userDoc.data()?['fcmToken'] as String?;
    if (token == null) return;

    // This should be done via Cloud Functions in production
    // For now, you'd call your backend API
  }
}

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
}
```

**Cloud Function** (to send notifications):
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onOrderStatusChanged = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if status changed
    if (before.status === after.status) return;

    // Get user's FCM token
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(after.userId)
      .get();

    const token = userDoc.data()?.fcmToken;
    if (!token) return;

    // Send notification
    await admin.messaging().send({
      token: token,
      notification: {
        title: 'Order Status Update',
        body: `Your order is now ${after.status}`,
      },
      data: {
        orderId: context.params.orderId,
        status: after.status,
      },
    });
  });
```

**Estimated Time**: 12-16 hours
**Priority**: P2 (Medium - engagement)

---

## Architecture Refactoring

### 15. 🔨 Split DatabaseService

**Current**: `lib/services/database_service.dart` (565 lines)

**Issue**: Single service handles orders, payments, users, sessions

**Fix**:

**Create specialized services**:

```
lib/services/
  ├── database_service.dart (DEPRECATED - keep for backward compat)
  ├── order_service.dart       ✅ NEW
  ├── payment_service.dart     ✅ NEW
  ├── user_service.dart        ✅ NEW
  └── session_service.dart     ✅ NEW (if keeping sessions)
```

**Example**:
```dart
// lib/services/order_service.dart
class OrderService {
  final FirebaseFirestore _db;

  OrderService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // Create order
  Future<String> createOrder(Order order) async {
    final docRef = await _db.collection('orders').add(order.toJson());
    return docRef.id;
  }

  // Get orders for group
  Stream<List<Order>> getGroupOrders(String groupId) {
    return _db
        .collection('orders')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Order.fromJson(doc.data()))
            .toList());
  }

  // Update order
  Future<void> updateOrder(Order order) async {
    await _db.collection('orders').doc(order.id).update(order.toJson());
  }

  // Delete order
  Future<void> deleteOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).delete();
  }

  // Get user's order history
  Future<List<Order>> getUserOrderHistory(String userId, {int limit = 50}) async {
    final snapshot = await _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => Order.fromJson(doc.data())).toList();
  }
}

// lib/services/payment_service.dart
class PaymentService {
  final FirebaseFirestore _db;

  PaymentService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<String> createPayment(Payment payment) async {
    final docRef = await _db.collection('payments').add(payment.toJson());
    return docRef.id;
  }

  Future<void> markAsPaid(String paymentId) async {
    await _db.collection('payments').doc(paymentId).update({
      'paid': true,
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Payment>> getUserPayments(String userId) {
    return _db
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Payment.fromJson(doc.data()))
            .toList());
  }

  Future<Map<String, double>> getPaymentStats(String userId) async {
    final payments = await _db
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .get();

    double total = 0;
    double paid = 0;

    for (var doc in payments.docs) {
      final payment = Payment.fromJson(doc.data());
      total += payment.amount;
      if (payment.paid) {
        paid += payment.amount;
      }
    }

    return {
      'total': total,
      'paid': paid,
      'unpaid': total - paid,
    };
  }
}
```

**Update Providers to use new services**:
```dart
// lib/providers/order_provider.dart
class OrderProvider extends ChangeNotifier {
  final OrderService _orderService;

  OrderProvider({OrderService? orderService})
      : _orderService = orderService ?? OrderService();

  Future<void> createOrder(Order order) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _orderService.createOrder(order);  // ✅ Use service

    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

**Benefits**:
- ✅ Single responsibility principle
- ✅ Easier to test (mock individual services)
- ✅ Better code organization
- ✅ Parallel development (different devs work on different services)

**Estimated Time**: 10-12 hours
**Priority**: P2 (Medium - maintainability)

---

### 16. 🎭 State Management Evolution

**Current**: Provider with multiple loading states

**Option A: Stick with Provider + Freezed**
```yaml
dependencies:
  freezed_annotation: ^2.4.1

dev_dependencies:
  build_runner: ^2.4.8
  freezed: ^2.4.7
```

```dart
// lib/models/order_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_state.freezed.dart';

@freezed
class OrderState with _$OrderState {
  const factory OrderState.initial() = _Initial;
  const factory OrderState.loading() = _Loading;
  const factory OrderState.loaded(List<Order> orders) = _Loaded;
  const factory OrderState.error(String message) = _Error;
}

// lib/providers/order_provider.dart
class OrderProvider extends ChangeNotifier {
  OrderState _state = const OrderState.initial();
  OrderState get state => _state;

  Future<void> loadOrders(String groupId) async {
    _state = const OrderState.loading();
    notifyListeners();

    try {
      final orders = await _orderService.getOrders(groupId);
      _state = OrderState.loaded(orders);
    } catch (e) {
      _state = OrderState.error(e.toString());
    }

    notifyListeners();
  }
}

// UI
Widget build(BuildContext context) {
  final state = context.watch<OrderProvider>().state;

  return state.when(
    initial: () => const SizedBox.shrink(),
    loading: () => const CircularProgressIndicator(),
    loaded: (orders) => OrderList(orders: orders),
    error: (message) => ErrorWidget(message: message),
  );
}
```

**Option B: Migrate to Riverpod**
```yaml
dependencies:
  flutter_riverpod: ^2.4.10
```

```dart
// lib/providers/order_provider.dart
final orderServiceProvider = Provider((ref) => OrderService());

final groupOrdersProvider = StreamProvider.family<List<Order>, String>((ref, groupId) {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getGroupOrders(groupId);
});

// UI
class OrderListScreen extends ConsumerWidget {
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(groupOrdersProvider(groupId));

    return ordersAsync.when(
      data: (orders) => OrderList(orders: orders),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error: error),
    );
  }
}
```

**Estimated Time**:
- Freezed: 8-10 hours
- Riverpod: 16-20 hours

**Priority**: P3 (Low - nice to have)

---

## Implementation Plan

### Phase 1: Critical Fixes (1-2 days)
**Must do before production**

- [ ] Fix Firestore security rules (15 min)
- [ ] Enable offline support - Firestore persistence (2 hours)
- [ ] Add menu caching (4 hours)
- [ ] Add connectivity detection (2 hours)
- [ ] Consolidate order system (remove sessionId) (6 hours)
- [ ] Basic unit tests for models (4 hours)

**Total**: ~18 hours

---

### Phase 2: Core Enhancements (3-5 days)
**Major feature improvements**

- [ ] Multi-restaurant support (8 hours)
- [ ] Order modifier persistence (10 hours)
- [ ] Order editing functionality (6 hours)
- [ ] Order status workflow (12 hours)
- [ ] Payment reminders (8 hours)

**Total**: ~44 hours

---

### Phase 3: UX Polish (2-3 days)
**User experience improvements**

- [ ] Break up large screen files (16 hours)
- [ ] Implement named routes (4 hours)
- [ ] Add bottom navigation (4 hours)
- [ ] Add search and filters (8 hours)
- [ ] Skeleton loaders (6 hours)
- [ ] Favorites/templates (8 hours)

**Total**: ~46 hours

---

### Phase 4: Testing & Quality (2-3 days)
**Production readiness**

- [ ] Unit tests for services (12 hours)
- [ ] Widget tests for components (8 hours)
- [ ] Integration tests (8 hours)
- [ ] Split DatabaseService (12 hours)
- [ ] Extract shared widgets (6 hours)
- [ ] Code documentation (4 hours)

**Total**: ~50 hours

---

### Phase 5: Advanced Features (3-4 days)
**Nice to have features**

- [ ] Push notifications setup (16 hours)
- [ ] Analytics dashboard (12 hours)
- [ ] Payment gateway (Stripe) (24 hours)
- [ ] Complete i18n/RTL support (8 hours)
- [ ] Accessibility improvements (8 hours)

**Total**: ~68 hours

---

## Quick Wins

**Start here for immediate impact (< 2 hours each)**:

### 1. Fix Security Rules ⚡ (15 minutes)
```javascript
// firestore.rules
match /users/{userId} {
  allow read: if request.auth != null;  // ✅ Fixed
  allow write: if request.auth.uid == userId;
}
```

### 2. Enable Offline Persistence ⚡ (5 minutes)
```dart
// lib/main.dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
);
```

### 3. Add Currency Configuration ⚡ (30 minutes)
```dart
// lib/config/app_config.dart
class AppConfig {
  static const String currency = 'SAR';
  static const String currencySymbol = 'ر.س';
  static const String locale = 'ar_SA';

  static String formatCurrency(double amount) {
    return '$amount $currencySymbol';
  }
}
```

### 4. Extract Theme Toggle Widget ⚡ (1 hour)
```dart
// lib/widgets/theme_toggle.dart
class ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return IconButton(
      icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
      onPressed: () => themeProvider.toggleTheme(),
      tooltip: 'Toggle theme',
    );
  }
}
```

### 5. Add Loading Indicator Helper ⚡ (30 minutes)
```dart
// lib/utils/loading_utils.dart
class LoadingUtils {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
```

### 6. Add Error Dialog Helper ⚡ (30 minutes)
```dart
// lib/utils/dialog_utils.dart
class DialogUtils {
  static Future<void> showError(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
```

---

## Priority Matrix

### P0 - Critical (Do First)
Must be fixed before production deployment.

| Issue | Impact | Effort | Priority |
|-------|--------|--------|----------|
| Fix Security Rules | HIGH | 15 min | 🔴 P0 |
| Offline Support | HIGH | 10 hours | 🔴 P0 |
| Zero Test Coverage | HIGH | 20 hours | 🔴 P0 |
| Dual Order System | MEDIUM | 6 hours | 🔴 P0 |
| Multi-Restaurant | HIGH | 8 hours | 🔴 P0 |

### P1 - High Priority
Important for good user experience.

| Issue | Impact | Effort | Priority |
|-------|--------|--------|----------|
| Order Modifiers | MEDIUM | 10 hours | 🟠 P1 |
| Order Editing | MEDIUM | 6 hours | 🟠 P1 |
| Order Status Workflow | MEDIUM | 12 hours | 🟠 P1 |
| Search & Filter | MEDIUM | 8 hours | 🟠 P1 |

### P2 - Medium Priority
Nice to have for production.

| Issue | Impact | Effort | Priority |
|-------|--------|--------|----------|
| Refactor Large Files | LOW | 16 hours | 🟡 P2 |
| Named Routes | LOW | 8 hours | 🟡 P2 |
| Push Notifications | MEDIUM | 16 hours | 🟡 P2 |
| Split Services | LOW | 12 hours | 🟡 P2 |
| Payment Integration | MEDIUM | 24 hours | 🟡 P2 |

### P3 - Low Priority
Polish and future enhancements.

| Issue | Impact | Effort | Priority |
|-------|--------|--------|----------|
| Skeleton Loaders | LOW | 6 hours | 🟢 P3 |
| Favorites/Templates | LOW | 8 hours | 🟢 P3 |
| State Management Evolution | LOW | 20 hours | 🟢 P3 |
| Advanced Analytics | LOW | 12 hours | 🟢 P3 |

---

## Next Steps

1. **Review this document** with your team
2. **Prioritize** which improvements to tackle first
3. **Create GitHub issues** for each improvement (optional)
4. **Start with Quick Wins** for immediate impact
5. **Follow Phase 1** for critical fixes
6. **Iterate** through subsequent phases

---

## Conclusion

Your **Breakfast Buddy** app has a solid foundation with good architecture and modern design. The main areas needing attention are:

1. **Testing** - Critical for production
2. **Offline Support** - Essential for reliability
3. **Feature Limitations** - Multi-restaurant, modifiers, order editing
4. **Code Organization** - Break up large files, split services

With the improvements outlined in this document, your app will be **production-ready** and **scalable** for future growth.

**Estimated Total Time for All Improvements**: ~226 hours (~6 weeks for 1 developer)

**Minimum for Production (Phase 1 + critical P0 items)**: ~40 hours (~1 week)

Good luck with your improvements! 🚀
