import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'api_client.dart';

class WishlistService extends ChangeNotifier {
  final ApiClient apiClient;

  List<Product> _items = [];

  WishlistService(this.apiClient);

  List<Product> get items => _items;

  bool isWishlisted(String productId) =>
      _items.any((product) => product.id == productId);

  Future<void> fetchWishlist() async {
    final response = await apiClient.get('/wishlist') as List;
    _items = response
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> add(String productId) async {
    final response = await apiClient.post('/wishlist', {
      'productId': productId,
    }) as List;
    _items = response
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> remove(String productId) async {
    final response = await apiClient.delete('/wishlist/$productId') as List;
    _items = response
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> toggle(String productId) {
    return isWishlisted(productId) ? remove(productId) : add(productId);
  }

  void clear() {
    _items = [];
    notifyListeners();
  }
}
