// lib/widgets/customer_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/db_helper.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';

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
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _suggestions = [];
  final _phoneFocus = FocusNode();
  final LayerLink _layerLink = LayerLink();

  // Track last known cart phone to detect external changes (e.g. from Customers screen)
  String _lastKnownCartPhone = '';

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), _hideOverlay);
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneFocus.dispose();
    _hideOverlay();
    super.dispose();
  }

  Future<void> _onPhoneChanged(String value, CartProvider cart) async {
    // Update cart phone live so other parts of UI stay in sync
    cart.customerPhone = value;
    cart.notifyListeners();

    if (value.length < 3) {
      _hideOverlay();
      setState(() => _suggestions = []);
      return;
    }
    final results = await DBHelper.instance.searchCustomers(value);
    if (!mounted) return;
    setState(() => _suggestions = results);
    if (results.isNotEmpty) {
      _showOverlay(cart);
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay(CartProvider cart) {
    _hideOverlay();
    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: 340,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 44),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (ctx2, i) {
                  final c = _suggestions[i];
                  return InkWell(
                    onTap: () => _selectSuggestion(c, cart),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(AppConstants.primaryColorValue)
                                .withOpacity(0.12),
                            child: Text(
                              (c['name'] as String).trim().isNotEmpty
                                  ? (c['name'] as String).trim()[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(AppConstants.primaryColorValue),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(c['phone'],
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          if ((c['total_orders'] ?? 0) > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${c['total_orders']} orders',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(Map<String, dynamic> c, CartProvider cart) {
    _hideOverlay();
    _phoneCtrl.text   = c['phone'] as String;
    _nameCtrl.text    = c['name'] as String;
    _addressCtrl.text = (c['address'] ?? '') as String;
    _lastKnownCartPhone = c['phone'] as String;
    cart.setCustomerFromMap(c);
    setState(() => _customerLoaded = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ ${c['name']} — ${c['total_orders'] ?? 0} previous orders'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _lookupPhone(CartProvider cart) async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    _hideOverlay();

    setState(() => _isLookingUp = true);
    final found = await cart.lookupCustomer(phone);
    _lastKnownCartPhone = phone;

    if (found) {
      _nameCtrl.text    = cart.customerName;
      _addressCtrl.text = cart.customerAddress;
      setState(() {
        _customerLoaded = true;
        _isLookingUp = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✓ Customer found: ${cart.customerName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
      }
    } else {
      setState(() {
        _customerLoaded = false;
        _isLookingUp = false;
      });
    }
  }

  /// Called when user manually edits name or address fields
  void _onNameChanged(String value, CartProvider cart) {
    cart.customerName = value;
    cart.notifyListeners();
  }

  void _onAddressChanged(String value, CartProvider cart) {
    cart.customerAddress = value;
    cart.notifyListeners();
  }

  void _clearForm(CartProvider cart) {
    _phoneCtrl.clear();
    _nameCtrl.clear();
    _addressCtrl.clear();
    _lastKnownCartPhone = '';
    _hideOverlay();
    setState(() => _customerLoaded = false);
  }

  @override
  Widget build(BuildContext context) {
    // Use read for actions, only watch the specific flag we need
    final cart = context.read<CartProvider>();

    // Detect when cart was cleared externally (e.g. after Print Bill)
    // or when customer was loaded from Customers screen
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        // Cart was cleared — reset form
        if (cart.customerPhone.isEmpty && _lastKnownCartPhone.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _clearForm(cart);
          });
        }

        // Customer loaded from Customers screen — populate form
        if (cart.customerFound &&
            cart.customerPhone.isNotEmpty &&
            cart.customerPhone != _lastKnownCartPhone) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _phoneCtrl.text   = cart.customerPhone;
              _nameCtrl.text    = cart.customerName;
              _addressCtrl.text = cart.customerAddress;
              _lastKnownCartPhone = cart.customerPhone;
              setState(() => _customerLoaded = true);
            }
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16,
                      color: Color(AppConstants.primaryColorValue)),
                  const SizedBox(width: 6),
                  const Text('Customer Info',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (_customerLoaded) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text('Returning Customer',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  // ── Phone field with autocomplete ──
                  CompositedTransformTarget(
                    link: _layerLink,
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _phoneCtrl,
                        focusNode: _phoneFocus,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '03001234567',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          suffixIcon: _customerLoaded
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green, size: 18)
                              : null,
                        ),
                        onChanged: (v) => _onPhoneChanged(v, cart),
                        onSubmitted: (_) => _lookupPhone(cart),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ── Search button ──
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _isLookingUp ? null : () => _lookupPhone(cart),
                      icon: _isLookingUp
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search, size: 16),
                      label: const Text('Search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppConstants.primaryColorValue),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ── Customer Name ──
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      onChanged: (v) => _onNameChanged(v, cart),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ── Address ──
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Address / Area',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      onChanged: (v) => _onAddressChanged(v, cart),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}