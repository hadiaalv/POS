// lib/screens/menu_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../database/db_helper.dart';
import '../utils/constants.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  int?    _selectedCategoryId;
  String  _selectedCategoryName = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _addItem(MenuProvider menu) async {
    final name  = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;

    if (name.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill item name and select category.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    await menu.addMenuItem(_selectedCategoryId!, name, price);
    _nameCtrl.clear();
    _priceCtrl.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ "$name" added to $_selectedCategoryName'),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<void> _editPriceDialog(int itemId, String itemName, double currentPrice, MenuProvider menu) async {
    final ctrl = TextEditingController(text: currentPrice.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Price: $itemName'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'New Price (Rs.)',
            border: OutlineInputBorder(),
            prefixText: 'Rs. ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text) ?? currentPrice),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != currentPrice) {
      await DBHelper.instance.updateMenuItem(itemId, itemName, result);
      await menu.selectCategory(menu.selectedCategory!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Reload', style: TextStyle(color: Colors.white)),
            onPressed: () => context.read<MenuProvider>().reload(),
          ),
        ],
      ),
      body: Consumer<MenuProvider>(
        builder: (context, menu, _) {
          // Auto-select first category on load
          if (_selectedCategoryId == null && menu.categories.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedCategoryId   = menu.categories.first.id;
                _selectedCategoryName = menu.categories.first.name;
              });
            });
          }

          return Row(
            children: [
              // ── Add Item Form ──
              Container(
                width: 290,
                padding: const EdgeInsets.all(20),
                color: Colors.grey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add New Item',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                          labelText: 'Category', border: OutlineInputBorder()),
                      items: menu.categories
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (val) {
                        final cat = menu.categories.firstWhere((c) => c.id == val);
                        setState(() {
                          _selectedCategoryId   = val;
                          _selectedCategoryName = cat.name;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Item Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price (Rs.) — 0 = Ask Price',
                        border: OutlineInputBorder(),
                        prefixText: 'Rs. ',
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppConstants.primaryColorValue),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                        ),
                        onPressed: () => _addItem(menu),
                      ),
                    ),

                    const Divider(height: 32),

                    const Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('• Price = 0 shows "Ask Price" on menu\n'
                        '• Tap edit icon to update price\n'
                        '• Toggle switch to show/hide item',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),

              // ── Items List ──
              Expanded(
                child: Column(
                  children: [
                    // Category tabs
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: menu.categories.map((cat) {
                            final isSel = menu.selectedCategory?.id == cat.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ElevatedButton(
                                onPressed: () => menu.selectCategory(cat),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSel
                                      ? const Color(AppConstants.primaryColorValue)
                                      : Colors.grey.shade200,
                                  foregroundColor: isSel ? Colors.white : Colors.black87,
                                  minimumSize: const Size(80, 40),
                                ),
                                child: Text(cat.name, style: const TextStyle(fontSize: 13)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    // Items
                    Expanded(
                      child: menu.currentItems.isEmpty
                          ? const Center(child: Text('No items. Add some!', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: menu.currentItems.length,
                              itemBuilder: (context, index) {
                                final item = menu.currentItems[index];
                                final priceStr = item.price == 0
                                    ? 'Ask Price'
                                    : 'Rs. ${item.price.toStringAsFixed(0)}';
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    title: Text(item.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(priceStr,
                                        style: TextStyle(
                                          color: item.price == 0
                                              ? Colors.grey
                                              : const Color(AppConstants.primaryColorValue),
                                          fontWeight: FontWeight.w500,
                                        )),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Edit price
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                          tooltip: 'Edit price',
                                          onPressed: () => _editPriceDialog(
                                              item.id, item.name, item.price, menu),
                                        ),
                                        // Toggle available
                                        Switch(
                                          value: item.isAvailable,
                                          activeColor: Colors.green,
                                          onChanged: (val) async {
                                            await DBHelper.instance.toggleMenuItem(item.id, val);
                                            await menu.selectCategory(menu.selectedCategory!);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}