import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'route_detail_screen.dart';
import '../../config/app_theme.dart';
import '../../widgets/frosted_card.dart';
import '../../widgets/swipe_to_delete_tile.dart';

class RoutesTab extends StatefulWidget {
  const RoutesTab({super.key});

  @override
  State<RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends State<RoutesTab> {
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

    if (ok != true) {
      return;
    }

    final name = nameCtrl.text.trim();

    if (name.isEmpty) return;

    if (!mounted) return;
    await context.read<AdminProvider>().createRoute(name);
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

    if (ok != true) {
      return;
    }

    final name = nameCtrl.text.trim();

    if (name.isEmpty) return;

    if (!mounted) return;
    await context.read<AdminProvider>().updateRouteName(r.id, name);
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
              'Routes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: admin.routes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.route_outlined,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No routes yet.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.only(
                        bottom: 100 + MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount: admin.routes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = admin.routes[i];
                        return SwipeToDeleteTile(
                          itemKey: r.id,
                          onConfirmDelete: () async {
                            return await admin.deleteRoute(r.id);
                          },
                          child: FrostedCard(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: const Icon(Icons.route, size: 20),
                              ),
                              title: Text(
                                r.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                r.driverPhone ?? 'No driver assigned',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
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
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: FloatingActionButton.extended(
          heroTag: 'routes_fab',
          onPressed: _showCreateRouteDialog,
          icon: const Icon(Icons.add),
          label: const Text('Create Route'),
        ),
      ),
    );
  }
}
