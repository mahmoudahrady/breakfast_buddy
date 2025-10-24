import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/database_service.dart';
import '../../models/order.dart';
import '../../widgets/currency_display.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String groupId;

  const OrderConfirmationScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final databaseService = DatabaseService();
    final group = groupProvider.selectedGroup;

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Confirmation')),
        body: const Center(child: Text('Group not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Orders'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: StreamBuilder<List<Order>>(
        stream: databaseService.getOrdersForGroup(groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final allOrders = snapshot.data ?? [];

          if (allOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Orders Yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There are no orders to confirm',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Group orders by member
          final memberOrders = <String, List<Order>>{};
          for (var member in groupProvider.members) {
            final orders = allOrders
                .where((order) => order.userId == member.userId)
                .toList();
            if (orders.isNotEmpty) {
              memberOrders[member.userId] = orders;
            }
          }

          // Calculate totals
          final totalAmount = allOrders.fold<double>(
            0.0,
            (sum, order) => sum + (order.price * order.quantity),
          );
          final totalItems = allOrders.fold<int>(
            0,
            (sum, order) => sum + order.quantity,
          );

          return Column(
            children: [
              // Summary Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryStat(
                          context,
                          Icons.people,
                          '${memberOrders.length}',
                          'Members',
                        ),
                        _buildSummaryStat(
                          context,
                          Icons.shopping_bag,
                          '$totalItems',
                          'Items',
                        ),
                        Column(
                          children: [
                            Icon(
                              Icons.payments,
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 4),
                            CurrencyDisplay(
                              amount: totalAmount,
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                              iconColor: Theme.of(context).colorScheme.primary,
                              iconSize: 16,
                            ),
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Orders List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupProvider.members.length,
                  itemBuilder: (context, index) {
                    final member = groupProvider.members[index];
                    final orders = memberOrders[member.userId] ?? [];

                    if (orders.isEmpty) {
                      return const SizedBox.shrink();
                    }

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
                        title: Text(
                          member.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          children: [
                            Text('${orders.length} ${orders.length == 1 ? 'item' : 'items'} • '),
                            CurrencyDisplay(
                              amount: memberTotal,
                              iconSize: 14,
                            ),
                          ],
                        ),
                        children: [
                          ...orders.map((order) => ListTile(
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
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  iconSize: 14,
                                ),
                              )),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Subtotal: ',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                CurrencyDisplay(
                                  amount: memberTotal,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                  iconColor: Theme.of(context).colorScheme.primary,
                                  iconSize: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Confirm Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
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
                                  color: Colors.green,
                                ),
                            iconColor: Colors.green,
                            iconSize: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmOrders(
                            context,
                            orderProvider,
                            groupProvider,
                            allOrders,
                          ),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Confirm All Orders'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This will create payment records and close the group',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _confirmOrders(
    BuildContext context,
    OrderProvider orderProvider,
    GroupProvider groupProvider,
    List<Order> allOrders,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Orders'),
        content: const Text(
          'Are you sure you want to confirm all orders?\n\n'
          '• Payment records will be created for all members\n'
          '• The group will be deactivated\n'
          '• No more orders can be added\n\n'
          'This action cannot be undone.',
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

    if (confirmed == true && context.mounted) {
      try {
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
              groupId: groupProvider.selectedGroup!.id,
            );
          }
        }

        // Deactivate the group
        await groupProvider.toggleGroupActiveStatus(
          groupProvider.selectedGroup!.id,
          false,
        );

        if (context.mounted) {
          // Pop twice to go back to group details
          Navigator.pop(context);
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orders confirmed! Payments created and group deactivated.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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
}
