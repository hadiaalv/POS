// lib/models/rider.dart

class Rider {
  final int? id;
  final String name;
  final String phone;
  final bool isActive;

  Rider({this.id, required this.name, required this.phone, this.isActive = true});

  factory Rider.fromMap(Map<String, dynamic> map) {
    return Rider(
      id: map['id'],
      name: map['name'],
      phone: map['phone'] ?? '',
      isActive: map['is_active'] == 1,
    );
  }
}

class RiderTrip {
  final int? id;
  final int riderId;
  final String riderName;
  final List<int> orderIds;
  final String orderIdsStr;
  final DateTime departedAt;
  final DateTime? returnedAt;
  final String? notes;

  RiderTrip({
    this.id,
    required this.riderId,
    required this.riderName,
    required this.orderIds,
    required this.orderIdsStr,
    required this.departedAt,
    this.returnedAt,
    this.notes,
  });

  bool get isOut => returnedAt == null;

  Duration get duration {
    final end = returnedAt ?? DateTime.now();
    return end.difference(departedAt);
  }

  String get durationStr {
    final d = duration;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  factory RiderTrip.fromMap(Map<String, dynamic> map) {
    final idsStr = map['order_ids'] as String? ?? '';
    final ids = idsStr.isEmpty
        ? <int>[]
        : idsStr.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((e) => e > 0).toList();
    return RiderTrip(
      id: map['id'],
      riderId: map['rider_id'],
      riderName: map['rider_name'] ?? '',
      orderIds: ids,
      orderIdsStr: idsStr,
      departedAt: DateTime.parse(map['departed_at']),
      returnedAt: map['returned_at'] != null ? DateTime.parse(map['returned_at']) : null,
      notes: map['notes'],
    );
  }
}