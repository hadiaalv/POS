// lib/screens/sales_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../utils/constants.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final report = await DBHelper.instance.getDailySalesReport(dateStr);
    setState(() {
      _report = report;
      _isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _selectedDate = picked;
      await _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            Row(
              children: [
                const Text('Date:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                  onPressed: _pickDate,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Today'),
                  onPressed: () {
                    _selectedDate = DateTime.now();
                    _loadReport();
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_report != null)
              _buildReport(),
          ],
        ),
      ),
    );
  }

  Widget _buildReport() {
    final r = _report!;
    final revenue = (r['total_revenue'] ?? 0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats cards row
        Row(
          children: [
            _statCard(
              'Total Revenue',
              'Rs. ${revenue.toStringAsFixed(0)}',
              Icons.attach_money,
              const Color(AppConstants.primaryColorValue),
            ),
            const SizedBox(width: 16),
            _statCard(
              'Total Orders',
              '${r['total_orders']}',
              Icons.receipt,
              Colors.blue,
            ),
            const SizedBox(width: 16),
            _statCard(
              'Pizzas Sold',
              '${r['total_pizzas'] ?? 0}',
              Icons.local_pizza,
              Colors.orange,
            ),
            const SizedBox(width: 16),
            _statCard(
              'Shawarmas Sold',
              '${r['total_shawarmas'] ?? 0}',
              Icons.lunch_dining,
              Colors.green,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Recent orders
        const Text(
          'Orders Today',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if ((r['recent_orders'] as List).isEmpty)
          const Text('No orders for this day.', style: TextStyle(fontSize: 15, color: Colors.grey))
        else
          Expanded(
            child: ListView.builder(
              itemCount: (r['recent_orders'] as List).length,
              itemBuilder: (context, index) {
                final order = (r['recent_orders'] as List)[index];
                final time = DateFormat('hh:mm a').format(DateTime.parse(order['created_at']));
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(AppConstants.primaryColorValue),
                      child: Text('#${order['id']}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    title: Text(order['customer_name'] ?? 'Walk-in'),
                    subtitle: Text('${order['customer_phone']} • $time'),
                    trailing: Text(
                      'Rs. ${(order['total'] as num).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}