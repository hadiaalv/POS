// lib/screens/customers_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/db_helper.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, dynamic>? _selectedCustomer;
  List<Map<String, dynamic>> _customerOrders = [];
  bool _loadingOrders = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final list = await DBHelper.instance.getAllCustomers();
    setState(() {
      _customers = list;
      _filtered = list;
    });
  }

  void _search(String q) {
    if (q.trim().isEmpty) {
      setState(() => _filtered = _customers);
    } else {
      final lower = q.toLowerCase();
      setState(() {
        _filtered = _customers.where((c) =>
          (c['name'] as String).toLowerCase().contains(lower) ||
          (c['phone'] as String).contains(q)
        ).toList();
      });
    }
  }

  Future<void> _selectCustomer(Map<String, dynamic> customer) async {
    setState(() {
      _selectedCustomer = customer;
      _loadingOrders = true;
    });
    final orders = await DBHelper.instance.getOrdersByCustomer(customer['id']);
    setState(() {
      _customerOrders = orders;
      _loadingOrders = false;
    });
  }

  Future<void> _showOrderDetail(Map<String, dynamic> order) async {
    final items = await DBHelper.instance.getOrderItems(order['id']);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(AppConstants.primaryColorValue)),
            const SizedBox(width: 8),
            Text('Order #${order['id']}'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Date', DateFormat('dd MMM yyyy, hh:mm a')
                  .format(DateTime.parse(order['created_at']))),
              _infoRow('Customer', order['customer_name'] ?? '—'),
              _infoRow('Phone', order['customer_phone'] ?? '—'),
              if ((order['customer_address'] ?? '').toString().isNotEmpty)
                _infoRow('Address', order['customer_address']),
              const Divider(height: 16),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${it['item_name']} × ${it['quantity']}',
                        style: const TextStyle(fontSize: 13))),
                    Text('Rs. ${((it['price'] as num) * (it['quantity'] as num)).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
              const Divider(height: 16),
              _infoRow('Subtotal', 'Rs. ${(order['subtotal'] as num).toStringAsFixed(0)}'),
              _infoRow('Delivery', 'Rs. ${(order['delivery_charges'] as num).toStringAsFixed(0)}'),
              _infoRow('TOTAL', 'Rs. ${(order['total'] as num).toStringAsFixed(0)}', bold: true),
              if ((order['notes'] ?? '').toString().isNotEmpty) ...[
                const Divider(height: 16),
                _infoRow('Notes', order['notes']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: TextStyle(
              color: Colors.grey.shade600, fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            )),
          ),
          Expanded(child: Text(value, style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? const Color(AppConstants.primaryColorValue) : Colors.black87,
          ))),
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
        title: const Text('Customer Directory'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Refresh', style: TextStyle(color: Colors.white)),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: Row(
        children: [
          // ── Customer List ──────────────────────────────────────────
          Container(
            width: 340,
            color: Colors.white,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
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

                // Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_filtered.length} customers',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      Text('Total: ${_customers.length}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                const Divider(height: 8),

                // List
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text('No customers yet',
                                  style: TextStyle(color: Colors.grey.shade400)),
                              const SizedBox(height: 4),
                              Text('Customers are saved when you place orders',
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final c = _filtered[i];
                            final isSelected = _selectedCustomer?['id'] == c['id'];
                            final orders = c['total_orders'] ?? 0;
                            final initials = (c['name'] as String)
                                .trim()
                                .split(' ')
                                .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                                .take(2)
                                .join();
                            return InkWell(
                              onTap: () => _selectCustomer(c),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                color: isSelected
                                    ? const Color(AppConstants.primaryColorValue).withOpacity(0.08)
                                    : Colors.transparent,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? const Color(AppConstants.primaryColorValue)
                                        : Colors.grey.shade200,
                                    child: Text(initials,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : Colors.grey.shade700,
                                        )),
                                  ),
                                  title: Text(c['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 13)),
                                  subtitle: Text(c['phone'],
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey.shade500)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(AppConstants.primaryColorValue)
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('$orders orders',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(AppConstants.primaryColorValue),
                                              fontWeight: FontWeight.w600,
                                            )),
                                      ),
                                      if ((c['total_spent'] ?? 0) > 0)
                                        Text('Rs. ${(c['total_spent'] as num).toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade500,
                                            )),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Divider
          Container(width: 1, color: Colors.grey.shade200),

          // ── Customer Detail ────────────────────────────────────────
          Expanded(
            child: _selectedCustomer == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Select a customer to view details',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                      ],
                    ),
                  )
                : _buildCustomerDetail(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetail() {
    final c = _selectedCustomer!;
    final totalSpent = (c['total_spent'] ?? 0.0) as num;
    final totalOrders = (c['total_orders'] ?? 0) as num;
    final lastOrder = c['last_order_at'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(c['last_order_at']))
        : 'Never';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(AppConstants.primaryColorValue),
                child: Text(
                  (c['name'] as String).trim().split(' ')
                      .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                      .take(2).join(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['name'],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(c['phone'],
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        if ((c['address'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(c['address'],
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action: Add to new order
              ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: const Text('New Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryColorValue),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  context.read<CartProvider>().setCustomerFromMap(c);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),

        // Stats
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _statChip(Icons.receipt, 'Total Orders', '$totalOrders', Colors.blue.shade700),
              const SizedBox(width: 12),
              _statChip(Icons.attach_money, 'Total Spent',
                  'Rs. ${totalSpent.toStringAsFixed(0)}',
                  const Color(AppConstants.primaryColorValue)),
              const SizedBox(width: 12),
              _statChip(Icons.calendar_today, 'Last Order', lastOrder, Colors.green.shade700),
            ],
          ),
        ),

        // Orders header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Text('Order History',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_customerOrders.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        // Orders list
        Expanded(
          child: _loadingOrders
              ? const Center(child: CircularProgressIndicator())
              : _customerOrders.isEmpty
                  ? Center(
                      child: Text('No orders yet',
                          style: TextStyle(color: Colors.grey.shade400)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: _customerOrders.length,
                      itemBuilder: (ctx, i) {
                        final order = _customerOrders[i];
                        final date = DateFormat('dd MMM yyyy, hh:mm a')
                            .format(DateTime.parse(order['created_at']));
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _showOrderDetail(order),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(AppConstants.primaryColorValue)
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text('#${order['id']}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(AppConstants.primaryColorValue),
                                          )),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(date,
                                            style: const TextStyle(
                                                fontSize: 12, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text(order['items_summary'] ?? '',
                                            style: TextStyle(
                                                fontSize: 11, color: Colors.grey.shade500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rs. ${(order['total'] as num).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(AppConstants.primaryColorValue),
                                        ),
                                      ),
                                      if ((order['delivery_charges'] as num) > 0)
                                        Text('+Rs. ${(order['delivery_charges'] as num).toStringAsFixed(0)} delivery',
                                            style: TextStyle(
                                                fontSize: 10, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}