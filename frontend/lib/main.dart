// lib/main.dart

import 'package:flutter/material.dart';
import 'package:frontend/pages/auth/login_page.dart';
import 'package:frontend/pages/dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Best Parking Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
