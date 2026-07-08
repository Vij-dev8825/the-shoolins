import 'cart_item.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
