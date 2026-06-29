import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/frosted_card.dart';

class DriversTab extends StatefulWidget {
  const DriversTab({super.key});

  @override
  State<DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<DriversTab> {
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _addDriver() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    final ok = await context.read<AdminProvider>().addUser(phone, 'Driver');
    if (ok && mounted) {
      _phoneController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Driver',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addDriver,
                    child: const Text('Add to whitelist'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Drivers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (admin.drivers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No drivers yet.'),
              ),
            )
          else
            ...admin.drivers.map((d) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: const Text('D'),
                    ),
                    title: Text(d.phoneNumber),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => admin.deleteUser(d.id),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
