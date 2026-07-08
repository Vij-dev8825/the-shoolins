class CartItem {
  final String productId;
  final String name;
  final double price;
  final String image;
  final int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.quantity,
  });

  double get lineTotal => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'].toString(),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String,
      quantity: json['quantity'] as int,
    );
  }
}
