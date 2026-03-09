// lib/screens/riders_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/rider.dart';
import '../utils/constants.dart';

class RidersScreen extends StatefulWidget {
  const RidersScreen({super.key});

  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  List<Map<String, dynamic>> _riders = [];
  List<RiderTrip> _activeTrips = [];
  List<RiderTrip> _history = [];

  // Auto-refresh timer so elapsed times update every 30s
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {}); // triggers duration text refresh
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final riders = await DBHelper.instance.getAllRiders();
    final activeRaw = await DBHelper.instance.getActiveTrips();
    final historyRaw = await DBHelper.instance.getTripHistory(limit: 150);

    if (!mounted) return;
    setState(() {
      _riders = riders;
      _activeTrips = activeRaw.map((m) => RiderTrip.fromMap(m)).toList();
      _history = historyRaw.map((m) => RiderTrip.fromMap(m)).toList();
    });
  }

  // ─── Dispatch dialog ──────────────────────────────────────────────────────

  Future<void> _showDispatchDialog() async {
    final activeRiders = _riders.where((r) => r['is_active'] == 1).toList();
    if (activeRiders.isEmpty) {
      _showInfo('No active riders. Please add a rider first.');
      return;
    }

    int? selectedRiderId;
    String? selectedRiderName;
    final orderCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColorValue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delivery_dining,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Dispatch Rider'),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rider picker
                DropdownButtonFormField<int>(
                  value: selectedRiderId,
                  decoration: const InputDecoration(
                    labelText: 'Select Rider *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: activeRiders
                      .map((r) => DropdownMenuItem<int>(
                            value: r['id'] as int,
                            child: Row(
                              children: [
                                Text(r['name'] as String,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                if ((r['phone'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text('· ${r['phone']}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500)),
                                ],
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setS(() {
                      selectedRiderId = val;
                      selectedRiderName = activeRiders
                          .firstWhere((r) => r['id'] == val)['name'] as String;
                    });
                  },
                ),
                const SizedBox(height: 14),

                // Order IDs
                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Order Numbers *',
                    hintText: 'e.g. 45, 46, 47',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.receipt_long),
                    helperText: 'Separate multiple orders with commas',
                    helperStyle:
                        TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Any special instructions...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),

                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Departure time will be recorded as: '
                        '${DateFormat('hh:mm a').format(DateTime.now())}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Dispatch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColorValue),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (selectedRiderId == null) {
                  _showInfo('Please select a rider.');
                  return;
                }
                final rawIds = orderCtrl.text.trim();
                if (rawIds.isEmpty) {
                  _showInfo('Please enter at least one order number.');
                  return;
                }
                await DBHelper.instance.startRiderTrip(
                  riderId: selectedRiderId!,
                  riderName: selectedRiderName!,
                  orderIds: rawIds,
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                await _load();
                _tabCtrl.animateTo(1); // jump to Active tab
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Row(children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                          '$selectedRiderName dispatched with orders: $rawIds'),
                    ]),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Mark returned ───────────────────────────────────────────────────────

  Future<void> _markReturned(RiderTrip trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Returned?'),
        content: Text(
          '${trip.riderName} will be marked as returned.\n'
          'Trip duration: ${trip.durationStr}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm Return',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DBHelper.instance.markRiderReturned(trip.id!);
      await _load();
    }
  }

  // ─── Add / Edit rider dialog ──────────────────────────────────────────────

  Future<void> _showRiderDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final isEdit = existing != null;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Rider' : 'Add New Rider'),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Rider Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryColorValue),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                _showInfo('Please enter a name.');
                return;
              }
              if (isEdit) {
                await DBHelper.instance
                    .updateRider(existing['id'], name, phoneCtrl.text.trim());
              } else {
                await DBHelper.instance.addRider(name, phoneCtrl.text.trim());
              }
              Navigator.pop(ctx);
              await _load();
            },
            child: Text(isEdit ? 'Save' : 'Add Rider'),
          ),
        ],
      ),
    );
  }

  // ─── Delete rider ─────────────────────────────────────────────────────────

  Future<void> _deleteRider(Map<String, dynamic> rider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rider?'),
        content: Text('Remove "${rider['name']}" from the system?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DBHelper.instance.deleteRider(rider['id']);
      await _load();
    }
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activeCount = _activeTrips.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.delivery_dining, size: 22),
            SizedBox(width: 8),
            Text('Rider Dispatch'),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Refresh', style: TextStyle(color: Colors.white)),
            onPressed: _load,
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Dispatch Rider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(AppConstants.primaryColorValue),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: _showDispatchDialog,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            const Tab(text: 'Riders'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active'),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$activeCount',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _RidersTab(
            riders: _riders,
            onAdd: () => _showRiderDialog(),
            onEdit: (r) => _showRiderDialog(existing: r),
            onDelete: _deleteRider,
            onToggle: (r, val) async {
              await DBHelper.instance.toggleRiderActive(r['id'], val);
              await _load();
            },
          ),
          _ActiveTripsTab(
            trips: _activeTrips,
            onReturn: _markReturned,
            onDelete: (trip) async {
              await DBHelper.instance.deleteTrip(trip.id!);
              await _load();
            },
          ),
          _HistoryTab(trips: _history),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 1 — Riders list
// ═══════════════════════════════════════════════════════════════════════════════

class _RidersTab extends StatelessWidget {
  final List<Map<String, dynamic>> riders;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;
  final void Function(Map<String, dynamic>, bool) onToggle;

  const _RidersTab({
    required this.riders,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add button bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                  '${riders.length} rider${riders.length == 1 ? '' : 's'} registered',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Rider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppConstants.primaryColorValue),
                  foregroundColor: Colors.white,
                ),
                onPressed: onAdd,
              ),
            ],
          ),
        ),

        Expanded(
          child: riders.isEmpty
              ? _EmptyState(
                  icon: Icons.delivery_dining,
                  title: 'No riders yet',
                  subtitle: 'Tap "Add Rider" to get started',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: riders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final r = riders[i];
                    final isActive = r['is_active'] == 1;
                    final name = r['name'] as String;
                    final phone = (r['phone'] ?? '') as String;
                    final initials = name
                        .trim()
                        .split(' ')
                        .where((w) => w.isNotEmpty)
                        .map((w) => w[0].toUpperCase())
                        .take(2)
                        .join();

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: isActive
                                  ? const Color(AppConstants.primaryColorValue)
                                  : Colors.grey.shade300,
                              child: Text(initials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  if (phone.isNotEmpty)
                                    Row(children: [
                                      Icon(Icons.phone,
                                          size: 12,
                                          color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(phone,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500)),
                                    ]),
                                ],
                              ),
                            ),
                            // Active badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isActive
                                        ? Colors.green.shade200
                                        : Colors.grey.shade300),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? Colors.green.shade700
                                        : Colors.grey.shade500),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Toggle
                            Switch(
                              value: isActive,
                              activeColor: Colors.green,
                              onChanged: (val) => onToggle(r, val),
                            ),
                            // Edit
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: Colors.blue),
                              tooltip: 'Edit',
                              onPressed: () => onEdit(r),
                            ),
                            // Delete
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () => onDelete(r),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 2 — Active trips
// ═══════════════════════════════════════════════════════════════════════════════

class _ActiveTripsTab extends StatelessWidget {
  final List<RiderTrip> trips;
  final void Function(RiderTrip) onReturn;
  final void Function(RiderTrip) onDelete;

  const _ActiveTripsTab({
    required this.trips,
    required this.onReturn,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return _EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No active deliveries',
        subtitle:
            'All riders are back. Use "Dispatch Rider" to send someone out.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _ActiveTripCard(
        trip: trips[i],
        onReturn: () => onReturn(trips[i]),
        onDelete: () => onDelete(trips[i]),
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final RiderTrip trip;
  final VoidCallback onReturn;
  final VoidCallback onDelete;

  const _ActiveTripCard({
    required this.trip,
    required this.onReturn,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final departStr = DateFormat('hh:mm a').format(trip.departedAt);
    final orderCount = trip.orderIds.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.delivery_dining,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(trip.riderName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text('Out for ${trip.durationStr}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final oid in trip.orderIds)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.primaryColorValue)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(AppConstants.primaryColorValue)
                                  .withOpacity(0.25)),
                        ),
                        child: Text(
                          'Order #$oid',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(AppConstants.primaryColorValue)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Info row
                Row(
                  children: [
                    _infoChip(Icons.access_time, 'Departed', departStr,
                        Colors.orange.shade700),
                    const SizedBox(width: 10),
                    _infoChip(
                        Icons.receipt_long,
                        'Orders',
                        '$orderCount order${orderCount == 1 ? '' : 's'}',
                        Colors.blue.shade700),
                  ],
                ),

                // Notes
                if ((trip.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(trip.notes!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 15),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      onPressed: onDelete,
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Mark Returned'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                      onPressed: onReturn,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 3 — Trip history
// ═══════════════════════════════════════════════════════════════════════════════

class _HistoryTab extends StatelessWidget {
  final List<RiderTrip> trips;

  const _HistoryTab({required this.trips});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return _EmptyState(
        icon: Icons.history,
        title: 'No trip history yet',
        subtitle: 'Completed deliveries will appear here',
      );
    }

    // Group by date
    final Map<String, List<RiderTrip>> grouped = {};
    for (final t in trips) {
      final key = DateFormat('yyyy-MM-dd').format(t.departedAt);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: dates.length,
      itemBuilder: (ctx, di) {
        final date = dates[di];
        final dayTrips = grouped[date]!;
        final dateLabel =
            DateFormat('EEEE, dd MMM yyyy').format(DateTime.parse(date));
        final isToday = date == DateFormat('yyyy-MM-dd').format(DateTime.now());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(AppConstants.primaryColorValue)
                          : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isToday ? 'Today — $dateLabel' : dateLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                      '${dayTrips.length} trip${dayTrips.length == 1 ? '' : 's'}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            ...dayTrips.map((trip) => _HistoryCard(trip: trip)),
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final RiderTrip trip;

  const _HistoryCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final departStr = DateFormat('hh:mm a').format(trip.departedAt);
    final returnStr = trip.returnedAt != null
        ? DateFormat('hh:mm a').format(trip.returnedAt!)
        : '—';
    final isCompleted = !trip.isOut;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isCompleted ? Colors.grey.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green : Colors.orange,
              ),
            ),
            // Rider name + orders
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.riderName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    trip.orderIds.map((id) => '#$id').join(', '),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Departed
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Departed',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                  Text(departStr,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            // Returned
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Returned',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                  Text(returnStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isCompleted ? Colors.green.shade700 : Colors.orange,
                      )),
                ],
              ),
            ),
            // Duration
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Duration',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                  Text(trip.durationStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      )),
                ],
              ),
            ),
            // Status badge
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:
                    isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isCompleted
                        ? Colors.green.shade200
                        : Colors.orange.shade200),
              ),
              child: Text(
                isCompleted ? 'Done' : 'Out',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? Colors.green.shade700
                        : Colors.orange.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared empty-state widget
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
