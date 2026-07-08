import '../models/order.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient apiClient;

  OrderService(this.apiClient);

  Future<Order> checkout() async {
    final response = await apiClient.post('/orders/checkout');
    return Order.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Order>> getOrders() async {
    final response = await apiClient.get('/orders') as List;
    final orders = response
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }
}
