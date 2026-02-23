// lib/widgets/menu_item_card.dart
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../utils/constants.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const MenuItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Items with price 0 show "Ask Price"
    final priceStr = item.price == 0
        ? 'Ask Price'
        : 'Rs. ${item.price.toStringAsFixed(0)}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        splashColor: const Color(AppConstants.primaryColorValue).withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      priceStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.price == 0
                            ? Colors.grey
                            : const Color(AppConstants.primaryColorValue),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(AppConstants.primaryColorValue),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}