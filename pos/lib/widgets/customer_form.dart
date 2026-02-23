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
  final _phoneCtrl   = TextEditingController();
  final _nameCtrl    = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isLookingUp  = false;
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
      _nameCtrl.text    = cart.customerName;
      _addressCtrl.text = cart.customerAddress;
      setState(() => _customerLoaded = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✓ Customer found: ${cart.customerName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
      }
    } else {
      _nameCtrl.clear();
      _addressCtrl.clear();
      setState(() => _customerLoaded = false);
    }
    setState(() => _isLookingUp = false);
  }

  void _applyCustomerInfo(CartProvider cart) {
    cart.setCustomerDetails(_nameCtrl.text.trim(), _addressCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    // Clear form fields when cart is cleared externally
    if (cart.customerPhone.isEmpty && _phoneCtrl.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _phoneCtrl.clear();
        _nameCtrl.clear();
        _addressCtrl.clear();
        setState(() => _customerLoaded = false);
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Info',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),

          Row(
            children: [
              // Phone
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '03001234567',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    suffixIcon: _customerLoaded
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                        : null,
                  ),
                  onSubmitted: (_) => _lookupPhone(cart),
                ),
              ),
              const SizedBox(width: 8),

              // Lookup button
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isLookingUp ? null : () => _lookupPhone(cart),
                  icon: _isLookingUp
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search, size: 18),
                  label: const Text('Lookup'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(90, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Name
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  onChanged: (_) => _applyCustomerInfo(cart),
                ),
              ),

              const SizedBox(width: 8),

              // Address
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address / Area',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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