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
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  int? _selectedCategoryId;
  String _selectedCategoryName = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _addItem(MenuProvider menu) async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());

    if (name.isEmpty || price == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    await menu.addMenuItem(_selectedCategoryId!, name, price);
    _nameCtrl.clear();
    _priceCtrl.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name added to $_selectedCategoryName'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
      ),
      body: Consumer<MenuProvider>(
        builder: (context, menu, _) {
          if (_selectedCategoryId == null && menu.categories.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedCategoryId = menu.categories.first.id;
                _selectedCategoryName = menu.categories.first.name;
              });
            });
          }

          return Row(
            children: [
              // Add item form
              Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                color: Colors.grey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add New Item',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: menu.categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        final cat = menu.categories.firstWhere((c) => c.id == val);
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedCategoryName = cat.name;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (Rs.)',
                        border: OutlineInputBorder(),
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
                          minimumSize: const Size(0, 52),
                        ),
                        onPressed: () => _addItem(menu),
                      ),
                    ),
                  ],
                ),
              ),

              // Menu items list with toggle
              Expanded(
                child: Column(
                  children: [
                    // Category tab bar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: menu.categories.map((cat) {
                          final isSelected = menu.selectedCategory?.id == cat.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: () => menu.selectCategory(cat),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? const Color(AppConstants.primaryColorValue)
                                    : Colors.grey.shade200,
                                foregroundColor:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                              child: Text(cat.name),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Items list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: menu.currentItems.length,
                        itemBuilder: (context, index) {
                          final item = menu.currentItems[index];
                          return Card(
                            child: ListTile(
                              title: Text(item.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('Rs. ${item.price.toStringAsFixed(0)}'),
                              trailing: Switch(
                                value: item.isAvailable,
                                activeColor: Colors.green,
                                onChanged: (val) async {
                                  await DBHelper.instance.toggleMenuItem(item.id, val);
                                  await menu.selectCategory(menu.selectedCategory!);
                                },
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