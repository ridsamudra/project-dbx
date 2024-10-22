// lib/components/navbar.dart

import 'package:flutter/material.dart';
import 'responsive.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const Navbar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.getFontSize(
            context,
            mobile: 12, // Custom responsive size untuk mobile
            tablet: 20, // Custom responsive size untuk tablet
            desktop: 20, // Custom responsive size untuk desktop
          ),
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0, // Prevents shadow when scrolled under
      surfaceTintColor: Colors.transparent, // Prevents color tint when scrolled
    );
  }
}
