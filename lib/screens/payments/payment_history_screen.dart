import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/payment.dart';
import '../../widgets/currency_display.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String _statusFilter = 'all'; // 'all', 'paid', 'unpaid'
  String _dateFilter = 'all'; // 'all', 'week', 'month', 'quarter'
  String? _selectedGroupId;
  bool _showFilters = false;

  List<Payment> _filterPayments(List<Payment> payments) {
    var filtered = payments;

    // Filter by status
    if (_statusFilter == 'paid') {
      filtered = filtered.where((p) => p.paid).toList();
    } else if (_statusFilter == 'unpaid') {
      filtered = filtered.where((p) => !p.paid).toList();
    }

    // Filter by date
    if (_dateFilter != 'all') {
      final now = DateTime.now();
      DateTime cutoffDate;

      switch (_dateFilter) {
        case 'week':
          cutoffDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          cutoffDate = now.subtract(const Duration(days: 30));
          break;
        case 'quarter':
          cutoffDate = now.subtract(const Duration(days: 90));
          break;
        default:
          cutoffDate = DateTime(2000);
      }

      filtered = filtered.where((p) =>
        p.createdAt.isAfter(cutoffDate)
      ).toList();
    }

    // Filter by group
    if (_selectedGroupId != null) {
      filtered = filtered.where((p) => p.groupId == _selectedGroupId).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view payment history')),
      );
    }

    // Filter payments for current user
    final userPayments = orderProvider.payments
        .where((p) => p.userId == user.id)
        .toList();

    final filteredPayments = _filterPayments(userPayments);

    // Calculate statistics
    final totalPaid = filteredPayments
        .where((p) => p.paid)
        .fold<double>(0.0, (sum, p) => sum + p.amount);

    final totalUnpaid = filteredPayments
        .where((p) => !p.paid)
        .fold<double>(0.0, (sum, p) => sum + p.amount);

    final paidCount = filteredPayments.where((p) => p.paid).length;
    final unpaidCount = filteredPayments.where((p) => !p.paid).length;

    // Get unique groups
    final uniqueGroupIds = userPayments
        .map((p) => p.groupId)
        .where((id) => id != null)
        .cast<String>()
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
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
        ],
      ),
      body: Column(
        children: [
          // Filters Panel
          if (_showFilters) _buildFiltersPanel(uniqueGroupIds),

          // Statistics Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Payment Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      context,
                      'Paid',
                      paidCount.toString(),
                      totalPaid,
                      Colors.green,
                      Icons.check_circle,
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey[300],
                    ),
                    _buildStatCard(
                      context,
                      'Pending',
                      unpaidCount.toString(),
                      totalUnpaid,
                      Colors.orange,
                      Icons.pending,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Payments List
          Expanded(
            child: userPayments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payment,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Payment History',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your payment records will appear here',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredPayments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No payments found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = filteredPayments[index];
                          return _buildPaymentCard(context, payment);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel(List<String> groupIds) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
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
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _statusFilter = 'all';
                    _dateFilter = 'all';
                    _selectedGroupId = null;
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status Filter
          Text(
            'Payment Status',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _statusFilter == 'all',
                onSelected: (selected) {
                  setState(() => _statusFilter = 'all');
                },
              ),
              ChoiceChip(
                label: const Text('Paid'),
                selected: _statusFilter == 'paid',
                selectedColor: Colors.green[100],
                onSelected: (selected) {
                  setState(() => _statusFilter = selected ? 'paid' : 'all');
                },
              ),
              ChoiceChip(
                label: const Text('Pending'),
                selected: _statusFilter == 'unpaid',
                selectedColor: Colors.orange[100],
                onSelected: (selected) {
                  setState(() => _statusFilter = selected ? 'unpaid' : 'all');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Range Filter
          Text(
            'Date Range',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All Time'),
                selected: _dateFilter == 'all',
                onSelected: (selected) {
                  setState(() => _dateFilter = 'all');
                },
              ),
              ChoiceChip(
                label: const Text('Last 7 Days'),
                selected: _dateFilter == 'week',
                onSelected: (selected) {
                  setState(() => _dateFilter = selected ? 'week' : 'all');
                },
              ),
              ChoiceChip(
                label: const Text('Last 30 Days'),
                selected: _dateFilter == 'month',
                onSelected: (selected) {
                  setState(() => _dateFilter = selected ? 'month' : 'all');
                },
              ),
              ChoiceChip(
                label: const Text('Last 90 Days'),
                selected: _dateFilter == 'quarter',
                onSelected: (selected) {
                  setState(() => _dateFilter = selected ? 'quarter' : 'all');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Group Filter
          if (groupIds.isNotEmpty) ...[
            Text(
              'Filter by Group',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _selectedGroupId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              hint: const Text('All Groups'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Groups'),
                ),
                ...groupIds.map((groupId) {
                  return DropdownMenuItem(
                    value: groupId,
                    child: Text('Group: ${groupId.substring(0, 8)}...'),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGroupId = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String count,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        CurrencyDisplay(
          amount: amount,
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          iconColor: color,
          iconSize: 12,
        ),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    final isPaid = payment.paid;
    final statusColor = isPaid ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPaymentDetails(context, payment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      CurrencyDisplay(
                        amount: payment.amount,
                        textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        iconColor: Theme.of(context).colorScheme.primary,
                        iconSize: 20,
                      ),
                    ],
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaid ? Icons.check_circle : Icons.pending,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPaid ? 'PAID' : 'PENDING',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(payment.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (isPaid && payment.paidAt != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Paid On',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(payment.paidAt!),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (payment.groupId != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.group,
                        size: 14,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Group: ${payment.groupId!.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              payment.paid ? Icons.check_circle : Icons.pending,
              color: payment.paid ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Payment Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(context, 'Status', payment.paid ? 'Paid' : 'Pending'),
              _buildDetailRow(
                context,
                'Amount',
                '${payment.amount.toStringAsFixed(2)} SAR',
                isHighlighted: true,
              ),
              _buildDetailRow(
                context,
                'Created At',
                DateFormat('MMMM d, yyyy • h:mm a').format(payment.createdAt),
              ),
              if (payment.paid && payment.paidAt != null)
                _buildDetailRow(
                  context,
                  'Paid At',
                  DateFormat('MMMM d, yyyy • h:mm a').format(payment.paidAt!),
                ),
              if (payment.groupId != null)
                _buildDetailRow(
                  context,
                  'Group ID',
                  payment.groupId!,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                fontSize: isHighlighted ? 16 : 14,
                color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
