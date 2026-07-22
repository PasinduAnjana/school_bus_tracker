import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../config/app_theme.dart';
import '../../widgets/frosted_card.dart';
import '../../widgets/swipe_to_delete_tile.dart';
import 'route_detail_screen.dart';

class BusDetailScreen extends StatefulWidget {
  final String busId;
  final String busName;

  const BusDetailScreen({
    super.key,
    required this.busId,
    required this.busName,
  });

  @override
  State<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends State<BusDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadRoutes();
    });
  }

  Future<void> _showCreateRouteDialog() async {
    final nameCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Route'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Route name',
            hintText: 'e.g. Colombo 1 - Morning',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    if (!mounted) return;
    await context.read<AdminProvider>().createRoute(name, busId: widget.busId);
  }

  Future<void> _showEditRouteDialog(RouteWithDriver r) async {
    final nameCtrl = TextEditingController(text: r.name);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Route Name'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Route name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    if (!mounted) return;
    await context.read<AdminProvider>().updateRouteName(r.id, name);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final bus = admin.buses.firstWhere((b) => b.id == widget.busId);
    final busRoutes = admin.routes.where((r) => r.busId == widget.busId).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.busName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign Driver',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('bus_driver_${bus.id}'),
                  value: bus.driverId,
                  decoration: const InputDecoration(labelText: 'Driver'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...admin.drivers.map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.phoneNumber),
                      ),
                    )
                  ],
                  onChanged: (v) {
                    admin.assignDriverToBus(bus.id, v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Routes', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          if (busRoutes.isEmpty)
            const FrostedCard(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No routes for this bus yet.',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: busRoutes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = busRoutes[i];
                return SwipeToDeleteTile(
                  itemKey: r.id,
                  onConfirmDelete: () async {
                    return await admin.deleteRoute(r.id);
                  },
                  child: FrostedCard(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.route, size: 20),
                      ),
                      title: Text(
                        r.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showEditRouteDialog(r),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteDetailScreen(
                            routeId: r.id,
                            routeName: r.name,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 80), // padding for FAB
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'bus_detail_fab',
        onPressed: _showCreateRouteDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Route'),
      ),
    );
  }
}
