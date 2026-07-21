import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/frosted_card.dart';
import '../../widgets/swipe_to_delete_tile.dart';

class DriversTab extends StatefulWidget {
  const DriversTab({super.key});

  @override
  State<DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<DriversTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  Future<void> _showAddDriverDialog() async {
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              autofocus: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Driver phone number',
                hintText: '077 123 4567',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Driver name',
                hintText: 'Nimal Perera',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok != true) {
      return;
    }

    final phone = phoneCtrl.text.trim();
    final name = nameCtrl.text.trim();

    if (phone.isEmpty) return;

    if (!mounted) return;
    await context.read<AdminProvider>().addUser(phone, 'Driver', name: name);
  }

  Future<void> _showEditDriverDialog(WhitelistedUser d) async {
    final nameCtrl = TextEditingController(text: d.name ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Driver'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Driver name',
            hintText: 'Nimal Perera',
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
    await context.read<AdminProvider>().updateUserName(d.id, name);
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
              'Drivers',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: admin.drivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_pin_outlined,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No drivers yet.',
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
                      itemCount: admin.drivers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final d = admin.drivers[i];
                        return SwipeToDeleteTile(
                          itemKey: d.id,
                          onConfirmDelete: () async {
                            return await admin.deleteUser(d.id);
                          },
                          child: FrostedCard(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: const Text(
                                  'D',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              title: Text(
                                d.name != null && d.name!.isNotEmpty
                                    ? d.name!
                                    : d.phoneNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: d.name != null && d.name!.isNotEmpty
                                  ? Text(d.phoneNumber)
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showEditDriverDialog(d),
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
          heroTag: 'drivers_fab',
          onPressed: _showAddDriverDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Driver'),
        ),
      ),
    );
  }
}
