import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import 'api_client.dart';

class CartService extends ChangeNotifier {
  final ApiClient apiClient;

  List<CartItem> _items = [];

  CartService(this.apiClient);

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get total => _items.fold(0, (sum, item) => sum + item.lineTotal);

  Future<void> fetchCart() async {
    final response = await apiClient.get('/cart') as List;
    _items = response
        .map((json) => CartItem.fromJson(json as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    final response = await apiClient.post('/cart', {
      'productId': productId,
      'quantity': quantity,
    }) as List;
    _items = response
        .map((json) => CartItem.fromJson(json as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    final response = await apiClient.patch('/cart/$productId', {
      'quantity': quantity,
    }) as List;
    _items = response
        .map((json) => CartItem.fromJson(json as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> removeFromCart(String productId) async {
    final response = await apiClient.delete('/cart/$productId') as List;
    _items = response
        .map((json) => CartItem.fromJson(json as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  void clear() {
    _items = [];
    notifyListeners();
  }
}
