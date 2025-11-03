import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/group_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/group_restaurant.dart';
import '../../models/restaurant.dart';
import '../../models/menu_category.dart';
import '../../models/menu_item.dart';

class GroupMenuScreen extends StatefulWidget {
  final String groupId;

  const GroupMenuScreen({super.key, required this.groupId});

  @override
  State<GroupMenuScreen> createState() => _GroupMenuScreenState();
}

class _GroupMenuScreenState extends State<GroupMenuScreen> {
  GroupRestaurant? _selectedGroupRestaurant;
  bool _isLoadingMenu = false;

  @override
  void initState() {
    super.initState();
    // Defer the call to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupDetails();
    });
  }

  void _loadGroupDetails() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    groupProvider.selectGroup(widget.groupId);
  }

  Future<void> _selectRestaurant(GroupRestaurant groupRestaurant) async {
    setState(() {
      _selectedGroupRestaurant = groupRestaurant;
      _isLoadingMenu = true;
    });

    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);

    // If restaurant has an API URL, load the menu from API
    if (groupRestaurant.restaurantApiUrl != null) {
      final restaurant = Restaurant(
        id: groupRestaurant.restaurantId,
        name: groupRestaurant.restaurantName,
        apiUrl: groupRestaurant.restaurantApiUrl!,
        imageUrl: groupRestaurant.restaurantImageUrl,
        description: groupRestaurant.restaurantDescription,
      );

      await restaurantProvider.selectRestaurant(restaurant);
    }

    setState(() {
      _isLoadingMenu = false;
    });
  }

  void _backToRestaurantList() {
    setState(() {
      _selectedGroupRestaurant = null;
    });
    // Clear restaurant provider
    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);
    restaurantProvider.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedGroupRestaurant?.restaurantName ?? 'Group Menu'),
        leading: _selectedGroupRestaurant != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToRestaurantList,
              )
            : null,
        actions: [
          // Settings Menu (Three Dots)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Settings',
            onSelected: (value) async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              switch (value) {
                case 'logout':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await authProvider.signOut();
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: Colors.red,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: groupProvider.restaurants.isEmpty
          ? _buildEmptyState()
          : _selectedGroupRestaurant == null
              ? _buildRestaurantSelection(groupProvider.restaurants)
              : _buildMenuView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Restaurants Available',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask the admin to add restaurants to the group',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantSelection(List<GroupRestaurant> restaurants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Select a Restaurant',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: restaurant.restaurantImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            restaurant.restaurantImageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.restaurant, size: 40),
                          ),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.restaurant),
                        ),
                  title: Text(
                    restaurant.restaurantName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: restaurant.restaurantDescription != null
                      ? Text(
                          restaurant.restaurantDescription!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _selectRestaurant(restaurant),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuView() {
    final restaurantProvider = Provider.of<RestaurantProvider>(context);

    if (_isLoadingMenu || restaurantProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // If restaurant has a menu from API
    if (restaurantProvider.categories.isNotEmpty) {
      return _MenuWithTabs(
        groupRestaurant: _selectedGroupRestaurant!,
        groupId: widget.groupId,
      );
    }

    // Otherwise show custom item view
    return _buildCustomItemView();
  }

  Widget _buildCustomItemView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_shopping_cart,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Add Your Items',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'This restaurant doesn\'t have a menu API.\nTap the button below to add custom items.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddCustomItemDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Item'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomItemDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddCustomItemDialog(),
    );

    if (result != null && mounted) {
      _createOrder(
        itemName: result['name'],
        price: result['price'],
        imageUrl: null,
      );
    }
  }

  Future<void> _createOrder({
    required String itemName,
    required double price,
    String? imageUrl,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to order')),
      );
      return;
    }

    // Initialize or get today's session
    await orderProvider.initTodaySession(
      authProvider.user!.id,
      authProvider.user!.name,
    );

    if (orderProvider.currentSession == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create order session'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Create the order
    final success = await orderProvider.createOrder(
      userId: authProvider.user!.id,
      userName: authProvider.user!.name,
      itemName: itemName,
      price: price,
      imageUrl: imageUrl,
      groupId: widget.groupId, // CRITICAL: Link order to group
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                orderProvider.errorMessage ?? 'Failed to create order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Menu with category tabs
class _MenuWithTabs extends StatefulWidget {
  final GroupRestaurant groupRestaurant;
  final String groupId;

  const _MenuWithTabs({
    required this.groupRestaurant,
    required this.groupId,
  });

  @override
  State<_MenuWithTabs> createState() => _MenuWithTabsState();
}

class _MenuWithTabsState extends State<_MenuWithTabs>
    with SingleTickerProviderStateMixin {
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
    return Consumer<RestaurantProvider>(
      builder: (context, restaurantProvider, child) {
        final categories = restaurantProvider.categories;
        const locale = 'ar'; // Always use Arabic for menu items

        if (categories.isEmpty) {
          return const Center(
            child: Text('No menu items available'),
          );
        }

        _updateTabController(categories.length);

        return Column(
          children: [
            // Tab bar
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
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
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: categories.map((category) {
                  return _CategoryTabContent(
                    category: category,
                    groupId: widget.groupId,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryTabContent extends StatelessWidget {
  final MenuCategory category;
  final String groupId;

  const _CategoryTabContent({
    required this.category,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    const locale = 'ar'; // Always use Arabic for menu items

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Category header with image and description
        if (category.imageUri != null ||
            category.getLocalizedDescription(locale).isNotEmpty)
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
                if (category.imageUri != null &&
                    category.getLocalizedDescription(locale).isNotEmpty)
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
        )),
      ],
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  final MenuItem item;
  final String groupId;

  const _MenuItemCard({
    required this.item,
    required this.groupId,
  });

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> {
  @override
  Widget build(BuildContext context) {
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
                          '﷼${widget.item.price.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
      ),
    );
  }
}

class _ItemDetailsBottomSheet extends StatefulWidget {
  final MenuItem item;
  final String groupId;

  const _ItemDetailsBottomSheet({
    required this.item,
    required this.groupId,
  });

  @override
  State<_ItemDetailsBottomSheet> createState() =>
      _ItemDetailsBottomSheetState();
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    const locale = 'ar';

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
      groupId: widget.groupId, // CRITICAL: Link order to group
    );

    setState(() {
      _isAdding = false;
    });

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${widget.item.getLocalizedName(locale)} added to order!'),
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
    const locale = 'ar';
    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);

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
                    '﷼${widget.item.price.toStringAsFixed(2)}',
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _quantity.toString(),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          '﷼${(widget.item.price * _quantity).toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
                                avatar: allergen
                                        .getLocalizedIcon(locale)
                                        .isNotEmpty
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
            // Add to Order button
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
          ],
        ),
      ),
    );
  }
}

class _AddCustomItemDialog extends StatefulWidget {
  const _AddCustomItemDialog();

  @override
  State<_AddCustomItemDialog> createState() => _AddCustomItemDialogState();
}

class _AddCustomItemDialogState extends State<_AddCustomItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g., Cappuccino',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                hintText: 'e.g., 4.50',
                border: OutlineInputBorder(),
                prefixText: '﷼',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value.trim()) <= 0) {
                  return 'Price must be greater than 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add to Order'),
        ),
      ],
    );
  }
}
