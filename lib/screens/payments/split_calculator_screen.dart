import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/order.dart';
import '../../widgets/currency_display.dart';

class SplitCalculatorScreen extends StatefulWidget {
  final String groupId;

  const SplitCalculatorScreen({super.key, required this.groupId});

  @override
  State<SplitCalculatorScreen> createState() => _SplitCalculatorScreenState();
}

class _SplitCalculatorScreenState extends State<SplitCalculatorScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _splitMode = 'individual'; // 'individual' or 'equal'
  double _tipPercentage = 0;
  double _additionalFees = 0;
  final TextEditingController _feesController = TextEditingController();

  @override
  void dispose() {
    _feesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Calculator'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: StreamBuilder<List<Order>>(
        stream: _databaseService.getOrdersForGroup(widget.groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allOrders = snapshot.data ?? [];

          if (allOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No orders to split'),
                ],
              ),
            );
          }

          // Group orders by member
          final memberOrders = <String, List<Order>>{};
          final memberTotals = <String, double>{};
          final memberNames = <String, String>{};

          for (var member in groupProvider.members) {
            final orders = allOrders.where((o) => o.userId == member.userId).toList();
            if (orders.isNotEmpty) {
              memberOrders[member.userId] = orders;
              memberTotals[member.userId] = orders.fold(
                0.0,
                (sum, order) => sum + (order.price * order.quantity),
              );
              memberNames[member.userId] = member.userName;
            }
          }

          final subtotal = memberTotals.values.fold(0.0, (sum, amount) => sum + amount);
          final tipAmount = subtotal * (_tipPercentage / 100);
          final grandTotal = subtotal + tipAmount + _additionalFees;

          // Calculate split amounts
          final splitAmounts = <String, double>{};
          if (_splitMode == 'equal') {
            final perPerson = grandTotal / memberTotals.length;
            for (var userId in memberTotals.keys) {
              splitAmounts[userId] = perPerson;
            }
          } else {
            // Individual split with proportional tip and fees
            for (var userId in memberTotals.keys) {
              final proportion = memberTotals[userId]! / subtotal;
              final share = memberTotals[userId]! + (tipAmount * proportion) + (_additionalFees * proportion);
              splitAmounts[userId] = share;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 16)),
                            CurrencyDisplay(
                              amount: subtotal,
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              iconSize: 14,
                            ),
                          ],
                        ),
                        if (_tipPercentage > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tip ($_tipPercentage%)', style: const TextStyle(fontSize: 16)),
                              CurrencyDisplay(
                                amount: tipAmount,
                                textStyle: const TextStyle(fontSize: 16),
                                iconSize: 14,
                              ),
                            ],
                          ),
                        ],
                        if (_additionalFees > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Additional Fees', style: TextStyle(fontSize: 16)),
                              CurrencyDisplay(
                                amount: _additionalFees,
                                textStyle: const TextStyle(fontSize: 16),
                                iconSize: 14,
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            CurrencyDisplay(
                              amount: grandTotal,
                              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              iconColor: Colors.green,
                              iconSize: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Split Mode Selector
                Text(
                  'Split Mode',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Individual Amounts'),
                        selected: _splitMode == 'individual',
                        onSelected: (selected) {
                          if (selected) setState(() => _splitMode = 'individual');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Split Equally'),
                        selected: _splitMode == 'equal',
                        onSelected: (selected) {
                          if (selected) setState(() => _splitMode = 'equal');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tip Selector
                Text(
                  'Add Tip',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [0, 5, 10, 15, 20].map((tip) {
                    return ChoiceChip(
                      label: Text('$tip%'),
                      selected: _tipPercentage == tip,
                      onSelected: (selected) {
                        if (selected) setState(() => _tipPercentage = tip.toDouble());
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Additional Fees
                Text(
                  'Additional Fees',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Delivery, service fees, etc.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _additionalFees = double.tryParse(value) ?? 0;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Per-Person Breakdown
                Text(
                  'Per-Person Breakdown',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...splitAmounts.entries.map((entry) {
                  final userId = entry.key;
                  final amount = entry.value;
                  final name = memberNames[userId] ?? 'Unknown';
                  final isCurrentUser = authProvider.user?.id == userId;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isCurrentUser
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrentUser
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: _splitMode == 'individual'
                          ? Text('${memberOrders[userId]?.length ?? 0} items')
                          : null,
                      trailing: CurrencyDisplay(
                        amount: amount,
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser ? Theme.of(context).colorScheme.primary : null,
                        ),
                        iconSize: 16,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Copy Summary Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _copySummary(context, memberNames, splitAmounts, grandTotal),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Summary'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _copySummary(
    BuildContext context,
    Map<String, String> names,
    Map<String, double> amounts,
    double total,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('💰 Split Payment Summary\n');
    buffer.writeln('Split Mode: ${_splitMode == 'equal' ? 'Equal Split' : 'Individual Amounts'}\n');

    for (var entry in amounts.entries) {
      final name = names[entry.key] ?? 'Unknown';
      buffer.writeln('${name}: ${entry.value.toStringAsFixed(2)} SAR');
    }

    buffer.writeln('\n Total: ${total.toStringAsFixed(2)} SAR');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
