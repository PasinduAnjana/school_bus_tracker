import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/halt.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/frosted_card.dart';
import '../../widgets/squishy_button.dart';
import '../../widgets/swipe_to_delete_tile.dart';
import 'map_picker_screen.dart';
import 'route_path_screen.dart';

class RouteDetailScreen extends StatefulWidget {
  final String routeId;
  final String routeName;

  const RouteDetailScreen({
    super.key,
    required this.routeId,
    required this.routeName,
  });

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadBuses();
      admin.loadHalts(widget.routeId);
    });
  }

  Future<void> _addHalt() async {
    final nameCtrl = TextEditingController();
    TimeOfDay time = TimeOfDay.fromDateTime(DateTime.now());
    LatLng? location;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Halt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Halt name',
                    hintText: 'e.g. Temple Road Stop',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('Arrival time: ${time.format(context)}'),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: time,
                    );
                    if (picked != null) {
                      setDialogState(() => time = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(
                    location != null
                        ? '${location!.latitude.toStringAsFixed(4)}, ${location!.longitude.toStringAsFixed(4)}'
                        : 'Pick on map',
                  ),
                  trailing: const Icon(Icons.map),
                  onTap: () async {
                    final admin = context.read<AdminProvider>();
                    final result = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(
                          initialLocation: location,
                          existingHalts: admin.halts(widget.routeId),
                        ),
                      ),
                    );
                    if (result != null) {
                      setDialogState(() => location = result);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            SquishyButton(
              onTap: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              label: 'Save',
              width: null,
              height: 44,
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      if (!mounted) return;
      final timeStr =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      await context.read<AdminProvider>().addHalt(
        widget.routeId,
        nameCtrl.text.trim(),
        timeStr,
        latitude: location?.latitude,
        longitude: location?.longitude,
      );
    }
  }

  Future<void> _editHalt(Halt halt) async {
    final nameCtrl = TextEditingController(text: halt.name);
    final parts = halt.arrivalTime.split(':');
    TimeOfDay time = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    LatLng? location = (halt.latitude != null && halt.longitude != null)
        ? LatLng(halt.latitude!, halt.longitude!)
        : null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Halt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Halt name'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('Arrival time: ${time.format(context)}'),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: time,
                    );
                    if (picked != null) {
                      setDialogState(() => time = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(
                    location != null
                        ? '${location!.latitude.toStringAsFixed(4)}, ${location!.longitude.toStringAsFixed(4)}'
                        : 'Pick on map',
                  ),
                  trailing: const Icon(Icons.map),
                  onTap: () async {
                    final admin = context.read<AdminProvider>();
                    final result = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(
                          initialLocation: location,
                          existingHalts: admin.halts(widget.routeId),
                        ),
                      ),
                    );
                    if (result != null) {
                      setDialogState(() => location = result);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            SquishyButton(
              onTap: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              label: 'Save',
              width: null,
              height: 44,
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      if (!mounted) return;
      final timeStr =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      await context.read<AdminProvider>().updateHalt(
        halt.id,
        nameCtrl.text.trim(),
        timeStr,
        latitude: location?.latitude,
        longitude: location?.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final halts = admin.halts(widget.routeId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.routeName)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'route_detail_fab',
        onPressed: _addHalt,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SquishyButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoutePathScreen(
                    routeId: widget.routeId,
                    routeName: widget.routeName,
                  ),
                ),
              );
            },
            label: 'Preview & Edit Path on Map',
            height: 48,
            width: double.infinity,
          ),
          const SizedBox(height: 16),
          Text('Halts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (halts.isEmpty)
            const FrostedCard(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No halts yet. Tap + to add one.')),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: halts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final halt = halts[i];
                return SwipeToDeleteTile(
                  itemKey: halt.id,
                  onConfirmDelete: () async {
                    return await admin.deleteHalt(halt.id);
                  },
                  child: FrostedCard(
                    margin: EdgeInsets.zero, // Margin is handled by the Swipe container now
                    key: ValueKey('card_${halt.id}'),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.schedule,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      title: Text(halt.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Arrival: ${halt.arrivalTime}'),
                          if (halt.latitude != null && halt.longitude != null)
                            Text(
                              '${halt.latitude!.toStringAsFixed(4)}, ${halt.longitude!.toStringAsFixed(4)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      onTap: () => _editHalt(halt),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
