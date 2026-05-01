import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ ADD

import 'features/splash/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/menu/provider/menu_provider.dart';
import 'features/cart/provider/cart_provider.dart';
import 'features/orders/provider/order_provider.dart';
import 'features/address/provider/address_provider.dart';
import 'features/home/provider/home_provider.dart';
import 'features/cart/provider/coupon_provider.dart';
import 'core/globals.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ REQUIRED
  await Firebase.initializeApp();            // ✅ FIREBASE INIT
  await FcmService().initialize();           // ✅ FCM PUSH NOTIFICATIONS
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// MENU PROVIDER
        ChangeNotifierProvider(
          create: (_) => MenuProvider(),
        ),

        /// CART PROVIDER
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),

        /// ORDER PROVIDER
        ChangeNotifierProvider(
          create: (_) => OrderProvider(),
        ),

        /// ADDRESS PROVIDER
        ChangeNotifierProvider(
          create: (_) => AddressProvider()..fetchAddresses(),
        ),

        /// HOME PROVIDER
        ChangeNotifierProvider(
          create: (_) => HomeProvider()..loadHomeData(),
        ),

        /// COUPON PROVIDER
        ChangeNotifierProvider(
          create: (_) => CouponProvider()..fetchAvailableCoupons(),
        ),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'Govardhan Thal',

        theme: AppTheme.lightTheme,

        /// 🚀 START SCREEN
        home: const SplashScreen(),
      ),
    );
  }
}
