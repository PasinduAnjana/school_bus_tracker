import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/frosted_card.dart';
import '../../widgets/swipe_to_delete_tile.dart';
import '../../config/app_theme.dart';
import 'bus_detail_screen.dart';

class BusesTab extends StatefulWidget {
  const BusesTab({super.key});

  @override
  State<BusesTab> createState() => _BusesTabState();
}

class _BusesTabState extends State<BusesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadBuses();
      context.read<AdminProvider>().loadUsers();
    });
  }

  Future<void> _showCreateBusDialog() async {
    final nameCtrl = TextEditingController(text: 'Bus ${context.read<AdminProvider>().buses.length + 1}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Bus'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Bus name'),
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
    await context.read<AdminProvider>().createBus(name);
  }

  Future<void> _showEditBusDialog(String busId, String currentName) async {
    final nameCtrl = TextEditingController(text: currentName);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Bus Name'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Bus name'),
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
    await context.read<AdminProvider>().updateBusName(busId, name);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buses',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: admin.buses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_bus_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No buses yet.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.only(
                        bottom: 100 + MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount: admin.buses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final b = admin.buses[i];
                        final driver = admin.drivers.where((d) => d.id == b.driverId).firstOrNull;
                        final driverText = driver != null 
                            ? '${driver.name ?? 'No name'} (${driver.phoneNumber})' 
                            : 'No driver assigned';
                            
                        return SwipeToDeleteTile(
                          itemKey: b.id,
                          onConfirmDelete: () async {
                            return await admin.deleteBus(b.id);
                          },
                          child: FrostedCard(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: const Icon(Icons.directions_bus, size: 20),
                              ),
                              title: Text(
                                b.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(driverText),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _showEditBusDialog(b.id, b.name),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BusDetailScreen(
                                      busId: b.id,
                                      busName: b.name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: FloatingActionButton.extended(
          heroTag: 'buses_fab',
          onPressed: _showCreateBusDialog,
          icon: const Icon(Icons.add),
          label: const Text('Create Bus'),
        ),
      ),
    );
  }
}
