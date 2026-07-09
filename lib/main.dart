import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/locale_service.dart';
import 'screens/language_gate.dart';
import 'theme/app_theme.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/notification_service.dart';
import 'services/order_service.dart';
import 'services/product_service.dart';
import 'services/wishlist_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const TheShoolinsApp());
}

class TheShoolinsApp extends StatelessWidget {
  const TheShoolinsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProvider<AuthService>(
          create: (context) {
            final apiClient = context.read<ApiClient>();
            final auth = AuthService(apiClient)..loadFromStorage();
            apiClient.onUnauthorized = () {
              auth.logout();
              final navigator = navigatorKey.currentState;
              if (navigator == null) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LanguageGate()),
                (route) => false,
              );
              final messengerContext = navigator.context;
              ScaffoldMessenger.of(messengerContext).showSnackBar(
                const SnackBar(content: Text('Your session has expired. Please log in again.')),
              );
            };
            return auth;
          },
        ),
        Provider<ProductService>(
          create: (context) => ProductService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<CartService>(
          create: (context) => CartService(context.read<ApiClient>()),
        ),
        Provider<OrderService>(
          create: (context) => OrderService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<WishlistService>(
          create: (context) => WishlistService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<LocaleService>(
          create: (context) => LocaleService()..loadFromStorage(),
        ),
        ChangeNotifierProvider<NotificationService>(
          create: (context) => NotificationService()..loadFromStorage(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'The Shoolins',
        theme: AppTheme.light,
        home: const LanguageGate(),
      ),
    );
  }
}
