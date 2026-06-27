import 'package:flutter/material.dart';
import '../../widgets/frosted_card.dart';

class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add User',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '077 123 4567',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Driver', child: Text('Driver')),
                    DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Add to whitelist'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Whitelisted Users',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildUserCard(context, '077 123 4567', 'Admin'),
          _buildUserCard(context, '077 987 6543', 'Driver'),
          _buildUserCard(context, '077 555 1212', 'Parent'),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, String phone, String role) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(role[0]),
        ),
        title: Text(phone),
        subtitle: Text(role),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {},
        ),
      ),
    );
  }
}
