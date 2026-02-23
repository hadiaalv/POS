// lib/models/cart_item.dart
class CartItem {
  final int menuItemId;
  final String name;
  final String categoryName;
  final double price;
  int quantity;

  CartItem({
    required this.menuItemId,
    required this.name,
    required this.categoryName,
    required this.price,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toOrderItemMap() {
    return {
      'menu_item_id': menuItemId,
      'item_name': name,
      'category_name': categoryName,
      'price': price,
      'quantity': quantity,
    };
  }
}