import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../models/payment.dart';
import '../../utils/currency_utils.dart';

class PaymentTrackingScreen extends StatelessWidget {
  final String? groupId; // Optional groupId to filter payments by group

  const PaymentTrackingScreen({super.key, this.groupId});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    // Filter payments by groupId if provided
    final payments = groupId != null
        ? orderProvider.payments.where((p) => p.groupId == groupId).toList()
        : orderProvider.payments;

    // Calculate totals
    int totalParticipants = payments.length;
    int paidCount = payments.where((p) => p.paid).length;
    int unpaidCount = payments.where((p) => !p.paid).length;
    double totalPaid = payments.where((p) => p.paid).fold(0.0, (sum, p) => sum + p.amount);
    double totalUnpaid = payments.where((p) => !p.paid).fold(0.0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Tracking'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          // Payment Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            child: Column(
              children: [
                Text(
                  'Payment Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryCard(
                      context,
                      'Paid',
                      paidCount.toString(),
                      Colors.green,
                      CurrencyUtils.formatCurrency(totalPaid),
                    ),
                    _buildSummaryCard(
                      context,
                      'Unpaid',
                      unpaidCount.toString(),
                      Colors.orange,
                      CurrencyUtils.formatCurrency(totalUnpaid),
                    ),
                    _buildSummaryCard(
                      context,
                      'Total',
                      totalParticipants.toString(),
                      Theme.of(context).colorScheme.primary,
                      CurrencyUtils.formatCurrency(orderProvider.currentSession?.totalAmount ?? 0),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Payment List
          Expanded(
            child: payments.isEmpty
                ? const Center(
                    child: Text('No payments yet'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      return _buildPaymentCard(
                        context,
                        payments[index],
                        orderProvider,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String count,
    Color color,
    String amount,
  ) {
    return Card(
      elevation: 2,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    Payment payment,
    OrderProvider orderProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: payment.paid
              ? Colors.green
              : Theme.of(context).colorScheme.primary,
          child: Icon(
            payment.paid ? Icons.check : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          payment.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              CurrencyUtils.formatCurrency(payment.amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (payment.paid && payment.paidAt != null)
              Text(
                'Paid on ${DateFormat('MMM d, h:mm a').format(payment.paidAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: payment.paid
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PAID',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : TextButton(
                onPressed: () {
                  _showMarkAsPaidDialog(
                    context,
                    payment,
                    orderProvider,
                  );
                },
                child: const Text('Mark Paid'),
              ),
      ),
    );
  }

  void _showMarkAsPaidDialog(
    BuildContext context,
    Payment payment,
    OrderProvider orderProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text(
          'Mark ${payment.userName}\'s payment of '
          '${CurrencyUtils.formatCurrency(payment.amount)} as paid?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await orderProvider.markPaymentAsPaid(payment.userId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment marked as paid'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
  }
}
