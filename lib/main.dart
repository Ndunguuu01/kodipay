import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:kodipay/providers/auth_provider.dart';
import 'package:kodipay/providers/property_provider.dart';
import 'package:kodipay/providers/complaint_provider.dart';
import 'package:kodipay/providers/theme_provider.dart';
import 'package:kodipay/providers/bill_provider.dart';
import 'package:kodipay/providers/lease_provider.dart';
import 'package:kodipay/providers/message_provider.dart';
import 'package:kodipay/providers/tenant_provider.dart';

import 'package:kodipay/router.dart';
import 'package:kodipay/services/api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();

  final authProvider = AuthProvider();
  await authProvider.initialize();

  final router = createRouter(authProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
        ChangeNotifierProvider(create: (_) => LeaseProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => TenantProvider()),
      ],
      child: MyApp(router: router),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KodiPay',
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).theme,
      routerConfig: router,
    );
  }
}
