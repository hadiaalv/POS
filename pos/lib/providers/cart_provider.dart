// lib/providers/cart_provider.dart
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider extends ChangeNotifier {
  int? customerId;
  String customerName = '';
  String customerPhone = '';
  String customerAddress = '';
  bool customerFound = false;

  final List<CartItem> _items = [];
  double deliveryCharges = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get total => subtotal + deliveryCharges;

  Future<bool> lookupCustomer(String phone) async {
    final data = await DBHelper.instance.getCustomerByPhone(phone);
    if (data != null) {
      customerId = data['id'];
      customerName = data['name'];
      customerPhone = phone;
      customerAddress = data['address'] ?? '';
      customerFound = true;
      notifyListeners();
      return true;
    }
    customerFound = false;
    customerId = null;
    customerName = '';
    customerAddress = '';
    customerPhone = phone;
    notifyListeners();
    return false;
  }

  void setCustomerDetails(String name, String address) {
    customerName = name;
    customerAddress = address;
    notifyListeners();
  }

  void addItem(MenuItem item, String categoryName) {
    final existing = _items.where((i) => i.menuItemId == item.id).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      _items.add(CartItem(
        menuItemId: item.id,
        name: item.name,
        categoryName: categoryName,
        price: item.price,
      ));
    }
    notifyListeners();
  }

  void incrementItem(int menuItemId) {
    final item = _items.firstWhere((i) => i.menuItemId == menuItemId);
    item.quantity++;
    notifyListeners();
  }

  void decrementItem(int menuItemId) {
    final item = _items.firstWhere((i) => i.menuItemId == menuItemId);
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.removeWhere((i) => i.menuItemId == menuItemId);
    }
    notifyListeners();
  }

  void removeItem(int menuItemId) {
    _items.removeWhere((i) => i.menuItemId == menuItemId);
    notifyListeners();
  }

  void setDeliveryCharges(double amount) {
    deliveryCharges = amount;
    notifyListeners();
  }

  Future<int> placeOrder() async {
    if (_items.isEmpty) throw Exception('Cart is empty');

    if (!customerFound && customerPhone.isNotEmpty) {
      customerId = await DBHelper.instance.saveCustomer(
        customerPhone, customerName, customerAddress,
      );
      customerFound = true;
    }

    final orderId = await DBHelper.instance.saveOrder(
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      subtotal: subtotal,
      deliveryCharges: deliveryCharges,
      total: total,
      items: _items.map((i) => i.toOrderItemMap()).toList(),
    );

    return orderId;
  }

  void clearCart() {
    _items.clear();
    customerId = null;
    customerName = '';
    customerPhone = '';
    customerAddress = '';
    customerFound = false;
    deliveryCharges = 0;
    notifyListeners();
  }
}