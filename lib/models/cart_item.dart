class CartItem {
  final String productId;
  final String name;
  final double price;
  final String image;
  final String? imageBase64;
  final int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    this.imageBase64,
    required this.quantity,
  });

  double get lineTotal => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'].toString(),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String,
      imageBase64: json['imageBase64'] as String?,
      quantity: json['quantity'] as int,
    );
  }
}
