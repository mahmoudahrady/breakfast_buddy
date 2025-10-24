import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/menu_category.dart';
import '../../models/menu_item.dart';
import '../../models/modifier.dart';
import '../../models/order.dart' as OrderModel;
import '../../utils/currency_utils.dart';
import '../../utils/app_logger.dart';
import '../../services/database_service.dart';
import '../../widgets/order_deadline_banner.dart';

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
  List<OrderModel.Order>? _recentOrders;
  bool _loadingRecentOrders = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecentOrders();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentOrders() async {
    if (widget.groupId == null) {
      setState(() {
        _loadingRecentOrders = false;
        _recentOrders = [];
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      setState(() {
        _loadingRecentOrders = false;
        _recentOrders = [];
      });
      return;
    }

    final databaseService = DatabaseService();
    final orders = await databaseService.getUserRecentOrdersForGroup(
      authProvider.user!.id,
      widget.groupId!,
      limit: 10,
    );

    if (mounted) {
      setState(() {
        _recentOrders = orders;
        _loadingRecentOrders = false;
      });
    }
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
        final selectedGroupActive = groupProvider.selectedGroup?.isActive;
        final parameterActive = widget.isGroupActive;
        final isGroupActive = selectedGroupActive ?? parameterActive;

        AppLogger.info('MenuScreen build | GroupID: ${widget.groupId} | selectedGroup.isActive: $selectedGroupActive | parameter.isGroupActive: $parameterActive | final isGroupActive: $isGroupActive');
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
          body: Column(
            children: [
              // Quick Reorder Section
              if (_recentOrders != null && _recentOrders!.isNotEmpty)
                _buildQuickReorderSection(context, isGroupActive),
              // Deadline Banner
              if (groupProvider.selectedGroup?.orderDeadline != null &&
                  groupProvider.selectedGroup!.isActive &&
                  !groupProvider.selectedGroup!.isDeadlinePassed)
                OrderDeadlineBanner(
                  deadline: groupProvider.selectedGroup!.orderDeadline!,
                ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search menu items...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              // Menu Categories
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: categories.map((category) {
                    return RefreshIndicator(
                      onRefresh: () => restaurantProvider.refreshMenu(),
                      child: _CategoryTabContent(
                        category: category,
                        groupId: widget.groupId,
                        isGroupActive: isGroupActive,
                        searchQuery: _searchQuery,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickReorderSection(BuildContext context, bool isGroupActive) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Reorder',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_recentOrders!.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _recentOrders!.length,
              itemBuilder: (context, index) {
                final order = _recentOrders![index];
                return _buildQuickReorderCard(context, order, isGroupActive);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReorderCard(
    BuildContext context,
    OrderModel.Order order,
    bool isGroupActive,
  ) {
    return Card(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: isGroupActive ? () => _quickReorder(order) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (order.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: order.imageUrl!,
                    height: 50,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.fastfood, size: 24),
                    ),
                  ),
                )
              else
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.fastfood, size: 24),
                  ),
                ),
              const SizedBox(height: 6),
              // Name
              Text(
                order.itemName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Price and Reorder button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      CurrencyUtils.formatCurrency(order.price),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isGroupActive)
                    Icon(
                      Icons.add_circle,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickReorder(OrderModel.Order order) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final user = authProvider.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to reorder')),
      );
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text('Adding ${order.itemName}...'),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    final success = await orderProvider.createOrder(
      userId: user.id,
      userName: user.name,
      itemName: order.itemName,
      price: order.price,
      quantity: order.quantity,
      imageUrl: order.imageUrl,
      groupId: widget.groupId,
      notes: order.notes,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${order.itemName} added to order!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Failed to add item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _CategoryTabContent extends StatelessWidget {
  final MenuCategory category;
  final String? groupId;
  final bool isGroupActive;
  final String searchQuery;

  const _CategoryTabContent({
    required this.category,
    this.groupId,
    required this.isGroupActive,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    const locale = 'ar'; // Always use Arabic for menu items

    // Filter items based on search query
    final filteredItems = searchQuery.isEmpty
        ? category.items
        : category.items.where((item) {
            final name = item.getLocalizedName(locale).toLowerCase();
            final description = item.getLocalizedDescription(locale).toLowerCase();
            return name.contains(searchQuery) || description.contains(searchQuery);
          }).toList();

    // If search is active and no results, show message
    if (searchQuery.isNotEmpty && filteredItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No items found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Category header with image and description (hide when searching)
        if (searchQuery.isEmpty &&
            (category.imageUri != null || category.getLocalizedDescription(locale).isNotEmpty))
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
        // Search results count (when searching)
        if (searchQuery.isNotEmpty && filteredItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${filteredItems.length} ${filteredItems.length == 1 ? 'result' : 'results'} found',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        // Category items
        ...filteredItems.map((item) => _MenuItemCard(
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
  String? _favoriteId;
  bool _isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  Future<void> _checkIfFavorited() async {
    if (widget.groupId == null) {
      setState(() => _isLoadingFavorite = false);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      setState(() => _isLoadingFavorite = false);
      return;
    }

    final databaseService = DatabaseService();
    const locale = 'ar';
    final favoriteId = await databaseService.getFavoriteId(
      userId: authProvider.user!.id,
      groupId: widget.groupId!,
      itemName: widget.item.getLocalizedName(locale),
    );

    if (mounted) {
      setState(() {
        _favoriteId = favoriteId;
        _isLoadingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.groupId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final databaseService = DatabaseService();
    const locale = 'ar';

    try {
      if (_favoriteId != null) {
        // Remove from favorites
        await databaseService.removeFavorite(_favoriteId!);
        if (mounted) {
          setState(() => _favoriteId = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Add to favorites
        final favoriteId = await databaseService.addFavorite(
          userId: authProvider.user!.id,
          groupId: widget.groupId!,
          itemName: widget.item.getLocalizedName(locale),
          itemDescription: widget.item.getLocalizedDescription(locale),
          price: widget.item.price,
          imageUrl: widget.item.imageUri,
        );
        if (mounted) {
          setState(() => _favoriteId = favoriteId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

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
              // Favorite button
              if (widget.groupId != null)
                _isLoadingFavorite
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          _favoriteId != null ? Icons.favorite : Icons.favorite_border,
                          color: _favoriteId != null ? Colors.red : Colors.grey,
                        ),
                        onPressed: _toggleFavorite,
                        tooltip: _favoriteId != null ? 'Remove from favorites' : 'Add to favorites',
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
  final TextEditingController _notesController = TextEditingController();
  final Map<int, List<int>> _selectedModifiers = {}; // modifierGroupId -> [modifierIds]

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleModifier(ModifierGroup group, int modifierId) {
    setState(() {
      if (!_selectedModifiers.containsKey(group.id)) {
        _selectedModifiers[group.id] = [];
      }

      final selectedList = _selectedModifiers[group.id]!;

      if (group.type == 'SINGLE') {
        // For single selection, clear and set new
        selectedList.clear();
        selectedList.add(modifierId);
      } else {
        // For multiple selection
        if (selectedList.contains(modifierId)) {
          selectedList.remove(modifierId);
        } else {
          // Check maximum constraint
          if (selectedList.length < group.maximum) {
            selectedList.add(modifierId);
          }
        }
      }
    });
  }

  bool _isModifierSelected(int groupId, int modifierId) {
    return _selectedModifiers[groupId]?.contains(modifierId) ?? false;
  }

  double _calculateModifiersPrice() {
    double total = 0.0;
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);

    _selectedModifiers.forEach((groupId, modifierIds) {
      for (var modifierId in modifierIds) {
        final modifier = restaurantProvider.modifiers[modifierId];
        if (modifier != null) {
          total += modifier.price;
        }
      }
    });

    return total;
  }

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
    AppLogger.info('_addToOrder called | widget.isGroupActive: ${widget.isGroupActive} | groupId: ${widget.groupId}');

    if (!widget.isGroupActive) {
      AppLogger.warning('Order blocked: Group is not active (isGroupActive: false)');
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

    AppLogger.info('Order check passed, proceeding to add order...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    const locale = 'ar'; // Always use Arabic for menu items

    final user = authProvider.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add items to order')),
      );
      return;
    }

    // Build item name with modifiers
    String itemNameWithModifiers = widget.item.getLocalizedName(locale);
    final List<String> modifierNames = [];

    _selectedModifiers.forEach((groupId, modifierIds) {
      for (var modifierId in modifierIds) {
        final modifier = restaurantProvider.modifiers[modifierId];
        if (modifier != null) {
          modifierNames.add(modifier.getLocalizedName(locale));
        }
      }
    });

    if (modifierNames.isNotEmpty) {
      itemNameWithModifiers += ' (${modifierNames.join(', ')})';
    }

    // Calculate total price including modifiers
    final totalPrice = widget.item.price + _calculateModifiersPrice();

    setState(() {
      _isAdding = true;
    });

    final success = await orderProvider.createOrder(
      userId: user.id,
      userName: user.name,
      itemName: itemNameWithModifiers,
      price: totalPrice,
      quantity: _quantity,
      imageUrl: widget.item.imageUri,
      groupId: widget.groupId,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
                  // Modifiers Section
                  if (widget.item.modifierGroups.isNotEmpty) ...[
                    ...restaurantProvider.getModifierGroupsForItem(widget.item.modifierGroups).map((group) {
                      final modifiers = restaurantProvider.getModifiersForGroup(group);
                      if (modifiers.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                group.getLocalizedName(locale),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (group.minimum > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Required',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            group.type == 'SINGLE'
                                ? 'Choose one'
                                : 'Choose up to ${group.maximum}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 12),
                          ...modifiers.map((modifier) {
                            final isSelected = _isModifierSelected(group.id, modifier.id);
                            return InkWell(
                              onTap: () => _toggleModifier(group, modifier.id),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    if (group.type == 'SINGLE')
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey[400],
                                      )
                                    else
                                      Icon(
                                        isSelected
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey[400],
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        modifier.getLocalizedName(locale),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                      ),
                                    ),
                                    if (modifier.price > 0)
                                      Text(
                                        '+ ${CurrencyUtils.formatCurrency(modifier.price)}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                  ],
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
                          CurrencyUtils.formatCurrency((widget.item.price + _calculateModifiersPrice()) * _quantity),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Special instructions
                  Text(
                    'Special Instructions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'E.g., No onions, Extra spicy...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      prefixIcon: const Icon(Icons.note_alt_outlined),
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
