import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mini_money_flutter/screens/login_screen.dart';
import 'package:mini_money_flutter/screens/home_screen.dart';
import 'package:mini_money_flutter/screens/assets_screen.dart';
import 'package:mini_money_flutter/screens/details_screen.dart';
import 'package:mini_money_flutter/screens/statistics_screen.dart';
import 'package:mini_money_flutter/screens/settings_screen.dart';
import 'package:mini_money_flutter/screens/edit_transaction_screen.dart';
import 'package:mini_money_flutter/screens/main_layout.dart';
import 'package:mini_money_flutter/providers/auth_provider.dart';
import 'package:mini_money_flutter/providers/home_provider.dart';
import 'package:mini_money_flutter/providers/transaction_provider.dart';
import 'package:mini_money_flutter/providers/asset_provider.dart';
import 'package:mini_money_flutter/providers/statistics_provider.dart';
import 'package:mini_money_flutter/providers/user_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider(create: (context) => TransactionProvider()),
        ChangeNotifierProvider(create: (context) => AssetProvider()),
        ChangeNotifierProvider(create: (context) => StatisticsProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final router = GoRouter(
      refreshListenable: authProvider,
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return MainLayout(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/details',
              builder: (context, state) => const DetailsScreen(),
            ),
            GoRoute(
              path: '/assets',
              builder: (context, state) => const AssetsScreen(),
            ),
            GoRoute(
              path: '/statistics',
              builder: (context, state) => const StatisticsScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/add-transaction',
          builder: (context, state) => const EditTransactionScreen(),
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }

        if (isAuthenticated && isLoggingIn) {
          return '/';
        }

        return null;
      },
    );

    return MaterialApp.router(
      title: 'Mini Money',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
