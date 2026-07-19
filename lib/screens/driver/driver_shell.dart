import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/halt.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../profile_screen.dart';
import 'driver_home_page.dart';
import 'driver_map_page.dart';
import 'driver_stops_page.dart';
import '../../widgets/frosted_nav_bar.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _selectedIndex = 0;
  Halt? _focusHalt;

  void _onHaltTap(Halt halt) {
    setState(() {
      _focusHalt = halt;
      _selectedIndex = 1;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final driver = context.read<DriverProvider>();
      final auth = context.read<AuthProvider>();
      driver.initGps();
      await driver.loadRoutes(auth.currentUser!.id);
      await driver.resumeActiveTrip(auth.currentUser!.id);
      if (driver.resumed && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Trip restored')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Builder(
          builder: (ctx) {
            final authUser = ctx.watch<AuthProvider>().currentUser;
            final name = authUser?.name;
            final homeTitle = (name != null && name.isNotEmpty) 
                ? 'Hello, $name' 
                : 'Driver Dashboard';
            return Text([homeTitle, 'Live Map', 'Stops'][_selectedIndex]);
          }
        ),
        actions: [
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
          const DriverHomePage(),
          DriverMapPage(focusHalt: _focusHalt),
          DriverStopsPage(onHaltTap: _onHaltTap),
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
