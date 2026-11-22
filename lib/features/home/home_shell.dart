import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

/// Kerangka empat tab pemain: Beranda, Cari PB, Perlengkapan, Akun.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_outlined, 'Beranda'),
    (Icons.search, 'Cari PB'),
    (Icons.shopping_bag_outlined, 'Perlengkapan'),
    (Icons.person_outline, 'Akun'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: YbColors.surface,
          border: Border(top: BorderSide(color: YbColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Row(
              children: [
                for (final (i, tab) in _tabs.indexed)
                  Expanded(
                    child: _TabItem(
                      icon: tab.$1,
                      label: tab.$2,
                      selected: shell.currentIndex == i,
                      onTap: () => shell.goBranch(
                        i,
                        initialLocation: i == shell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? YbColors.primary : YbColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 3,
              decoration: BoxDecoration(
                color: selected ? YbColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: YbText.body(
                size: 11,
                color: color,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
