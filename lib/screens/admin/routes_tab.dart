import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/frosted_card.dart';

class RoutesTab extends StatefulWidget {
  const RoutesTab({super.key});

  @override
  State<RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends State<RoutesTab> {
  String? _selectedRouteId;
  String? _selectedDriverId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadRoutes();
    });
  }

  Future<void> _assign() async {
    if (_selectedRouteId == null) return;
    await context
        .read<AdminProvider>()
        .assignDriver(_selectedRouteId!, _selectedDriverId);
    if (mounted) {
      setState(() {
        _selectedRouteId = null;
        _selectedDriverId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assign Driver to Route',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('route_$_selectedRouteId'),
                  initialValue: _selectedRouteId,
                  decoration: const InputDecoration(labelText: 'Route'),
                  items: admin.routes
                      .map((r) => DropdownMenuItem(
                          value: r.id, child: Text(r.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRouteId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('driver_$_selectedDriverId'),
                  initialValue: _selectedDriverId,
                  decoration: const InputDecoration(labelText: 'Driver'),
                  items: admin.drivers
                      .map((d) => DropdownMenuItem(
                          value: d.id, child: Text(d.phoneNumber)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDriverId = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _assign,
                    child: const Text('Assign'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Routes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (admin.routes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No routes yet.'),
              ),
            )
          else
            ...admin.routes.map((r) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.route),
                    title: Text(r.name),
                    subtitle: Text(r.driverPhone ?? 'No driver assigned'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        setState(() {
                          _selectedRouteId = r.id;
                          _selectedDriverId = r.driverId;
                        });
                      },
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
