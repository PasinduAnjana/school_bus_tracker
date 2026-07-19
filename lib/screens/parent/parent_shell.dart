import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/halt.dart';
import '../../providers/auth_provider.dart';
import '../../providers/monitor_provider.dart';
import '../profile_screen.dart';
import 'parent_home_page.dart';
import 'parent_map_page.dart';
import 'parent_halts_page.dart';
import '../../widgets/frosted_nav_bar.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _selectedIndex = 0;
  String? _selectedRouteId;
  Halt? _focusHalt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final monitor = context.read<MonitorProvider>();
      if (auth.currentUser != null) {
        monitor.loadParentStudents(auth.currentUser!.id);
        monitor.subscribe(); // Start "all routes" subscription for realtime
      }
    });
  }

  Future<void> _onRouteSelected(String? routeId) async {
    setState(() => _selectedRouteId = routeId);
    if (routeId == null) return;
    final monitor = context.read<MonitorProvider>();
    await monitor.loadActiveTrips(); // Load all trips; UI filters by routeId
    final trip = monitor.activeTrips.where((t) => t.routeId == routeId).firstOrNull;
    await monitor.loadHalts(routeId, trip?.locationId);
  }

  void _onHaltTap(Halt halt) {
    setState(() {
      _focusHalt = halt;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitorProvider>();
    final students = monitor.parentStudents;

    final routeAssignments = students
        .where((s) => s.routeId != null && s.routeName != null)
        .map((s) => (s.routeId!, s.routeName!))
        .toSet()
        .toList();

    if (_selectedRouteId == null && routeAssignments.length == 1) {
      _selectedRouteId = routeAssignments.first.$1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onRouteSelected(_selectedRouteId);
      });
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Builder(
          builder: (ctx) {
            final authUser = ctx.watch<AuthProvider>().currentUser;
            final name = authUser?.name;
            final homeTitle = (name != null && name.isNotEmpty) 
                ? 'Hello, $name' 
                : 'Home';
            return Text([homeTitle, 'Live Map', 'Stops'][_selectedIndex]);
          }
        ),
        actions: [
          if (routeAssignments.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButton<String>(
                value: _selectedRouteId,
                underline: const SizedBox.shrink(),
                icon: Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                items: routeAssignments
                    .map(
                      (r) => DropdownMenuItem(
                        value: r.$1,
                        child: Text(
                          r.$2,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _onRouteSelected,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ParentHomePage(routeId: _selectedRouteId),
          ParentMapPage(routeId: _selectedRouteId, focusHalt: _focusHalt),
          ParentHaltsPage(routeId: _selectedRouteId, onHaltTap: _onHaltTap),
        ],
      ),
      bottomNavigationBar: FrostedNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        icons: const [Icons.home_rounded, Icons.map_rounded, Icons.location_on_rounded],
        labels: const ['Home', 'Map', 'Stops'],
      ),
    );
  }
}
