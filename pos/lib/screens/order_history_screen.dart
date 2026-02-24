// lib/screens/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../utils/constants.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await DBHelper.instance.getRecentOrders(limit: 200);
    setState(() {
      _orders = orders;
      _filtered = orders;
      _loading = false;
    });
  }

  void _search(String q) {
    if (q.trim().isEmpty) {
      setState(() => _filtered = _orders);
      return;
    }
    final lower = q.toLowerCase();
    setState(() {
      _filtered = _orders.where((o) =>
        (o['customer_name'] ?? '').toString().toLowerCase().contains(lower) ||
        (o['customer_phone'] ?? '').toString().contains(q) ||
        o['id'].toString().contains(q)
      ).toList();
    });
  }

  Future<void> _showDetail(Map<String, dynamic> order) async {
    final items = await DBHelper.instance.getOrderItems(order['id']);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(AppConstants.primaryColorValue),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Order #${order['id']}',
                  style: const TextStyle(color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Date', DateFormat('dd MMM yyyy, hh:mm a')
                    .format(DateTime.parse(order['created_at']))),
                _row('Customer', order['customer_name'] ?? 'Walk-in'),
                if ((order['customer_phone'] ?? '').toString().isNotEmpty)
                  _row('Phone', order['customer_phone']),
                if ((order['customer_address'] ?? '').toString().isNotEmpty)
                  _row('Address', order['customer_address']),
                const Divider(height: 20),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(4),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: ['Item', 'Qty', 'Price', 'Total']
                          .map((h) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              child: Text(h,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 12))))
                          .toList(),
                    ),
                    ...items.map((it) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                          child: Text(it['item_name'], style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                          child: Text('${it['quantity']}',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                          child: Text('Rs. ${(it['price'] as num).toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.right),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                          child: Text(
                            'Rs. ${((it['price'] as num) * (it['quantity'] as num)).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
                const Divider(height: 20),
                _row('Subtotal', 'Rs. ${(order['subtotal'] as num).toStringAsFixed(0)}'),
                _row('Delivery', 'Rs. ${(order['delivery_charges'] as num).toStringAsFixed(0)}'),
                const SizedBox(height: 4),
                _row('TOTAL', 'Rs. ${(order['total'] as num).toStringAsFixed(0)}', bold: true),
                if ((order['notes'] ?? '').toString().isNotEmpty) ...[
                  const Divider(height: 16),
                  _row('Notes', order['notes']),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _row(String label, String val, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(
            child: Text(val,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: bold ? const Color(AppConstants.primaryColorValue) : Colors.black87,
                )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        title: const Text('Order History'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Refresh', style: TextStyle(color: Colors.white)),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + stats bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name, phone or order #...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: _search,
                  ),
                ),
                const SizedBox(width: 16),
                Text('Showing ${_filtered.length} of ${_orders.length} orders',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
          ),

          // Table header
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _header('Order #', 80),
                _header('Date & Time', 180),
                _header('Customer', 160),
                _header('Phone', 130),
                Expanded(child: _header('Items', null)),
                _header('Total', 110),
              ],
            ),
          ),

          // Orders
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text('No orders found',
                                style: TextStyle(color: Colors.grey.shade400)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (ctx, i) {
                          final order = _filtered[i];
                          final date = DateFormat('dd MMM, hh:mm a')
                              .format(DateTime.parse(order['created_at']));
                          return InkWell(
                            onTap: () => _showDetail(order),
                            child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // Order #
                                  SizedBox(
                                    width: 80,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(AppConstants.primaryColorValue)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('#${order['id']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(AppConstants.primaryColorValue),
                                          )),
                                    ),
                                  ),
                                  // Date
                                  SizedBox(
                                    width: 180,
                                    child: Text(date,
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                  // Customer name
                                  SizedBox(
                                    width: 160,
                                    child: Text(order['customer_name'] ?? 'Walk-in',
                                        style: const TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  // Phone
                                  SizedBox(
                                    width: 130,
                                    child: Text(order['customer_phone'] ?? '—',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey.shade500)),
                                  ),
                                  // Items summary
                                  Expanded(
                                    child: Text(order['items_summary'] ?? '',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey.shade500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  // Total
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      'Rs. ${(order['total'] as num).toStringAsFixed(0)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(AppConstants.primaryColorValue),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey, size: 16),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _header(String text, double? width) {
    final t = Text(text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey));
    if (width == null) return Expanded(child: t);
    return SizedBox(width: width, child: t);
  }
}