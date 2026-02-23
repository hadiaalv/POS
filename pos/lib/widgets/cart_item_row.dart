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
    final priceStr = item.price == 0 ? '---' : 'Rs. ${item.price.toStringAsFixed(0)}';
    final totalStr = item.price == 0 ? '---' : 'Rs. ${item.total.toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Text(priceStr,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          // Qty controls
          _qtyBtn(Icons.remove, onDecrement, Colors.orange.shade700),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text('${item.quantity}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          _qtyBtn(Icons.add, onIncrement, const Color(AppConstants.primaryColorValue)),

          const SizedBox(width: 6),
          SizedBox(
            width: 72,
            child: Text(totalStr,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, color: Colors.red, size: 16),
            ),
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
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }
}