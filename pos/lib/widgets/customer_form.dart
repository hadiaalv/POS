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

  bool _isLookingUp    = false;
  bool _customerLoaded = false;

  // When true the ListenableBuilder skips its "external fill" logic because
  // we are already handling the fill directly inside _selectSuggestion.
  bool _suppressListenerFill = false;

  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _suggestions = [];
  _ActiveField _activeField = _ActiveField.none;

  final _phoneFocus    = FocusNode();
  final _nameFocus     = FocusNode();
  final LayerLink _phoneLayerLink = LayerLink();
  final LayerLink _nameLayerLink  = LayerLink();

  // The phone we last "confirmed" (lookup, selection, or external load).
  // Used to detect a cart-cleared event vs a new external customer load.
  String _lastKnownCartPhone = '';

  @override
  void initState() {
    super.initState();
    // Dismiss overlay when the driving field loses focus,
    // but only after a short delay so a tap on a row registers first.
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _activeField == _ActiveField.phone) _hideOverlay();
        });
      }
    });
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _activeField == _ActiveField.name) _hideOverlay();
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneFocus.dispose();
    _nameFocus.dispose();
    _hideOverlay();
    super.dispose();
  }

  // ── Text field callbacks ───────────────────────────────────────────────────

  Future<void> _onPhoneChanged(String value, CartProvider cart) async {
    cart.customerPhone = value;
    // Don't notifyListeners here — it would trigger the ListenableBuilder
    // and interfere while the user is still typing.
    if (value.length < 2) {
      _hideOverlay();
      setState(() => _suggestions = []);
      return;
    }
    await _fetchAndShow(value, cart, _ActiveField.phone);
  }

  Future<void> _onNameChanged(String value, CartProvider cart) async {
    cart.customerName = value;
    if (value.length < 2) {
      _hideOverlay();
      setState(() => _suggestions = []);
      return;
    }
    await _fetchAndShow(value, cart, _ActiveField.name);
  }

  void _onAddressChanged(String value, CartProvider cart) {
    cart.customerAddress = value;
  }

  // ── Autocomplete fetch ────────────────────────────────────────────────────

  Future<void> _fetchAndShow(
      String query, CartProvider cart, _ActiveField field) async {
    final results = await DBHelper.instance.searchCustomers(query);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _activeField = field;
    });
    if (results.isNotEmpty) {
      _showOverlay(cart, field);
    } else {
      _hideOverlay();
    }
  }

  // ── Overlay ───────────────────────────────────────────────────────────────

  void _showOverlay(CartProvider cart, _ActiveField field) {
    _hideOverlay();
    final layerLink =
        field == _ActiveField.phone ? _phoneLayerLink : _nameLayerLink;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: 380,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 46),
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(10),
            shadowColor: Colors.black26,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(AppConstants.primaryColorValue)
                          .withOpacity(0.06),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10)),
                      border: Border(
                          bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people_alt_outlined,
                            size: 14,
                            color: const Color(AppConstants.primaryColorValue)),
                        const SizedBox(width: 6),
                        Text(
                          '${_suggestions.length} matching customer'
                          '${_suggestions.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Rows ──
                  Flexible(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (ctx, i) {
                        final c = _suggestions[i];
                        final totalOrders = (c['total_orders'] ?? 0) as int;
                        final totalSpent  = (c['total_spent'] ?? 0.0) as num;
                        final name        = c['name'] as String;
                        final initials = name
                            .trim()
                            .split(' ')
                            .where((w) => w.isNotEmpty)
                            .map((w) => w[0].toUpperCase())
                            .take(2)
                            .join();

                        return InkWell(
                          onTap: () => _selectSuggestion(c, cart),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: i < _suggestions.length - 1
                                  ? Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade100))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(
                                          AppConstants.primaryColorValue)
                                      .withOpacity(0.12),
                                  child: Text(
                                    initials.isEmpty ? '?' : initials,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(AppConstants.primaryColorValue),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Name + phone + address
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.phone,
                                              size: 11,
                                              color: Colors.grey.shade500),
                                          const SizedBox(width: 3),
                                          Text(
                                            c['phone'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                          if ((c['address'] ?? '')
                                              .toString()
                                              .isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Icon(Icons.location_on,
                                                size: 11,
                                                color: Colors.grey.shade400),
                                            const SizedBox(width: 2),
                                            Flexible(
                                              child: Text(
                                                c['address'] as String,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade400,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Stats badge
                                if (totalOrders > 0)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.green.shade200),
                                        ),
                                        child: Text(
                                          '$totalOrders order'
                                          '${totalOrders == 1 ? '' : 's'}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (totalSpent > 0) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Rs. ${totalSpent.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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

  // ── Selection — THE critical method ──────────────────────────────────────
  //
  // Order of operations matters:
  //  1. Hide overlay immediately (before any async work or rebuilds).
  //  2. Set _suppressListenerFill + _lastKnownCartPhone BEFORE touching cart,
  //     so the ListenableBuilder won't clobber anything when cart notifies.
  //  3. Fill controllers directly right now — instant, no frame delay.
  //  4. Update local _customerLoaded state.
  //  5. Call cart.setCustomerFromMap last (this fires notifyListeners).
  //  6. Release suppression after the current frame settles.

  void _selectSuggestion(Map<String, dynamic> c, CartProvider cart) {
    // 1
    _hideOverlay();

    final phone   = c['phone']   as String;
    final name    = c['name']    as String;
    final address = (c['address'] ?? '') as String;

    // 2 — guard before any cart mutation
    _suppressListenerFill = true;
    _lastKnownCartPhone   = phone;

    // 3 — fill fields immediately so the user sees the result at once
    _phoneCtrl.text   = phone;
    _nameCtrl.text    = name;
    _addressCtrl.text = address;

    // 4
    setState(() => _customerLoaded = true);

    // 5 — now safe to notify; listener will be suppressed
    cart.setCustomerFromMap(c);

    // 6 — release suppression after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _suppressListenerFill = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$name — ${c['total_orders'] ?? 0} previous '
                'order${(c['total_orders'] ?? 0) == 1 ? '' : 's'}',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  // ── Manual phone lookup (Search button / Enter key) ───────────────────────

  Future<void> _lookupPhone(CartProvider cart) async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    _hideOverlay();

    setState(() => _isLookingUp = true);
    final found = await cart.lookupCustomer(phone);

    _suppressListenerFill = true;
    _lastKnownCartPhone   = phone;

    if (found) {
      _nameCtrl.text    = cart.customerName;
      _addressCtrl.text = cart.customerAddress;
      setState(() {
        _customerLoaded = true;
        _isLookingUp    = false;
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
        _isLookingUp    = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _suppressListenerFill = false;
    });
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  void _clearForm(CartProvider cart) {
    _phoneCtrl.clear();
    _nameCtrl.clear();
    _addressCtrl.clear();
    _lastKnownCartPhone   = '';
    _suppressListenerFill = false;
    _hideOverlay();
    setState(() => _customerLoaded = false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {

        // ── Cart was cleared externally (e.g. after Print Bill) ──
        if (cart.customerPhone.isEmpty && _lastKnownCartPhone.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _clearForm(cart);
          });
        }

        // ── Customer loaded from the Customers screen (not from dropdown) ──
        // Only act when we haven't already handled this phone ourselves.
        if (!_suppressListenerFill &&
            cart.customerFound &&
            cart.customerPhone.isNotEmpty &&
            cart.customerPhone != _lastKnownCartPhone) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _phoneCtrl.text     = cart.customerPhone;
              _nameCtrl.text      = cart.customerName;
              _addressCtrl.text   = cart.customerAddress;
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
              // ── Header ──
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16,
                      color: Color(AppConstants.primaryColorValue)),
                  const SizedBox(width: 6),
                  const Text('Customer Info',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  if (_customerLoaded) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 12, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Returning Customer',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // ── Input row ──
              Row(
                children: [
                  // Phone
                  CompositedTransformTarget(
                    link: _phoneLayerLink,
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

                  // Search button
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLookingUp ? null : () => _lookupPhone(cart),
                      icon: _isLookingUp
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search, size: 16),
                      label: const Text('Search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(AppConstants.primaryColorValue),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 44),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Name — autocomplete enabled
                  Expanded(
                    flex: 3,
                    child: CompositedTransformTarget(
                      link: _nameLayerLink,
                      child: TextField(
                        controller: _nameCtrl,
                        focusNode: _nameFocus,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                        ),
                        onChanged: (v) => _onNameChanged(v, cart),
                      ),
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
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
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

enum _ActiveField { none, phone, name }