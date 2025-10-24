import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/currency_display.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String groupId;

  const OrderHistoryScreen({super.key, required this.groupId});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  String _filterOption = 'all'; // 'all', 'week', 'month', 'custom'
  String _searchQuery = '';
  String _sortOption = 'date_desc'; // 'date_desc', 'date_asc', 'price_desc', 'price_asc'
  double _minPrice = 0;
  double _maxPrice = 500;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Default to this month
    _setMonthFilter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setWeekFilter() {
    setState(() {
      _filterOption = 'week';
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      _selectedDateRange = DateTimeRange(
        start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
      );
    });
  }

  void _setMonthFilter() {
    setState(() {
      _filterOption = 'month';
      final now = DateTime.now();
      _selectedDateRange = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      );
    });
  }

  void _setAllTimeFilter() {
    setState(() {
      _filterOption = 'all';
      _selectedDateRange = null;
    });
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _filterOption = 'custom';
        _selectedDateRange = DateTimeRange(
          start: DateTime(picked.start.year, picked.start.month, picked.start.day),
          end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
        );
      });
    }
  }

  String _getDateRangeText() {
    if (_selectedDateRange == null) return 'All Time';
    final formatter = DateFormat('MMM d, yyyy');
    return '${formatter.format(_selectedDateRange!.start)} - ${formatter.format(_selectedDateRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Toggle Filters',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Date Filter',
            onSelected: (value) {
              switch (value) {
                case 'week':
                  _setWeekFilter();
                  break;
                case 'month':
                  _setMonthFilter();
                  break;
                case 'all':
                  _setAllTimeFilter();
                  break;
                case 'custom':
                  _selectCustomDateRange();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _filterOption == 'week' ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('This Week'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: _filterOption == 'month' ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('This Month'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      color: _filterOption == 'all' ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('All Time'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'custom',
                child: Row(
                  children: [
                    Icon(Icons.date_range),
                    SizedBox(width: 8),
                    Text('Custom Range'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search orders by item name...',
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
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filters Panel
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price Range',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _minPrice = 0;
                            _maxPrice = 500;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  Text(
                    '${_minPrice.toInt()} - ${_maxPrice.toInt()} SAR',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: 0,
                    max: 500,
                    divisions: 50,
                    labels: RangeLabels(
                      _minPrice.toInt().toString(),
                      _maxPrice.toInt().toString(),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _minPrice = values.start;
                        _maxPrice = values.end;
                      });
                    },
                  ),
                ],
              ),
            ),
          if (_showFilters) const SizedBox(height: 16),

          // Date range display
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.date_range, size: 20),
                const SizedBox(width: 8),
                Text(
                  _getDateRangeText(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: _databaseService.getOrdersForGroup(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var orders = snapshot.data ?? [];

                // Filter by user
                if (authProvider.user != null) {
                  orders = orders
                      .where((order) => order.userId == authProvider.user!.id)
                      .toList();
                }

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  orders = orders.where((order) {
                    return order.itemName.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                // Filter by date range
                if (_selectedDateRange != null) {
                  orders = orders.where((order) {
                    return order.createdAt.isAfter(_selectedDateRange!.start) &&
                        order.createdAt.isBefore(_selectedDateRange!.end);
                  }).toList();
                }

                // Filter by price range
                orders = orders.where((order) {
                  final totalPrice = order.price * order.quantity;
                  return totalPrice >= _minPrice && totalPrice <= _maxPrice;
                }).toList();

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting the date filter',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate total
                final total = orders.fold<double>(
                  0.0,
                  (sum, order) => sum + (order.price * order.quantity),
                );

                // Group orders by date
                final groupedOrders = <String, List<Order>>{};
                for (var order in orders) {
                  final dateKey =
                      DateFormat('EEEE, MMMM d, yyyy').format(order.createdAt);
                  groupedOrders.putIfAbsent(dateKey, () => []);
                  groupedOrders[dateKey]!.add(order);
                }

                return Column(
                  children: [
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Orders',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                orders.length.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total Spent',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              CurrencyDisplay(
                                amount: total,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
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

                    // Orders grouped by date
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedOrders.length,
                        itemBuilder: (context, index) {
                          final dateKey = groupedOrders.keys.elementAt(index);
                          final dateOrders = groupedOrders[dateKey]!;
                          final dayTotal = dateOrders.fold<double>(
                            0.0,
                            (sum, order) => sum + (order.price * order.quantity),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date header
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateKey,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    CurrencyDisplay(
                                      amount: dayTotal,
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      iconSize: 14,
                                    ),
                                  ],
                                ),
                              ),

                              // Orders for this date
                              ...dateOrders.map((order) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: order.imageUrl != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                order.imageUrl!,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.fastfood,
                                                        size: 40),
                                              ),
                                            )
                                          : const CircleAvatar(
                                              child: Icon(Icons.fastfood),
                                            ),
                                      title: Text(order.itemName),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text('Quantity: ${order.quantity}'),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('h:mm a')
                                                .format(order.createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: CurrencyDisplay(
                                        amount: order.price * order.quantity,
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        iconSize: 16,
                                      ),
                                    ),
                                  )),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
