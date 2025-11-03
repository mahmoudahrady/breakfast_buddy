import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../utils/currency_utils.dart';

class OrdersSummaryScreen extends StatelessWidget {
  const OrdersSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final orders = orderProvider.orders;

    // Group orders by user
    final Map<String, List<Order>> ordersByUser = {};
    final Map<String, double> totalsByUser = {};

    for (var order in orders) {
      if (!ordersByUser.containsKey(order.userId)) {
        ordersByUser[order.userId] = [];
        totalsByUser[order.userId] = 0.0;
      }
      ordersByUser[order.userId]!.add(order);
      totalsByUser[order.userId] = totalsByUser[order.userId]! + order.totalPrice;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Summary'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (orderProvider.currentSession?.isOpen ?? false)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _showCloseSessionDialog(context, orderProvider),
              tooltip: 'Close Session',
            ),
        ],
      ),
      body: orders.isEmpty
          ? const Center(
              child: Text('No orders yet'),
            )
          : Column(
              children: [
                // Summary Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Column(
                    children: [
                      Text(
                        'Total Orders: ${orders.length}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Grand Total: ${CurrencyUtils.formatCurrency(orderProvider.currentSession?.totalAmount ?? 0)}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Participants: ${ordersByUser.length}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),

                // Orders by User
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ordersByUser.length,
                    itemBuilder: (context, index) {
                      String userId = ordersByUser.keys.elementAt(index);
                      List<Order> userOrders = ordersByUser[userId]!;
                      double userTotal = totalsByUser[userId]!;
                      String userName = userOrders.first.userName;

                      return _buildUserOrdersCard(
                        context,
                        userName,
                        userOrders,
                        userTotal,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserOrdersCard(
    BuildContext context,
    String userName,
    List<Order> orders,
    double total,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            userName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${orders.length} item${orders.length > 1 ? 's' : ''}',
        ),
        trailing: Text(
          CurrencyUtils.formatCurrency(total),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        children: orders.map((order) {
          final totalPrice = order.totalPrice;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            leading: order.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, size: 24),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fastfood, size: 24),
                  ),
            title: Row(
              children: [
                Expanded(child: Text(order.itemName)),
                if (order.quantity > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'x${order.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('h:mm a').format(order.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (order.quantity > 1)
                  Text(
                    '${CurrencyUtils.formatCurrency(order.basePrice)} each',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
            trailing: Text(
              CurrencyUtils.formatCurrency(totalPrice),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCloseSessionDialog(
    BuildContext context,
    OrderProvider orderProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Order Session'),
        content: const Text(
          'Are you sure you want to close this order session? '
          'No more orders can be added after closing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await orderProvider.closeSession();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order session closed'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Session'),
          ),
        ],
      ),
    );
  }
}
