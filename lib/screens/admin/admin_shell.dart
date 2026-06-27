import 'package:flutter/material.dart';
import 'users_tab.dart';
import 'payments_tab.dart';
import 'routes_tab.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _tabs = const [
    _TabItem(label: 'Users & Students', icon: Icons.people_outline),
    _TabItem(label: 'Payments', icon: Icons.account_balance_wallet_outlined),
    _TabItem(label: 'Routes & Drivers', icon: Icons.route_outlined),
  ];

  final _screens = const [
    UsersTab(),
    PaymentsTab(),
    RoutesTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_index].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {},
          ),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem({required this.label, required this.icon});
}
