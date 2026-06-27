import 'package:flutter/material.dart';
import '../../widgets/frosted_card.dart';

class PaymentsTab extends StatelessWidget {
  const PaymentsTab({super.key});

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
                  'Filter by month',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: '06-2026',
                  decoration: const InputDecoration(labelText: 'Month'),
                  items: const [
                    DropdownMenuItem(value: '05-2026', child: Text('May 2026')),
                    DropdownMenuItem(value: '06-2026', child: Text('June 2026')),
                    DropdownMenuItem(value: '07-2026', child: Text('July 2026')),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildStudentRow(context, 'Amaya Perera', true),
          _buildStudentRow(context, 'Dilan Silva', false),
          _buildStudentRow(context, 'Nethmi Fernando', true),
        ],
      ),
    );
  }

  Widget _buildStudentRow(BuildContext context, String name, bool paid) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: paid
              ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
              : const Color(0xFFFF5252).withValues(alpha: 0.15),
          child: Icon(
            paid ? Icons.check : Icons.close,
            color: paid ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
          ),
        ),
        title: Text(name),
        trailing: Switch.adaptive(
          value: paid,
          activeTrackColor: const Color(0xFF4CAF50),
          onChanged: (_) {},
        ),
      ),
    );
  }
}
