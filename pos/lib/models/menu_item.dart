// lib/models/menu_item.dart
class MenuItem {
  final int id;
  final int categoryId;
  final String name;
  final double price;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    this.isAvailable = true,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'],
      categoryId: map['category_id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      isAvailable: map['is_available'] == 1,
    );
  }
}

class MenuCategory {
  final int id;
  final String name;

  MenuCategory({required this.id, required this.name});

  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    return MenuCategory(id: map['id'], name: map['name']);
  }
}