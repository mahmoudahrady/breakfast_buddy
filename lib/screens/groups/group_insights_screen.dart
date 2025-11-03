import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/group_provider.dart';
import '../../services/database_service.dart';
import '../../models/order.dart';
import '../../widgets/currency_display.dart';
import '../../config/tropical_theme.dart';

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
      backgroundColor: TropicalColors.background,
      appBar: AppBar(
        title: const Text('Group Insights'),
        backgroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            initialValue: _timeRange,
            onSelected: (value) => setState(() => _timeRange = value),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TropicalColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.filter_list_rounded,
                color: TropicalColors.orange,
                size: 22,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: TropicalColors.orange.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      size: 64,
                      color: TropicalColors.orange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No data available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: TropicalColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start ordering to see insights!',
                    style: TextStyle(
                      color: TropicalColors.mediumText,
                      fontSize: 15,
                    ),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TropicalColors.orange.withValues(alpha: 0.08),
            TropicalColors.coral.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TropicalColors.orange.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TropicalColors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 32,
              color: TropicalColors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Group Analytics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TropicalColors.darkText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeRangeText,
                  style: const TextStyle(
                    color: TropicalColors.mediumText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Key Metrics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: TropicalColors.darkText,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                Icons.shopping_bag_rounded,
                '${stats['totalOrders']}',
                'Total Orders',
                TropicalColors.coral,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                Icons.people_rounded,
                '${stats['activeMemberCount']}',
                'Active Members',
                TropicalColors.mint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.only(left: 16, right: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: TropicalColors.mint.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TropicalColors.mint.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: TropicalColors.mint.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.payments_rounded,
                            color: TropicalColors.mint,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Total Spent',
                          style: TextStyle(
                            fontSize: 13,
                            color: TropicalColors.mediumText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CurrencyDisplay(
                      amount: stats['totalSpent'],
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: TropicalColors.mint,
                        letterSpacing: -0.5,
                      ),
                      iconColor: TropicalColors.mint,
                      iconSize: 18,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.only(left: 6, right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: TropicalColors.orange.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TropicalColors.orange.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: TropicalColors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_rounded,
                            color: TropicalColors.orange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Avg Order',
                          style: TextStyle(
                            fontSize: 13,
                            color: TropicalColors.mediumText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CurrencyDisplay(
                      amount: stats['avgOrderValue'],
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: TropicalColors.orange,
                        letterSpacing: -0.5,
                      ),
                      iconColor: TropicalColors.orange,
                      iconSize: 18,
                    ),
                  ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: TropicalColors.mediumText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Spending Trend (Last 7 Days)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: TropicalColors.darkText,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
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
                        color: TropicalColors.orange,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        gradient: LinearGradient(
                          colors: [
                            TropicalColors.orange,
                            TropicalColors.coral,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Top Members',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: TropicalColors.darkText,
              letterSpacing: -0.3,
            ),
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

          return Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: rank == 1
                        ? Colors.amber
                        : rank == 2
                            ? Colors.grey[400]
                            : rank == 3
                                ? Colors.brown[300]
                                : TropicalColors.orange,
                    child: Text(
                      member.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (rank <= 3)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          size: 14,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: TropicalColors.darkText,
                ),
              ),
              subtitle: Text(
                '$orderCount orders',
                style: const TextStyle(
                  color: TropicalColors.mediumText,
                  fontSize: 14,
                ),
              ),
              trailing: CurrencyDisplay(
                amount: entry.value,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TropicalColors.darkText,
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Most Ordered Items',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: TropicalColors.darkText,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...popularItems.take(5).map((entry) {
          final revenue = itemRevenue[entry.key] ?? 0;
          return Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: TropicalColors.coral.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: TropicalColors.coral,
                  size: 24,
                ),
              ),
              title: Text(
                entry.key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: TropicalColors.darkText,
                ),
              ),
              subtitle: Text(
                '${entry.value} orders',
                style: const TextStyle(
                  color: TropicalColors.mediumText,
                  fontSize: 14,
                ),
              ),
              trailing: CurrencyDisplay(
                amount: revenue,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: TropicalColors.darkText,
                ),
                iconSize: 13,
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TropicalColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: TropicalColors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Order Frequency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TropicalColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    ordersPerDay.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: TropicalColors.orange,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Orders/Day',
                    style: TextStyle(
                      fontSize: 14,
                      color: TropicalColors.mediumText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1.5,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              Column(
                children: [
                  Text(
                    (ordersPerDay * 7).toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: TropicalColors.coral,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Orders/Week',
                    style: TextStyle(
                      fontSize: 14,
                      color: TropicalColors.mediumText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
