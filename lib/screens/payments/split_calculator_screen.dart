import 'dart:async';
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
  Timer? _debounceTimer;

  @override
  void dispose() {
    _feesController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Calculator'),
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
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 80,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Orders Yet',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add some orders first to calculate\nthe split payment',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
          final memberCount = memberTotals.length;
          final feesPerPerson = memberCount > 0 ? _additionalFees / memberCount : 0;

          if (_splitMode == 'equal') {
            final perPerson = grandTotal / memberCount;
            for (var userId in memberTotals.keys) {
              splitAmounts[userId] = perPerson;
            }
          } else {
            // Individual split with proportional tip and equal split of fees
            for (var userId in memberTotals.keys) {
              final proportion = memberTotals[userId]! / subtotal;
              final share = memberTotals[userId]! + (tipAmount * proportion) + feesPerPerson;
              splitAmounts[userId] = share;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card with Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green,
                        Colors.green.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Bill Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSummaryRow('Subtotal', subtotal, false),
                      if (_tipPercentage > 0) ...[
                        const SizedBox(height: 12),
                        _buildSummaryRow('Tip ($_tipPercentage%)', tipAmount, false),
                      ],
                      if (_additionalFees > 0) ...[
                        const SizedBox(height: 12),
                        _buildSummaryRow('Additional Fees', _additionalFees, false),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Grand Total', grandTotal, true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Split Mode Selector
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.splitscreen_rounded,
                        color: Colors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Split Mode',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeCard(
                        'Individual',
                        'Based on items',
                        Icons.person_rounded,
                        _splitMode == 'individual',
                        () => setState(() => _splitMode = 'individual'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModeCard(
                        'Equal Split',
                        'Divide equally',
                        Icons.people_rounded,
                        _splitMode == 'equal',
                        () => setState(() => _splitMode = 'equal'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Tip Selector
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Tip',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [0, 5, 10, 15, 20].map((tip) {
                    final isSelected = _tipPercentage == tip;
                    return InkWell(
                      onTap: () => setState(() => _tipPercentage = tip.toDouble()),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.amber : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '$tip%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Additional Fees
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Additional Fees',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _feesController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Delivery, service fees, etc.',
                    prefixIcon: const Icon(Icons.payments_rounded),
                    suffixText: 'SAR',
                    helperText: 'Will be split equally among all members',
                    helperMaxLines: 2,
                  ),
                  onChanged: (value) {
                    // Cancel previous timer
                    _debounceTimer?.cancel();

                    // Start new timer - wait 1 second after user stops typing
                    _debounceTimer = Timer(const Duration(seconds: 1), () {
                      setState(() {
                        _additionalFees = double.tryParse(value) ?? 0;
                      });
                    });
                  },
                ),
                if (_additionalFees > 0 && memberTotals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${(_additionalFees / memberTotals.length).toStringAsFixed(2)} SAR per person (${memberTotals.length} ${memberTotals.length == 1 ? 'member' : 'members'})',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                // Per-Person Breakdown
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.people_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Per-Person Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...splitAmounts.entries.map((entry) {
                  final userId = entry.key;
                  final amount = entry.value;
                  final name = memberNames[userId] ?? 'Unknown';
                  final isCurrentUser = authProvider.user?.id == userId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: isCurrentUser
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              ],
                            )
                          : null,
                      border: Border.all(
                        color: isCurrentUser
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                        width: isCurrentUser ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: isCurrentUser
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.secondary,
                                      ],
                                    )
                                  : LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.grey.shade400,
                                        Colors.grey.shade600,
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: (isCurrentUser
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey)
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrentUser
                                              ? Theme.of(context).colorScheme.primary
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentUser)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'You',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (_splitMode == 'individual')
                                  Text(
                                    '${memberOrders[userId]?.length ?? 0} items',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          CurrencyDisplay(
                            amount: amount,
                            textStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isCurrentUser
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.green,
                            ),
                            iconColor: isCurrentUser
                                ? Theme.of(context).colorScheme.primary
                                : Colors.green,
                            iconSize: 18,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Copy Summary Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _copySummary(context, memberNames, splitAmounts, grandTotal),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Summary to Clipboard'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.white,
          ),
        ),
        CurrencyDisplay(
          amount: amount,
          textStyle: TextStyle(
            fontSize: isTotal ? 24 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconColor: Colors.white,
          iconSize: isTotal ? 20 : 14,
        ),
      ],
    );
  }

  Widget _buildModeCard(
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple,
                    Colors.purple.shade700,
                  ],
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

    buffer.writeln('\nTotal: ${total.toStringAsFixed(2)} SAR');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Summary copied to clipboard!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
