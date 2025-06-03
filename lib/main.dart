import 'package:flutter/material.dart';
import 'package:kodipay/providers/bill_provider.dart';
import 'package:kodipay/providers/complaint_provider.dart';
import 'package:kodipay/providers/tenant_provider.dart' as tenant;
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lease_provider.dart';
import 'providers/payment_provider.dart';
import 'package:kodipay/services/api.dart';
import 'package:kodipay/providers/message_provider.dart';
import 'package:kodipay/providers/property_provider.dart' as prop;
import 'providers/theme_provider.dart';

import 'router.dart' as app_router;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await ApiService.initialize(); 

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => LeaseProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => prop.PropertyProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
        ChangeNotifierProvider(create: (_) => tenant.TenantProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Builder(
        builder: (context) {
          final auth = Provider.of<AuthProvider>(context);
          final billProvider = Provider.of<BillProvider>(context, listen: false);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (auth.auth != null) {
              billProvider.setUserId(auth.auth!.id);
            }
          });

          return const MyApp();
        },
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'KodiPay',
      theme: themeProvider.theme,
      routerConfig: app_router.router,
    );
  }
}
