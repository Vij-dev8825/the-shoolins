class Product {
  final String id;
  final String name;
  final double price;
  final String image;
  final String? imageBase64;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.imageBase64,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? json['productId']).toString(),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String,
      imageBase64: json['imageBase64'] as String?,
      category: json['category'] as String,
    );
  }
}
