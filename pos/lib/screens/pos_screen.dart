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
import 'sales_report_screen.dart';
import 'menu_management_screen.dart';
import '../utils/constants.dart';

class POSScreen extends StatelessWidget {
  const POSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        title: const Text(
          AppConstants.shopName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SalesReportScreen())),
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            label: const Text('Reports', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MenuManagementScreen())),
            icon: const Icon(Icons.menu_book, color: Colors.white),
            label: const Text('Menu', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // ── LEFT PANEL: Customer + Menu ──
          Expanded(
            flex: 6,
            child: Column(
              children: [
                // Customer form
                const CustomerForm(),

                // Category buttons
                const _CategoryBar(),

                // Menu items grid
                const Expanded(child: _MenuGrid()),
              ],
            ),
          ),

          // Divider
          Container(width: 2, color: Colors.grey.shade300),

          // ── RIGHT PANEL: Cart ──
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // Cart header
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(AppConstants.primaryColorValue),
                  width: double.infinity,
                  child: const Text(
                    'Current Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Cart items list
                const Expanded(child: _CartList()),

                // Order summary + checkout
                const _OrderSummary(),
              ],
            ),
          ),
        ],
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
      builder: (context, menuProvider, _) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Category: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(width: 8),
              ...menuProvider.categories.map((cat) => CategoryButton(
                    label: cat.name,
                    isSelected: menuProvider.selectedCategory?.id == cat.id,
                    onTap: () => menuProvider.selectCategory(cat),
                  )),
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
          return const Center(child: Text('No items in this category.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisExtent: 90,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
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
                Icon(Icons.shopping_cart_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No items yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: cart.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
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

// ─── Order Summary ────────────────────────────────────────────────────────────

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 6,
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _summaryRow('Subtotal', 'Rs. ${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 6),

          // Delivery charges input
          Row(
            children: [
              const Text('Delivery: ', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _deliveryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                    prefixText: 'Rs. ',
                  ),
                  onChanged: (v) {
                    final amount = double.tryParse(v) ?? 0;
                    cart.setDeliveryCharges(amount);
                  },
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(
                'Rs. ${cart.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColorValue),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Action buttons
          Row(
            children: [
              // Clear button
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () {
                    _deliveryCtrl.text = '0';
                    cart.clearCart();
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Print & Save button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Print Bill'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    backgroundColor: const Color(AppConstants.primaryColorValue),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: cart.items.isEmpty
                      ? null
                      : () => _handlePrintBill(context, cart),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _handlePrintBill(BuildContext context, CartProvider cart) async {
    // Validate customer info
    if (cart.customerName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter customer name before printing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Save order to DB
      await cart.placeOrder();

      // Print bill
      await BillPrinter.printBill(cart);

      // Clear cart after print
      _deliveryCtrl.text = '0';
      cart.clearCart();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order saved and bill sent to printer!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}