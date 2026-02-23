// lib/providers/menu_provider.dart
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/menu_item.dart';

class MenuProvider extends ChangeNotifier {
  List<MenuCategory> categories = [];
  List<MenuItem> currentItems = [];
  MenuCategory? selectedCategory;
  bool isLoading = false;

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    final catMaps = await DBHelper.instance.getCategories();
    categories = catMaps.map((m) => MenuCategory.fromMap(m)).toList();

    if (categories.isNotEmpty) {
      await selectCategory(categories.first);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> selectCategory(MenuCategory category) async {
    selectedCategory = category;
    final itemMaps = await DBHelper.instance.getMenuItemsByCategory(category.id);
    currentItems = itemMaps.map((m) => MenuItem.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> addMenuItem(int categoryId, String name, double price) async {
    await DBHelper.instance.addMenuItem(categoryId, name, price);
    if (selectedCategory?.id == categoryId) {
      await selectCategory(selectedCategory!);
    }
  }

  Future<void> reload() async {
    await loadData();
  }
}