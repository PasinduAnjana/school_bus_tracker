import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../profile_screen.dart';
import 'drivers_tab.dart';
import 'monitor_tab.dart';
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
    _TabItem(label: 'Students', icon: Icons.people_outline),
    _TabItem(label: 'Drivers', icon: Icons.person_pin_outlined),
    _TabItem(label: 'Payments', icon: Icons.account_balance_wallet_outlined),
    _TabItem(label: 'Routes', icon: Icons.route_outlined),
    _TabItem(label: 'Monitor', icon: Icons.map_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, _) => Scaffold(
        appBar: AppBar(
          title: Text(_tabs[_index].label),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: const [
            UsersTab(),
            DriversTab(),
            PaymentsTab(),
            RoutesTab(),
            MonitorTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _tabs
              .map(
                (t) =>
                    NavigationDestination(icon: Icon(t.icon), label: t.label),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem({required this.label, required this.icon});
}
