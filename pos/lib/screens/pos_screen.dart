// lib/screens/pos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../widgets/customer_form.dart';
import '../widgets/category_button.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/cart_item_row.dart';
import '../utils/bill_printer.dart';
import '../utils/constants.dart';
import 'sales_report_screen.dart';
import 'menu_management_screen.dart';

class POSScreen extends StatelessWidget {
  const POSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        title: const Text(
          AppConstants.shopName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SalesReportScreen())),
            icon: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
            label: const Text('Reports', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MenuManagementScreen())),
            icon: const Icon(Icons.menu_book, color: Colors.white, size: 20),
            label: const Text('Menu', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // ── LEFT: Menu Panel ──
          Expanded(
            flex: 6,
            child: Column(
              children: [
                const CustomerForm(),
                const _CategoryBar(),
                const Expanded(child: _MenuGrid()),
              ],
            ),
          ),

          Container(width: 1.5, color: Colors.grey.shade300),

          // ── RIGHT: Cart Panel ──
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: const Color(AppConstants.primaryColorValue),
                  child: const Text(
                    'Current Order',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(child: _CartList()),
                const _OrderSummary(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scrollable Category Bar ──────────────────────────────────────────────────

class _CategoryBar extends StatelessWidget {
  const _CategoryBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menu, _) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              const Text('Category: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: menu.categories.map((cat) => CategoryButton(
                      label: cat.name,
                      isSelected: menu.selectedCategory?.id == cat.id,
                      onTap: () => menu.selectCategory(cat),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Menu Grid ────────────────────────────────────────────────────────────────

class _MenuGrid extends StatelessWidget {
  const _MenuGrid();

  @override
  Widget build(BuildContext context) {
    return Consumer2<MenuProvider, CartProvider>(
      builder: (context, menu, cart, _) {
        if (menu.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (menu.currentItems.isEmpty) {
          return const Center(
              child: Text('No items in this category.',
                  style: TextStyle(color: Colors.grey)));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 170,
            mainAxisExtent: 88,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: menu.currentItems.length,
          itemBuilder: (context, index) {
            final item = menu.currentItems[index];
            return MenuItemCard(
              item: item,
              onTap: () => cart.addItem(item, menu.selectedCategory?.name ?? ''),
            );
          },
        );
      },
    );
  }
}

// ─── Cart List ────────────────────────────────────────────────────────────────

class _CartList extends StatelessWidget {
  const _CartList();

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('No items added', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(6),
          itemCount: cart.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = cart.items[index];
            return CartItemRow(
              item: item,
              onIncrement: () => cart.incrementItem(item.menuItemId),
              onDecrement: () => cart.decrementItem(item.menuItemId),
              onRemove:    () => cart.removeItem(item.menuItemId),
            );
          },
        );
      },
    );
  }
}

// ─── Order Summary + Checkout ─────────────────────────────────────────────────

class _OrderSummary extends StatefulWidget {
  const _OrderSummary();

  @override
  State<_OrderSummary> createState() => _OrderSummaryState();
}

class _OrderSummaryState extends State<_OrderSummary> {
  final _deliveryCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _deliveryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.08),
          offset: const Offset(0, -2),
          blurRadius: 6,
        )],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('Subtotal', 'Rs. ${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 6),

          // Delivery charge input
          Row(
            children: [
              const Text('Delivery Charges:', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _deliveryCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixText: 'Rs. ',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => cart.setDeliveryCharges(double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),

          const Divider(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                'Rs. ${cart.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColorValue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              // Clear
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () {
                    _deliveryCtrl.text = '0';
                    cart.clearCart();
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Print Bill
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print Bill'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: const Color(AppConstants.primaryColorValue),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: cart.items.isEmpty ? null : () => _handlePrint(context, cart),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(value,  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _handlePrint(BuildContext context, CartProvider cart) async {
    if (cart.customerName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter customer name first.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    try {
      await cart.placeOrder();
      await BillPrinter.printBill(cart);

      _deliveryCtrl.text = '0';
      cart.clearCart();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Order saved & bill sent to printer!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}