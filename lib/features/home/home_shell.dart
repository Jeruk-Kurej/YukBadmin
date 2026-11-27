import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/yb_widgets.dart';

/// Kerangka empat tab pemain: Beranda, Cari PB, Perlengkapan, Akun.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, 'Beranda'),
    (Icons.search, Icons.search, 'Cari PB'),
    (Icons.shopping_bag_outlined, Icons.shopping_bag, 'Perlengkapan'),
    (Icons.person_outline, Icons.person, 'Akun'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: YbTabBar(
        tabs: _tabs,
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
