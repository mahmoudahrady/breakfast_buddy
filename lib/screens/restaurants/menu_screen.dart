import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/menu_category.dart';
import '../../models/menu_item.dart';
import '../../utils/currency_utils.dart';

// Menu screen with tabs for categories
class MenuScreen extends StatefulWidget {
  final String? groupId;
  final bool isGroupActive;

  const MenuScreen({super.key, this.groupId, this.isGroupActive = true});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _currentTabLength = 0;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _updateTabController(int length) {
    if (length != _currentTabLength) {
      _tabController?.dispose();
      _tabController = TabController(length: length, vsync: this);
      _currentTabLength = length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RestaurantProvider, GroupProvider>(
      builder: (context, restaurantProvider, groupProvider, child) {
        // Get real-time group active status
        final isGroupActive = groupProvider.selectedGroup?.isActive ?? widget.isGroupActive;
        if (restaurantProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(restaurantProvider.selectedRestaurant?.name ?? 'Menu'),
              elevation: 0,
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (restaurantProvider.error != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(restaurantProvider.selectedRestaurant?.name ?? 'Menu'),
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading menu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurantProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => restaurantProvider.refreshMenu(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final categories = restaurantProvider.categories;
        const locale = 'ar'; // Always use Arabic for menu items

        if (categories.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(restaurantProvider.selectedRestaurant?.name ?? 'Menu'),
              elevation: 0,
            ),
            body: const Center(
              child: Text('No menu items available'),
            ),
          );
        }

        _updateTabController(categories.length);

        return Scaffold(
          appBar: AppBar(
            title: Text(restaurantProvider.selectedRestaurant?.name ?? 'Menu'),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: categories.map((category) {
                return Tab(
                  text: category.getLocalizedName(locale),
                );
              }).toList(),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: categories.map((category) {
              return RefreshIndicator(
                onRefresh: () => restaurantProvider.refreshMenu(),
                child: _CategoryTabContent(
                  category: category,
                  groupId: widget.groupId,
                  isGroupActive: isGroupActive,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _CategoryTabContent extends StatelessWidget {
  final MenuCategory category;
  final String? groupId;
  final bool isGroupActive;

  const _CategoryTabContent({
    required this.category,
    this.groupId,
    required this.isGroupActive,
  });

  @override
  Widget build(BuildContext context) {
    const locale = 'ar'; // Always use Arabic for menu items

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Category header with image and description
        if (category.imageUri != null || category.getLocalizedDescription(locale).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.imageUri != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: category.imageUri!,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: double.infinity,
                        height: 150,
                        color: Colors.grey[300],
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: double.infinity,
                        height: 150,
                        color: Colors.grey[300],
                        child: const Icon(Icons.category, size: 48),
                      ),
                    ),
                  ),
                if (category.imageUri != null && category.getLocalizedDescription(locale).isNotEmpty)
                  const SizedBox(height: 12),
                if (category.getLocalizedDescription(locale).isNotEmpty)
                  Text(
                    category.getLocalizedDescription(locale),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
              ],
            ),
          ),
        // Category items
        ...category.items.map((item) => _MenuItemCard(
              item: item,
              groupId: groupId,
              isGroupActive: isGroupActive,
            )),
      ],
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  final MenuItem item;
  final String? groupId;
  final bool isGroupActive;

  const _MenuItemCard({
    required this.item,
    this.groupId,
    required this.isGroupActive,
  });

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> {
  @override
  Widget build(BuildContext context) {
    // Always use Arabic for menu items
    const locale = 'ar';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showItemDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item image
              if (widget.item.imageUri != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.item.imageUri!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.fastfood),
                    ),
                  ),
                ),
              if (widget.item.imageUri != null) const SizedBox(width: 12),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.getLocalizedName(locale),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.getLocalizedDescription(locale),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          CurrencyUtils.formatCurrency(widget.item.price),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ItemDetailsBottomSheet(
        item: widget.item,
        groupId: widget.groupId,
        isGroupActive: widget.isGroupActive,
      ),
    );
  }
}

class _ItemDetailsBottomSheet extends StatefulWidget {
  final MenuItem item;
  final String? groupId;
  final bool isGroupActive;

  const _ItemDetailsBottomSheet({
    required this.item,
    this.groupId,
    required this.isGroupActive,
  });

  @override
  State<_ItemDetailsBottomSheet> createState() => _ItemDetailsBottomSheetState();
}

class _ItemDetailsBottomSheetState extends State<_ItemDetailsBottomSheet> {
  int _quantity = 1;
  bool _isAdding = false;

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _addToOrder() async {
    // Check if group is active before allowing order
    if (!widget.isGroupActive) {
      Navigator.pop(context); // Close bottom sheet first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orders are closed. The admin has confirmed all orders.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    const locale = 'ar'; // Always use Arabic for menu items

    final user = authProvider.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add items to order')),
      );
      return;
    }

    setState(() {
      _isAdding = true;
    });

    final success = await orderProvider.createOrder(
      userId: user.id,
      userName: user.name,
      itemName: widget.item.getLocalizedName(locale),
      price: widget.item.price,
      quantity: _quantity,
      imageUrl: widget.item.imageUri,
      groupId: widget.groupId,
    );

    setState(() {
      _isAdding = false;
    });

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.item.getLocalizedName(locale)} added to order!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Failed to add item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const locale = 'ar'; // Always use Arabic for menu items
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Image
                  if (widget.item.imageUri != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: widget.item.imageUri!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    widget.item.getLocalizedName(locale),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    widget.item.getLocalizedDescription(locale),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  // Price
                  Text(
                    CurrencyUtils.formatCurrency(widget.item.price),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  // Quantity selector
                  Row(
                    children: [
                      Text(
                        'Quantity',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _decreaseQuantity,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _quantity.toString(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: _increaseQuantity,
                        icon: const Icon(Icons.add_circle_outline),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Total price
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          CurrencyUtils.formatCurrency(widget.item.price * _quantity),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Allergens section
                  if (widget.item.allergens.isNotEmpty) ...[
                    Text(
                      'Allergens',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: restaurantProvider
                          .getAllergensForItem(widget.item.allergens)
                          .map((allergen) => Chip(
                                label: Text(allergen.getLocalizedName(locale)),
                                avatar: allergen.getLocalizedIcon(locale).isNotEmpty
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          allergen.getLocalizedIcon(locale),
                                        ),
                                      )
                                    : null,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            // Add to Order button (only show if group is active)
            if (widget.isGroupActive)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAdding ? null : _addToOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isAdding
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Add to Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            // Show message when orders are closed
            if (!widget.isGroupActive)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Orders are closed. The admin has confirmed all orders.',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
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
