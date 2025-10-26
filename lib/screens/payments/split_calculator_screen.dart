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

  // Applied value (what's actually used in calculations)
  double _appliedAdditionalFees = 0;

  final TextEditingController _feesController = TextEditingController();
  final FocusNode _feesFocusNode = FocusNode();

  @override
  void dispose() {
    _feesController.dispose();
    _feesFocusNode.dispose();
    super.dispose();
  }

  // Check if there are unapplied changes without rebuilding
  bool get _hasUnappliedChanges {
    final currentValue = double.tryParse(_feesController.text) ?? 0;
    return currentValue != _appliedAdditionalFees;
  }

  void _applyFees() {
    final newFees = double.tryParse(_feesController.text) ?? 0;

    setState(() {
      _appliedAdditionalFees = newFees;
    });

    // Unfocus the text field
    _feesFocusNode.unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Fees applied successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetFees() {
    setState(() {
      _feesController.clear();
      _appliedAdditionalFees = 0;
    });
    _feesFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFEF7ED), // Warm cream background
      appBar: AppBar(
        title: const Text('Split Calculator'),
        elevation: 0,
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
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
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
          final grandTotal = subtotal + _appliedAdditionalFees;

          // Calculate split amounts (individual split with equal split of fees)
          final splitAmounts = <String, double>{};
          final memberCount = memberTotals.length;
          final feesPerPerson = memberCount > 0 ? _appliedAdditionalFees / memberCount : 0;

          for (var userId in memberTotals.keys) {
            final share = memberTotals[userId]! + feesPerPerson;
            splitAmounts[userId] = share;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card with warm gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Bill Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSummaryRow('Subtotal', subtotal, false),
                      if (_appliedAdditionalFees > 0) ...[
                        const SizedBox(height: 14),
                        _buildSummaryRow('Additional Fees', _appliedAdditionalFees, false),
                      ],
                      const SizedBox(height: 20),
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSummaryRow('Grand Total', grandTotal, true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Additional Fees Section with inline Apply button
                _buildSectionHeader(
                  'Additional Fees',
                  Icons.add_card_rounded,
                  Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add delivery, service charge, packaging fees, etc.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setInputState) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _hasUnappliedChanges
                              ? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
                              : Colors.grey.shade300,
                          width: _hasUnappliedChanges ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _feesController,
                              focusNode: _feesFocusNode,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Enter amount',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(
                                  Icons.local_shipping_rounded,
                                  color: Theme.of(context).colorScheme.secondary,
                                  size: 22,
                                ),
                                suffixText: 'SAR',
                                suffixStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              onChanged: (value) {
                                // Only rebuild the input widget, not the entire page
                                setInputState(() {});
                              },
                            ),
                          ),
                          if (_hasUnappliedChanges) ...[
                            // Apply Button
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _applyFees,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade500,
                                          Colors.green.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Apply',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (_appliedAdditionalFees > 0 && !_hasUnappliedChanges) ...[
                            // Reset Button
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _resetFees,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.grey.shade600,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),

                // Per-Person Breakdown
                _buildSectionHeader(
                  'Payment Breakdown',
                  Icons.people_rounded,
                  Colors.blue.shade700,
                ),
                const SizedBox(height: 4),
                Text(
                  '${memberTotals.length} ${memberTotals.length == 1 ? 'person' : 'people'} in this group',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ...splitAmounts.entries.map((entry) {
                  final userId = entry.key;
                  final amount = entry.value;
                  final name = memberNames[userId] ?? 'Unknown';
                  final isCurrentUser = authProvider.user?.id == userId;
                  final itemCount = memberOrders[userId]?.length ?? 0;
                  final baseAmount = memberTotals[userId] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: isCurrentUser
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                Theme.of(context).colorScheme.tertiary.withOpacity(0.12),
                              ],
                            )
                          : null,
                      color: isCurrentUser ? null : Colors.white,
                      border: Border.all(
                        color: isCurrentUser
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.15),
                        width: isCurrentUser ? 2.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: (isCurrentUser
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black)
                              .withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isCurrentUser
                                    ? [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.secondary,
                                      ]
                                    : [
                                        Colors.grey.shade400,
                                        Colors.grey.shade600,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (isCurrentUser
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey)
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
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
                                              : Colors.grey[900],
                                        ),
                                      ),
                                    ),
                                    if (isCurrentUser)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).colorScheme.primary,
                                              Theme.of(context).colorScheme.secondary,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          'You',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 15,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (feesPerPerson > 0) ...[
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary
                                              .withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '+${feesPerPerson.toStringAsFixed(2)} fee',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.secondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CurrencyDisplay(
                                amount: amount,
                                textStyle: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentUser
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.green.shade700,
                                ),
                                iconColor: isCurrentUser
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.green.shade700,
                                iconSize: 18,
                              ),
                              if (feesPerPerson > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${baseAmount.toStringAsFixed(2)} + ${feesPerPerson.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Copy Summary Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _copySummary(context, memberNames, splitAmounts, grandTotal),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Summary to Clipboard'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      foregroundColor: Theme.of(context).colorScheme.primary,
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 20 : 17,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: Colors.white,
          ),
        ),
        CurrencyDisplay(
          amount: amount,
          textStyle: TextStyle(
            fontSize: isTotal ? 28 : 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconColor: Colors.white,
          iconSize: isTotal ? 22 : 16,
        ),
      ],
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

    if (_appliedAdditionalFees > 0) {
      buffer.writeln('Additional Fees: ${_appliedAdditionalFees.toStringAsFixed(2)} SAR');
      buffer.writeln();
    }

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
