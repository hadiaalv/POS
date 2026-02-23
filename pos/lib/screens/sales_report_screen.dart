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
            // Date picker row
            Row(
              children: [
                const Text('Date:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                  onPressed: _pickDate,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.today, size: 16),
                  label: const Text('Today'),
                  onPressed: () {
                    _selectedDate = DateTime.now();
                    _loadReport();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_report != null)
              Expanded(child: _buildReport()),
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
        // Stat cards
        Row(
          children: [
            _statCard('Revenue',        'Rs. ${revenue.toStringAsFixed(0)}', Icons.attach_money,  const Color(AppConstants.primaryColorValue)),
            const SizedBox(width: 12),
            _statCard('Orders',         '${r['total_orders']}',              Icons.receipt,        Colors.blue.shade700),
            const SizedBox(width: 12),
            _statCard('Pizzas',         '${r['total_pizzas'] ?? 0}',         Icons.local_pizza,    Colors.orange.shade700),
            const SizedBox(width: 12),
            _statCard('Shawarmas',      '${r['total_shawarmas'] ?? 0}',      Icons.lunch_dining,   Colors.green.shade700),
            const SizedBox(width: 12),
            _statCard('Burgers',        '${r['total_burgers'] ?? 0}',        Icons.fastfood,       Colors.purple.shade700),
          ],
        ),

        const SizedBox(height: 20),
        const Text('Order List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if ((r['recent_orders'] as List).isEmpty)
          const Text('No orders for this date.', style: TextStyle(color: Colors.grey))
        else
          Expanded(
            child: ListView.builder(
              itemCount: (r['recent_orders'] as List).length,
              itemBuilder: (context, index) {
                final order = (r['recent_orders'] as List)[index];
                final time = DateFormat('hh:mm a')
                    .format(DateTime.parse(order['created_at']));
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(AppConstants.primaryColorValue),
                      child: Text('#${order['id']}',
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    title: Text(order['customer_name'] ?? 'Walk-in',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${order['customer_phone'] ?? ''} • $time'),
                    trailing: Text(
                      'Rs. ${(order['total'] as num).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}