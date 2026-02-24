// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider extends ChangeNotifier {
  int?   customerId;
  String customerName    = '';
  String customerPhone   = '';
  String customerAddress = '';
  bool   customerFound   = false;
  String orderNotes      = '';

  final List<CartItem> _items = [];
  double deliveryCharges = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.total);
  double get total    => subtotal + deliveryCharges;

  // ── Customer ──────────────────────────────────────────────────────────────

  Future<bool> lookupCustomer(String phone) async {
    final data = await DBHelper.instance.getCustomerByPhone(phone);
    if (data != null) {
      customerId      = data['id'] as int?;
      customerName    = data['name'] as String;
      customerPhone   = phone;
      customerAddress = (data['address'] ?? '') as String;
      customerFound   = true;
      notifyListeners();
      return true;
    }
    customerFound   = false;
    customerId      = null;
    customerName    = '';
    customerAddress = '';
    customerPhone   = phone;
    notifyListeners();
    return false;
  }

  void setCustomerDetails(String name, String address) {
    customerName    = name;
    customerAddress = address;
    notifyListeners();
  }

  void setCustomerFromMap(Map<String, dynamic> data) {
    customerId      = data['id'] as int?;
    customerName    = data['name'] as String;
    customerPhone   = data['phone'] as String;
    customerAddress = (data['address'] ?? '') as String;
    customerFound   = true;
    notifyListeners();
  }

  void setNotes(String notes) {
    orderNotes = notes;
    // no notifyListeners — avoids rebuild loop while typing
  }

  // ── Cart items ────────────────────────────────────────────────────────────

  void addItem(MenuItem item, String categoryName) {
    final existing = _items.where((i) => i.menuItemId == item.id).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      _items.add(CartItem(
        menuItemId:   item.id,
        name:         item.name,
        categoryName: categoryName,
        price:        item.price,
      ));
    }
    notifyListeners();
  }

  void incrementItem(int menuItemId) {
    _items.firstWhere((i) => i.menuItemId == menuItemId).quantity++;
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

  // ── Order ─────────────────────────────────────────────────────────────────

  Future<int> placeOrder() async {
    if (_items.isEmpty) throw Exception('Cart is empty');

    if (!customerFound && customerPhone.isNotEmpty) {
      customerId    = await DBHelper.instance.saveCustomer(
          customerPhone, customerName, customerAddress);
      customerFound = true;
    } else if (customerFound && customerId != null) {
      await DBHelper.instance.updateCustomer(
          customerPhone, customerName, customerAddress);
    }

    return await DBHelper.instance.saveOrder(
      customerId:       customerId,
      customerName:     customerName,
      customerPhone:    customerPhone,
      customerAddress:  customerAddress,
      subtotal:         subtotal,
      deliveryCharges:  deliveryCharges,
      total:            total,
      items:            _items.map((i) => i.toOrderItemMap()).toList(),
      notes:            orderNotes.isEmpty ? null : orderNotes,
    );
  }

  void clearCart() {
    _items.clear();
    customerId      = null;
    customerName    = '';
    customerPhone   = '';
    customerAddress = '';
    customerFound   = false;
    deliveryCharges = 0;
    orderNotes      = '';
    notifyListeners();
  }
}