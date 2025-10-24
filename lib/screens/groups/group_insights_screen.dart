import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/group_provider.dart';
import '../../services/database_service.dart';
import '../../models/order.dart';
import '../../widgets/currency_display.dart';

class GroupInsightsScreen extends StatefulWidget {
  final String groupId;

  const GroupInsightsScreen({super.key, required this.groupId});

  @override
  State<GroupInsightsScreen> createState() => _GroupInsightsScreenState();
}

class _GroupInsightsScreenState extends State<GroupInsightsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _timeRange = '30'; // Days

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final group = groupProvider.selectedGroup;

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Insights')),
        body: const Center(child: Text('Group not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Insights'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          PopupMenuButton<String>(
            initialValue: _timeRange,
            onSelected: (value) => setState(() => _timeRange = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7', child: Text('Last 7 Days')),
              const PopupMenuItem(value: '30', child: Text('Last 30 Days')),
              const PopupMenuItem(value: '90', child: Text('Last 90 Days')),
              const PopupMenuItem(value: 'all', child: Text('All Time')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Order>>(
        stream: _databaseService.getOrdersForGroup(widget.groupId),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allOrders = orderSnapshot.data ?? [];
          final filteredOrders = _filterOrdersByTimeRange(allOrders);

          if (filteredOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insights, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No data available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start ordering to see insights!',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Calculate statistics
          final stats = _calculateStatistics(filteredOrders, groupProvider.members.length);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context, stats),
                const SizedBox(height: 24),

                // Key Metrics
                _buildKeyMetrics(context, stats),
                const SizedBox(height: 24),

                // Spending Trend Chart
                _buildSpendingTrendSection(context, filteredOrders),
                const SizedBox(height: 24),

                // Top Members
                _buildTopMembersSection(context, stats),
                const SizedBox(height: 24),

                // Popular Items
                _buildPopularItemsSection(context, stats),
                const SizedBox(height: 24),

                // Order Frequency
                _buildOrderFrequencySection(context, stats),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Order> _filterOrdersByTimeRange(List<Order> orders) {
    if (_timeRange == 'all') return orders;

    final days = int.parse(_timeRange);
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return orders.where((order) => order.createdAt.isAfter(cutoff)).toList();
  }

  Map<String, dynamic> _calculateStatistics(List<Order> orders, int memberCount) {
    final totalSpent = orders.fold<double>(0, (sum, o) => sum + (o.price * o.quantity));
    final totalOrders = orders.length;
    final avgOrderValue = totalOrders > 0 ? totalSpent / totalOrders : 0;

    // Member spending
    final memberSpending = <String, double>{};
    final memberOrderCount = <String, int>{};
    for (var order in orders) {
      memberSpending[order.userId] = (memberSpending[order.userId] ?? 0) + (order.price * order.quantity);
      memberOrderCount[order.userId] = (memberOrderCount[order.userId] ?? 0) + 1;
    }

    // Popular items
    final itemCounts = <String, int>{};
    final itemRevenue = <String, double>{};
    for (var order in orders) {
      itemCounts[order.itemName] = (itemCounts[order.itemName] ?? 0) + order.quantity;
      itemRevenue[order.itemName] = (itemRevenue[order.itemName] ?? 0) + (order.price * order.quantity);
    }

    // Sort by count
    final popularItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Daily spending trend (last 7 days)
    final dailySpending = <String, double>{};
    for (var order in orders) {
      final dateKey = DateFormat('MM/dd').format(order.createdAt);
      dailySpending[dateKey] = (dailySpending[dateKey] ?? 0) + (order.price * order.quantity);
    }

    return {
      'totalSpent': totalSpent,
      'totalOrders': totalOrders,
      'avgOrderValue': avgOrderValue,
      'memberSpending': memberSpending,
      'memberOrderCount': memberOrderCount,
      'popularItems': popularItems,
      'itemRevenue': itemRevenue,
      'dailySpending': dailySpending,
      'activeMemberCount': memberSpending.length,
    };
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> stats) {
    final timeRangeText = _timeRange == 'all'
        ? 'All Time'
        : _timeRange == '7'
            ? 'Last 7 Days'
            : _timeRange == '30'
                ? 'Last 30 Days'
                : 'Last 90 Days';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.insights,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group Analytics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeRangeText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
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

  Widget _buildKeyMetrics(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                Icons.shopping_bag,
                '${stats['totalOrders']}',
                'Total Orders',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                Icons.people,
                '${stats['activeMemberCount']}',
                'Active Members',
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payments, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Total Spent',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CurrencyDisplay(
                        amount: stats['totalSpent'],
                        textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                        iconColor: Colors.green,
                        iconSize: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Avg Order',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CurrencyDisplay(
                        amount: stats['avgOrderValue'],
                        textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                        iconColor: Colors.orange,
                        iconSize: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTrendSection(BuildContext context, List<Order> orders) {
    final last7Days = orders.where((o) {
      return o.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)));
    }).toList();

    final dailyData = <String, double>{};
    for (var order in last7Days) {
      final dateKey = DateFormat('E').format(order.createdAt);
      dailyData[dateKey] = (dailyData[dateKey] ?? 0) + (order.price * order.quantity);
    }

    if (dailyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending Trend (Last 7 Days)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: dailyData.values.isEmpty ? 100 : dailyData.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barGroups: dailyData.entries.map((e) {
                    final index = dailyData.keys.toList().indexOf(e.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: e.value,
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final keys = dailyData.keys.toList();
                          if (value.toInt() >= 0 && value.toInt() < keys.length) {
                            return Text(keys[value.toInt()], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopMembersSection(BuildContext context, Map<String, dynamic> stats) {
    final memberSpending = stats['memberSpending'] as Map<String, double>;
    final memberOrderCount = stats['memberOrderCount'] as Map<String, int>;
    final groupProvider = Provider.of<GroupProvider>(context);

    final sortedMembers = memberSpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Members',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...sortedMembers.take(5).map((entry) {
          final member = groupProvider.members.firstWhere(
            (m) => m.userId == entry.key,
            orElse: () => groupProvider.members.first,
          );
          final rank = sortedMembers.indexOf(entry) + 1;
          final orderCount = memberOrderCount[entry.key] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: rank == 1
                        ? Colors.amber
                        : rank == 2
                            ? Colors.grey[400]
                            : rank == 3
                                ? Colors.brown[300]
                                : Theme.of(context).colorScheme.primary,
                    child: Text(
                      member.userName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (rank <= 3)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          size: 12,
                          color: rank == 1
                              ? Colors.amber
                              : rank == 2
                                  ? Colors.grey[600]
                                  : Colors.brown,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                member.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('$orderCount orders'),
              trailing: CurrencyDisplay(
                amount: entry.value,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                iconSize: 14,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPopularItemsSection(BuildContext context, Map<String, dynamic> stats) {
    final popularItems = stats['popularItems'] as List<MapEntry<String, int>>;
    final itemRevenue = stats['itemRevenue'] as Map<String, double>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most Ordered Items',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...popularItems.take(5).map((entry) {
          final revenue = itemRevenue[entry.key] ?? 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: const Icon(Icons.fastfood),
              ),
              title: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${entry.value} orders'),
              trailing: CurrencyDisplay(
                amount: revenue,
                textStyle: const TextStyle(fontSize: 14),
                iconSize: 12,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOrderFrequencySection(BuildContext context, Map<String, dynamic> stats) {
    final totalOrders = stats['totalOrders'] as int;
    final days = _timeRange == 'all' ? 30 : int.parse(_timeRange);
    final ordersPerDay = totalOrders / days;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Order Frequency',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      ordersPerDay.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Orders/Day',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Column(
                  children: [
                    Text(
                      '${(ordersPerDay * 7).toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Orders/Week',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
