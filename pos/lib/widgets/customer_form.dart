// lib/widgets/customer_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key});

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isLookingUp = false;
  bool _customerLoaded = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupPhone(CartProvider cart) async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLookingUp = true);

    final found = await cart.lookupCustomer(phone);

    if (found) {
      // Auto-fill name and address
      _nameCtrl.text = cart.customerName;
      _addressCtrl.text = cart.customerAddress;
      setState(() => _customerLoaded = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer found: ${cart.customerName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      _nameCtrl.clear();
      _addressCtrl.clear();
      setState(() => _customerLoaded = false);
    }

    setState(() => _isLookingUp = false);
  }

  void _applyCustomerInfo(CartProvider cart) {
    cart.setCustomerDetails(
      _nameCtrl.text.trim(),
      _addressCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    // Sync text fields if cart was cleared
    if (cart.customerPhone.isEmpty && _phoneCtrl.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _phoneCtrl.clear();
        _nameCtrl.clear();
        _addressCtrl.clear();
        setState(() => _customerLoaded = false);
      });
    }

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Info',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Phone field
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. 03001234567',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _customerLoaded
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  onSubmitted: (_) => _lookupPhone(cart),
                ),
              ),
              const SizedBox(width: 8),

              // Lookup button
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLookingUp ? null : () => _lookupPhone(cart),
                  icon: _isLookingUp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Lookup'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              // Name field
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => _applyCustomerInfo(cart),
                ),
              ),
              const SizedBox(width: 8),

              // Address field
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => _applyCustomerInfo(cart),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}