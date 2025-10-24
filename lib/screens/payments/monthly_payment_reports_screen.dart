import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/payment.dart';
import '../../providers/group_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/currency_display.dart';

class MonthlyPaymentReportsScreen extends StatefulWidget {
  final String groupId;

  const MonthlyPaymentReportsScreen({super.key, required this.groupId});

  @override
  State<MonthlyPaymentReportsScreen> createState() =>
      _MonthlyPaymentReportsScreenState();
}

class _MonthlyPaymentReportsScreenState
    extends State<MonthlyPaymentReportsScreen> {
  DateTime _selectedMonth = DateTime.now();
  final DatabaseService _databaseService = DatabaseService();

  void _selectPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _selectNextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
  }

  Future<void> _exportToCSV(List<Payment> payments) async {
    try {
      List<List<dynamic>> rows = [
        ['Name', 'Email', 'Amount', 'Status', 'Paid At'],
      ];

      for (var payment in payments) {
        rows.add([
          payment.userName,
          '', // Email if available in payment model
          payment.amount,
          payment.paid ? 'Paid' : 'Unpaid',
          payment.paidAt != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(payment.paidAt!)
              : 'N/A',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
      final file = File('${directory.path}/payments_$monthStr.csv');

      // Write to file
      await file.writeAsString(csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final monthStr = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Payment Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              final payments = await _getMonthlyPayments();
              await _exportToCSV(payments);
            },
            tooltip: 'Export to CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _selectPreviousMonth,
                ),
                Text(
                  monthStr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectNextMonth,
                ),
              ],
            ),
          ),

          // Payment data
          Expanded(
            child: FutureBuilder<List<Payment>>(
              future: _getMonthlyPayments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final payments = snapshot.data ?? [];

                if (payments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No payments for $monthStr',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate statistics
                final totalAmount =
                    payments.fold<double>(0, (sum, p) => sum + p.amount);
                final paidAmount = payments
                    .where((p) => p.paid)
                    .fold<double>(0, (sum, p) => sum + p.amount);
                final unpaidAmount = totalAmount - paidAmount;
                final paidCount = payments.where((p) => p.paid).length;
                final unpaidCount = payments.length - paidCount;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total',
                            totalAmount,
                            payments.length,
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Paid',
                            paidAmount,
                            paidCount,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Unpaid',
                            unpaidAmount,
                            unpaidCount,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Chart
                    if (payments.length > 1) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Distribution',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                        value: paidAmount,
                                        title:
                                            '${((paidAmount / totalAmount) * 100).toStringAsFixed(0)}%',
                                        color: Colors.green,
                                        radius: 80,
                                      ),
                                      PieChartSectionData(
                                        value: unpaidAmount,
                                        title:
                                            '${((unpaidAmount / totalAmount) * 100).toStringAsFixed(0)}%',
                                        color: Colors.orange,
                                        radius: 80,
                                      ),
                                    ],
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Payment list
                    Text(
                      'All Payments',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),

                    ...payments.map((payment) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: payment.paid
                                  ? Colors.green
                                  : Colors.orange,
                              child: Icon(
                                payment.paid ? Icons.check : Icons.pending,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(payment.userName),
                            subtitle: payment.paidAt != null
                                ? Text(
                                    'Paid on ${DateFormat('MMM d, h:mm a').format(payment.paidAt!)}',
                                  )
                                : const Text('Not paid yet'),
                            trailing: CurrencyDisplay(
                              amount: payment.amount,
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
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, int count, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            CurrencyDisplay(
              amount: amount,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              iconSize: 12,
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Payment>> _getMonthlyPayments() async {
    // Get start and end of selected month
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

    return await _databaseService.getPaymentsForGroupByDateRange(
      groupId: widget.groupId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }
}
