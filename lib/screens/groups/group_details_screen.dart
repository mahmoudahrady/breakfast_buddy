import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/database_service.dart';
import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../models/group_restaurant.dart';
import '../../models/restaurant.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import 'package:intl/intl.dart';
import '../../widgets/currency_display.dart';
import '../../widgets/order_deadline_banner.dart';
import 'add_restaurant_to_group_screen.dart';
import '../restaurants/menu_screen.dart';
import 'group_invitation_dialog.dart';
import '../orders/order_confirmation_screen.dart';
import '../payments/split_calculator_screen.dart';
import 'group_insights_screen.dart';
import '../favorites/favorites_screen.dart';
import 'group_settings_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Defer the call to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadGroupDetails() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    groupProvider.selectGroup(widget.groupId);
  }

  void _copyGroupId() {
    Clipboard.setData(ClipboardData(text: widget.groupId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group ID copied to clipboard')),
    );
  }

  void _showInvitationDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (context) => GroupInvitationDialog(group: group),
    );
  }

  Future<void> _toggleGroupActiveStatus(
      GroupProvider groupProvider, Group? group) async {
    if (group == null) return;

    final newStatus = !group.isActive;
    final actionWord = newStatus ? 'activate' : 'deactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${actionWord[0].toUpperCase()}${actionWord.substring(1)} Group?'),
        content: Text(
          newStatus
              ? 'Members will be able to add orders when the group is active.'
              : 'Members will not be able to add orders when the group is inactive.\n\nThis is typically done after confirming all orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('${actionWord[0].toUpperCase()}${actionWord.substring(1)}'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await groupProvider.toggleGroupActiveStatus(
        widget.groupId,
        newStatus,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Group ${newStatus ? "activated" : "deactivated"} successfully',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update group status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAddRestaurant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddRestaurantToGroupScreen(groupId: widget.groupId),
      ),
    );

    if (result != null && mounted) {
      // Refresh the group details to update the restaurant list
      _loadGroupDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant added successfully!')),
      );
    }
  }

  void _navigateToRestaurantMenu(GroupRestaurant restaurant) async {
    // Check if the restaurant has an API URL
    if (restaurant.restaurantApiUrl == null || restaurant.restaurantApiUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant menu not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Create a Restaurant object from the GroupRestaurant data
      final restaurantObj = Restaurant(
        id: restaurant.restaurantId,
        name: restaurant.restaurantName,
        apiUrl: restaurant.restaurantApiUrl!,
        imageUrl: restaurant.restaurantImageUrl,
        description: restaurant.restaurantDescription,
      );

      // Select the restaurant in the provider
      await restaurantProvider.selectRestaurant(restaurantObj);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Navigate to the menu screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MenuScreen(
              groupId: widget.groupId,
              isGroupActive: groupProvider.selectedGroup?.isActive ?? true,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load menu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _leaveGroup() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await groupProvider.leaveGroup(
        groupId: widget.groupId,
        userId: authProvider.user!.id,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left group successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(groupProvider.errorMessage ?? 'Failed to leave group'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteGroup() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final group = groupProvider.selectedGroup;

    if (group == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"?\n\n'
          'This will permanently delete the group, all its restaurants, and all member records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await groupProvider.deleteGroup(widget.groupId);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(groupProvider.errorMessage ?? 'Failed to delete group'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final group = groupProvider.selectedGroup;

    if (groupProvider.isLoading || group == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin =
        authProvider.user != null && group.isAdmin(authProvider.user!.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: 'Group Insights',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupInsightsScreen(groupId: widget.groupId),
                ),
              );
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Group Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupSettingsScreen(groupId: widget.groupId),
                  ),
                );
              },
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.qr_code_2),
              tooltip: 'Invite Members',
              onPressed: () => _showInvitationDialog(context, group),
            ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Copy Group ID',
            onPressed: _copyGroupId,
          ),
          if (isAdmin)
            IconButton(
              icon: Icon(
                group?.isActive ?? true ? Icons.toggle_on : Icons.toggle_off,
                color: group?.isActive ?? true ? Colors.green : Colors.grey,
              ),
              tooltip: group?.isActive ?? true
                  ? 'Group is Active - Click to Deactivate'
                  : 'Group is Inactive - Click to Activate',
              onPressed: () => _toggleGroupActiveStatus(groupProvider, group),
            ),
          if (isAdmin)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Group', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteGroup();
                }
              },
            ),
          if (!isAdmin)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Leave Group', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'leave') {
                  _leaveGroup();
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Restaurants', icon: Icon(Icons.restaurant)),
            Tab(text: 'My Orders', icon: Icon(Icons.shopping_bag)),
            Tab(text: 'Orders', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Payments', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Group info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 16),
                    const SizedBox(width: 4),
                    Text('Admin: ${group.adminName}'),
                    const Spacer(),
                    Icon(Icons.people, size: 16),
                    const SizedBox(width: 4),
                    Text('${group.memberIds.length} members'),
                  ],
                ),
              ],
            ),
          ),

          // Deadline Banner
          if (group.orderDeadline != null && group.isActive && !group.isDeadlinePassed)
            OrderDeadlineBanner(deadline: group.orderDeadline!),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRestaurantsTab(groupProvider, isAdmin, group),
                _buildMyOrdersTab(groupProvider, isAdmin, group),
                _buildOrdersTab(groupProvider, isAdmin, group),
                _buildPaymentsTab(groupProvider, isAdmin, group),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin && groupProvider.restaurants.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddRestaurant,
              icon: const Icon(Icons.add),
              label: const Text('Add Restaurant'),
            )
          : null,
    );
  }

  Widget _buildRestaurantsTab(
      GroupProvider groupProvider, bool isAdmin, group) {
    if (groupProvider.restaurants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No Restaurants Yet',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Add restaurants to start ordering',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _navigateToAddRestaurant,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Restaurant'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupProvider.restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = groupProvider.restaurants[index];
        return _buildRestaurantCard(restaurant, isAdmin);
      },
    );
  }

  Widget _buildRestaurantCard(GroupRestaurant restaurant, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _navigateToRestaurantMenu(restaurant),
        leading: restaurant.restaurantImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  restaurant.restaurantImageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.restaurant),
                ),
              )
            : const CircleAvatar(
                child: Icon(Icons.restaurant),
              ),
        title: Text(
          restaurant.restaurantName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (restaurant.restaurantDescription != null) ...[
              const SizedBox(height: 4),
              Text(
                restaurant.restaurantDescription!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Added by ${restaurant.addedByName}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to view menu and order',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: isAdmin
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeleteRestaurant(restaurant),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _confirmDeleteRestaurant(GroupRestaurant restaurant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Restaurant'),
        content: Text(
            'Are you sure you want to remove ${restaurant.restaurantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final success = await groupProvider.removeRestaurant(restaurant.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Restaurant removed'
                : groupProvider.errorMessage ?? 'Failed to remove restaurant'),
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMyOrdersTab(GroupProvider groupProvider, bool isAdmin, Group? group) {
    final authProvider = Provider.of<AuthProvider>(context);
    final databaseService = DatabaseService();

    if (authProvider.user == null) {
      return const Center(child: Text('Please log in to view your orders'));
    }

    return StreamBuilder<List<Order>>(
      stream: databaseService.getOrdersForGroup(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Filter orders for current user
        final myOrders = (snapshot.data ?? [])
            .where((order) => order.userId == authProvider.user!.id)
            .toList();

    if (myOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No Orders Yet',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Go to Restaurants tab to place an order',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate total
    final total = myOrders.fold<double>(
        0.0, (sum, order) => sum + (order.price * order.quantity));

    return Column(
      children: [
        // Summary header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Orders',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${myOrders.length} ${myOrders.length == 1 ? 'item' : 'items'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  CurrencyDisplay(
                    amount: total,
                    textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    iconColor: Theme.of(context).colorScheme.primary,
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Favorites Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavoritesScreen(groupId: widget.groupId),
                  ),
                );
              },
              icon: const Icon(Icons.favorite),
              label: const Text('View My Favorites'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // Orders list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myOrders.length,
            itemBuilder: (context, index) {
              final order = myOrders[index];
              return _buildMyOrderCard(order, group);
            },
          ),
        ),
      ],
    );
      },
    );
  }

  Widget _buildMyOrderCard(Order order, Group? group) {
    final canDelete = group?.isActive ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: order.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  order.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 40),
                ),
              )
            : const CircleAvatar(
                child: Icon(Icons.fastfood),
              ),
        title: Text(
          order.itemName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Quantity: ${order.quantity}'),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(order.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            CurrencyDisplay(
              amount: order.price * order.quantity,
              textStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: 14,
            ),
          ],
        ),
        trailing: canDelete
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeleteOrder(order),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Confirmed',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _confirmDeleteOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to delete "${order.itemName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final success = await orderProvider.deleteOrder(order.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Order deleted'
                : orderProvider.errorMessage ?? 'Failed to delete order'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildOrdersTab(GroupProvider groupProvider, bool isAdmin, group) {
    final authProvider = Provider.of<AuthProvider>(context);
    final databaseService = DatabaseService();

    if (groupProvider.members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Order>>(
      stream: databaseService.getOrdersForGroup(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Get ALL orders for this group
        final allGroupOrders = snapshot.data ?? [];

    // Group members by their orders
    final memberOrders = <String, List<Order>>{};
    for (var member in groupProvider.members) {
      final orders = allGroupOrders
          .where((order) => order.userId == member.userId)
          .toList();
      memberOrders[member.userId] = orders;
    }

    // Calculate total amount from all orders
    final totalAmount = allGroupOrders.fold<double>(
      0.0,
      (sum, order) => sum + (order.price * order.quantity),
    );
    final hasOrders = memberOrders.values.any((orders) => orders.isNotEmpty);

    return Column(
      children: [
        // Show "Finished" indicator if group is not active
        if (!(group?.isActive ?? true))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.orange.shade900, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Orders Finished - This group is closed',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: hasOrders
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupProvider.members.length,
                  itemBuilder: (context, index) {
                    final member = groupProvider.members[index];
                    final orders = memberOrders[member.userId] ?? [];
                    return _buildMemberOrdersCard(member, orders, authProvider);
                  },
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No Orders Yet',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Members haven\'t placed any orders yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        // Only show confirm button if admin, has orders, AND group is active
        if (isAdmin && hasOrders && (group?.isActive ?? false))
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      CurrencyDisplay(
                        amount: totalAmount,
                        textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        iconColor: Theme.of(context).colorScheme.primary,
                        iconSize: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Split Calculator Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SplitCalculatorScreen(
                              groupId: widget.groupId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calculate),
                      label: const Text('Split Calculator'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Confirm Orders Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderConfirmationScreen(
                              groupId: widget.groupId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Review & Confirm Orders'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
      },
    );
  }

  Widget _buildMemberOrdersCard(
      GroupMember member, List<Order> orders, AuthProvider authProvider) {
    final isCurrentUser = authProvider.user?.id == member.userId;
    final memberTotal = orders.fold<double>(
      0.0,
      (sum, order) => sum + (order.price * order.quantity),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: member.userPhotoUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(member.userPhotoUrl!),
              )
            : CircleAvatar(
                child: Text(member.userName[0].toUpperCase()),
              ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ),
          ],
        ),
        subtitle: orders.isEmpty
            ? const Text('No orders yet')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${orders.length} ${orders.length == 1 ? 'order' : 'orders'} • '),
                  CurrencyDisplay(
                    amount: memberTotal,
                    iconSize: 14,
                  ),
                ],
              ),
        children: orders.isEmpty
            ? []
            : orders.map((order) {
                return ListTile(
                  dense: true,
                  leading: order.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            order.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.fastfood, size: 24),
                          ),
                        )
                      : const Icon(Icons.fastfood, size: 24),
                  title: Text(order.itemName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.quantity > 1) Text('Qty: ${order.quantity}'),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(order.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: CurrencyDisplay(
                    amount: order.price * order.quantity,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    iconSize: 14,
                  ),
                );
              }).toList(),
      ),
    );
  }

  Future<void> _confirmOrders(
      OrderProvider orderProvider, GroupProvider groupProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Orders'),
        content: const Text(
          'Are you sure you want to confirm all orders?\n\n'
          'This will create payment records for all members and deactivate the group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final databaseService = DatabaseService();

        // Fetch all orders for this group
        final allOrders = await databaseService.getOrdersForGroup(widget.groupId).first;

        // Create payment records for all members with orders
        for (var member in groupProvider.members) {
          final memberOrders = allOrders
              .where((order) => order.userId == member.userId)
              .toList();

          if (memberOrders.isNotEmpty) {
            final memberTotal = memberOrders.fold<double>(
              0.0,
              (sum, order) => sum + (order.price * order.quantity),
            );

            await orderProvider.createOrUpdatePayment(
              userId: member.userId,
              userName: member.userName,
              amount: memberTotal,
              paid: false,
              groupId: widget.groupId,
            );
          }
        }

        // Deactivate the group so no more orders can be added
        await groupProvider.toggleGroupActiveStatus(widget.groupId, false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orders confirmed! Payments created and group deactivated.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to confirm orders: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildPaymentsTab(
      GroupProvider groupProvider, bool isAdmin, Group? group) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Get all group members
    final allMembers = groupProvider.members;

    // Filter payments by groupId
    final payments = orderProvider.payments
        .where((p) => p.groupId == widget.groupId)
        .toList();

    // Create a map of userId -> payment for quick lookup
    final paymentMap = {for (var p in payments) p.userId: p};

    // Create member-payment pairs for ALL members
    final memberPayments = allMembers.map((member) {
      final payment = paymentMap[member.userId];
      return {
        'member': member,
        'payment': payment, // Can be null if member hasn't ordered
      };
    }).toList();

    // Calculate totals
    int totalParticipants = allMembers.length;
    int paidCount = payments.where((p) => p.paid).length;
    int unpaidCount = totalParticipants - paidCount;
    double totalPaid =
        payments.where((p) => p.paid).fold(0.0, (sum, p) => sum + p.amount);
    double totalUnpaid =
        payments.where((p) => !p.paid).fold(0.0, (sum, p) => sum + p.amount);
    double totalAmount = payments.fold(0.0, (sum, p) => sum + p.amount);

    return Column(
      children: [
        // Payment Summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
          child: Column(
            children: [
              Text(
                'Payment Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryCard(
                    context,
                    'Paid',
                    paidCount.toString(),
                    Colors.green,
                    totalPaid,
                  ),
                  _buildSummaryCard(
                    context,
                    'Unpaid',
                    unpaidCount.toString(),
                    Colors.orange,
                    totalUnpaid,
                  ),
                  _buildSummaryCard(
                    context,
                    'Total',
                    totalParticipants.toString(),
                    Theme.of(context).colorScheme.primary,
                    totalAmount,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Payment List - Show ALL members
        Expanded(
          child: memberPayments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No members yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: memberPayments.length,
                  itemBuilder: (context, index) {
                    final memberPaymentPair = memberPayments[index];
                    final member = memberPaymentPair['member'] as GroupMember;
                    final payment = memberPaymentPair['payment'] as Payment?;

                    return _buildPaymentCardForMember(
                      context,
                      member,
                      payment,
                      orderProvider,
                      authProvider,
                      isAdmin,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String count,
    Color color,
    double amount,
  ) {
    return Card(
      elevation: 2,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            CurrencyDisplay(
              amount: amount,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              iconSize: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    Payment payment,
    OrderProvider orderProvider,
    AuthProvider authProvider,
    bool isAdmin,
  ) {
    final isCurrentUser = authProvider.user?.id == payment.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              payment.paid ? Colors.green : Theme.of(context).colorScheme.primary,
          child: Icon(
            payment.paid ? Icons.check : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                payment.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            CurrencyDisplay(
              amount: payment.amount,
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: 16,
            ),
            if (payment.paid && payment.paidAt != null)
              Text(
                'Paid on ${DateFormat('MMM d, h:mm a').format(payment.paidAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: payment.paid
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PAID',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : (isAdmin
                ? TextButton(
                    onPressed: () {
                      _showMarkAsPaidDialog(context, payment, orderProvider);
                    },
                    child: const Text('Mark Paid'),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'UNPAID',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )),
      ),
    );
  }

  Widget _buildPaymentCardForMember(
    BuildContext context,
    GroupMember member,
    Payment? payment,
    OrderProvider orderProvider,
    AuthProvider authProvider,
    bool isAdmin,
  ) {
    final isCurrentUser = authProvider.user?.id == member.userId;
    final hasPayment = payment != null;
    final databaseService = DatabaseService();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: StreamBuilder<List<Order>>(
        stream: databaseService.getOrdersForGroup(widget.groupId),
        builder: (context, snapshot) {
          final allOrders = snapshot.data ?? [];
          final memberOrders = allOrders
              .where((order) => order.userId == member.userId)
              .toList();

          // Calculate total from orders
          final orderTotal = memberOrders.fold<double>(
            0.0,
            (sum, order) => sum + (order.price * order.quantity),
          );

          // Use payment amount if exists, otherwise use calculated order total
          final displayAmount = hasPayment ? payment.amount : orderTotal;
          final hasOrders = memberOrders.isNotEmpty;

          return ExpansionTile(
            leading: member.userPhotoUrl != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(member.userPhotoUrl!),
                    backgroundColor: hasPayment
                        ? (payment.paid ? Colors.green : Theme.of(context).colorScheme.primary)
                        : (hasOrders ? Colors.orange : Colors.grey),
                  )
                : CircleAvatar(
                    backgroundColor: hasPayment
                        ? (payment.paid ? Colors.green : Theme.of(context).colorScheme.primary)
                        : (hasOrders ? Colors.orange : Colors.grey),
                    child: Icon(
                      hasPayment
                          ? (payment.paid ? Icons.check : Icons.person)
                          : (hasOrders ? Icons.pending : Icons.person_outline),
                      color: Colors.white,
                    ),
                  ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    member.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isCurrentUser)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'You',
                      style: TextStyle(fontSize: 10, color: Colors.blue),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                CurrencyDisplay(
                  amount: displayAmount,
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  iconColor: Theme.of(context).colorScheme.primary,
                  iconSize: 16,
                ),
                if (!hasOrders)
                  Text(
                    'No orders placed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (hasPayment && payment.paid && payment.paidAt != null)
                  Text(
                    'Paid on ${DateFormat('MMM d, h:mm a').format(payment.paidAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            trailing: hasPayment
                ? (payment.paid
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'PAID',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : (isAdmin
                        ? TextButton(
                            onPressed: () {
                              _showMarkAsPaidDialog(context, payment, orderProvider);
                            },
                            child: const Text('Mark Paid'),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'UNPAID',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )))
                : (hasOrders
                    ? (isAdmin
                        ? TextButton(
                            onPressed: () {
                              _showMarkAsPaidDialogForPending(
                                context,
                                member,
                                orderTotal,
                                orderProvider,
                              );
                            },
                            child: const Text('Mark Paid'),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'PENDING',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ))
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'NO ORDER',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )),
            children: memberOrders.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No orders placed'),
                    ),
                  ]
                : memberOrders.map((order) {
                    return ListTile(
                      dense: true,
                      leading: order.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                order.imageUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.fastfood, size: 24),
                              ),
                            )
                          : const Icon(Icons.fastfood, size: 24),
                      title: Text(order.itemName),
                      subtitle: order.quantity > 1
                          ? Text('Qty: ${order.quantity}')
                          : null,
                      trailing: CurrencyDisplay(
                        amount: order.price * order.quantity,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        iconSize: 14,
                      ),
                    );
                  }).toList(),
          );
        },
      ),
    );
  }

  void _showMarkAsPaidDialog(
    BuildContext context,
    Payment payment,
    OrderProvider orderProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Mark ${payment.userName}\'s payment of '),
            CurrencyDisplay(
              amount: payment.amount,
              iconSize: 14,
            ),
            const Text(' as paid?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await orderProvider.markPaymentAsPaid(payment.userId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment marked as paid'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
  }

  void _showMarkAsPaidDialogForPending(
    BuildContext context,
    GroupMember member,
    double amount,
    OrderProvider orderProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Mark ${member.userName}\'s payment of '),
            CurrencyDisplay(
              amount: amount,
              iconSize: 14,
            ),
            const Text(' as paid?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // First create/update the payment record, then mark as paid
              final databaseService = DatabaseService();
              try {
                // Get current session
                if (orderProvider.currentSession != null) {
                  // Create or update payment record with paid status
                  await databaseService.createOrUpdatePayment(
                    sessionId: orderProvider.currentSession!.id,
                    groupId: widget.groupId,
                    userId: member.userId,
                    userName: member.userName,
                    amount: amount,
                    paid: true,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment marked as paid'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(GroupMember member, bool isAdmin) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUser = authProvider.user?.id == member.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: member.userPhotoUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(member.userPhotoUrl!),
              )
            : CircleAvatar(
                child: Text(member.userName[0].toUpperCase()),
              ),
        title: Row(
          children: [
            Text(member.userName),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ),
            ],
            if (member.isAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(fontSize: 10, color: Colors.orange),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(member.userEmail),
        trailing: isAdmin && !member.isAdmin
            ? IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => _confirmRemoveMember(member),
              )
            : null,
      ),
    );
  }

  Future<void> _confirmRemoveMember(GroupMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.userName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final success = await groupProvider.removeMember(
        groupId: widget.groupId,
        userId: member.userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Member removed'
                : groupProvider.errorMessage ?? 'Failed to remove member'),
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
    }
  }
}

