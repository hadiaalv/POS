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
import 'customers_screen.dart';
import 'order_history_screen.dart';

class POSScreen extends StatelessWidget {
  const POSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              AppConstants.shopName,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.4),
            ),
          ],
        ),
        actions: [
          _NavBtn(
            icon: Icons.history,
            label: 'Orders',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
          ),
          _NavBtn(
            icon: Icons.people_alt_outlined,
            label: 'Customers',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CustomersScreen())),
          ),
          _NavBtn(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SalesReportScreen())),
          ),
          _NavBtn(
            icon: Icons.menu_book_outlined,
            label: 'Menu',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MenuManagementScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // ── LEFT: Menu Panel ──────────────────────────────────────
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

          // Divider
          Container(
            width: 1,
            color: Colors.grey.shade300,
          ),

          // ── RIGHT: Cart Panel ─────────────────────────────────────
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryColorValue),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Current Order',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ],
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

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: Colors.white70),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Category Bar ─────────────────────────────────────────────────────────────

class _CategoryBar extends StatelessWidget {
  const _CategoryBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menu, _) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            children: [
              Text('Category:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: menu.categories
                        .map((cat) => CategoryButton(
                              label: cat.name,
                              isSelected: menu.selectedCategory?.id == cat.id,
                              onTap: () => menu.selectCategory(cat),
                            ))
                        .toList(),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.no_food_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                const Text('No items in this category.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
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
                Icon(Icons.shopping_bag_outlined, size: 52, color: Colors.grey.shade200),
                const SizedBox(height: 10),
                Text('No items added',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Tap items on the left to add',
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(6),
          itemCount: cart.items.length,
          separatorBuilder: (_, __) => Divider(
              height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            final item = cart.items[index];
            return CartItemRow(
              item: item,
              onIncrement: () => cart.incrementItem(item.menuItemId),
              onDecrement: () => cart.decrementItem(item.menuItemId),
              onRemove: () => cart.removeItem(item.menuItemId),
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
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _deliveryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.customerPhone.isEmpty) {
      if (_deliveryCtrl.text != '0') _deliveryCtrl.text = '0';
      if (_notesCtrl.text.isNotEmpty) _notesCtrl.clear();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            offset: const Offset(0, -2),
            blurRadius: 8,
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item count
          if (cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${cart.items.fold(0, (s, i) => s + i.quantity)} items',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ),

          _row('Subtotal', 'Rs. ${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),

          // Delivery input
          Row(
            children: [
              Text('Delivery:',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _deliveryCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixText: 'Rs. ',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      cart.setDeliveryCharges(double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Notes
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Order notes (optional)...',
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(),
            ),
            onChanged: cart.setNotes,
          ),

          const Divider(height: 14),

          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text(
                'Rs. ${cart.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColorValue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              // Clear
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () {
                  _deliveryCtrl.text = '0';
                  _notesCtrl.clear();
                  cart.clearCart();
                },
              ),
              const SizedBox(width: 8),

              // Print Bill
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Print Bill'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    backgroundColor: const Color(AppConstants.primaryColorValue),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: cart.items.isEmpty
                      ? null
                      : () => _handlePrint(context, cart),
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
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
      _notesCtrl.clear();
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