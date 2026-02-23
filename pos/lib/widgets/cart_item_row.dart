// lib/widgets/cart_item_row.dart
import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../utils/constants.dart';

class CartItemRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemRow({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Rs. ${item.price.toStringAsFixed(0)} each',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            children: [
              _qtyBtn(Icons.remove, onDecrement, Colors.orange),
              Container(
                width: 36,
                alignment: Alignment.center,
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              _qtyBtn(Icons.add, onIncrement, const Color(AppConstants.primaryColorValue)),
            ],
          ),

          const SizedBox(width: 8),

          // Total price
          SizedBox(
            width: 70,
            child: Text(
              'Rs. ${item.total.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),

          // Remove button
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: Colors.red, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}