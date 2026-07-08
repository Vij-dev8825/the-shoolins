import '../models/product.dart';
import 'api_client.dart';

class ProductService {
  final ApiClient apiClient;

  ProductService(this.apiClient);

  Future<List<Product>> getProducts({
    String? category,
    String? query,
    String? sort,
  }) async {
    final params = {
      'category': ?category,
      'q': query != null && query.isNotEmpty ? query : null,
      'sort': ?sort,
    };
    final path = params.isEmpty
        ? '/products'
        : '/products?${Uri(queryParameters: params).query}';
    final response = await apiClient.get(path) as List;
    return response
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Product> getProduct(String id) async {
    final response = await apiClient.get('/products/$id');
    return Product.fromJson(response as Map<String, dynamic>);
  }
}
