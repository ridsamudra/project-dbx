// lib/components/navbar.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'responsive.dart'; // Import responsive

class Navbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const Navbar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  // ignore: library_private_types_in_public_api
  _NavbarState createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  late Timer _timer;
  late DateTime _currentTime;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
    setState(() {
      _localeInitialized = true;
      _currentTime = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    final dayFormat = DateFormat('EEEE', 'id_ID');
    final dateFormat = DateFormat('d MMMM y', 'id_ID');
    final timeFormat = DateFormat('HH:mm:ss');

    return '${dayFormat.format(dateTime)}, ${dateFormat.format(dateTime)} - ${timeFormat.format(dateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        widget.title,
        style: TextStyle(
          fontSize: Responsive.getFontSize(context), // Dynamic font size
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Center(
            child: _localeInitialized
                ? Text(
                    _formatDateTime(_currentTime),
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context,
                          mobile: 12,
                          tablet: 16,
                          desktop: 20), // Dynamic font size
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }
}
