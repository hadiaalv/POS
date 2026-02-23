// lib/models/customer.dart
class Customer {
  final int? id;
  final String phone;
  final String name;
  final String address;

  Customer({this.id, required this.phone, required this.name, required this.address});

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      phone: map['phone'],
      name: map['name'],
      address: map['address'] ?? '',
    );
  }
}