import 'package:flutter/material.dart';
import '../../widgets/frosted_card.dart';

class RoutesTab extends StatelessWidget {
  const RoutesTab({super.key});

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
                  'Assign Driver to Route',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Route'),
                  items: const [
                    DropdownMenuItem(value: 'r1', child: Text('Colombo 1 - Morning')),
                    DropdownMenuItem(value: 'r2', child: Text('Colombo 1 - Afternoon')),
                    DropdownMenuItem(value: 'r3', child: Text('Colombo 2 - Morning')),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Driver'),
                  items: const [
                    DropdownMenuItem(value: 'd1', child: Text('Saman Kumara')),
                    DropdownMenuItem(value: 'd2', child: Text('Nuwan Perera')),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Assign'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildRouteCard(context, 'Colombo 1 - Morning', 'Saman Kumara'),
          _buildRouteCard(context, 'Colombo 1 - Afternoon', 'Nuwan Perera'),
        ],
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, String route, String driver) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.route),
        title: Text(route),
        subtitle: Text('Driver: $driver'),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () {},
        ),
      ),
    );
  }
}
