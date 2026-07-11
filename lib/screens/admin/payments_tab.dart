import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/frosted_card.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  final _months = <String>[];
  String _selectedMonth = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    for (int i = -2; i <= 2; i++) {
      final d = DateTime(now.year, now.month + i);
      final m = '${d.month.toString().padLeft(2, '0')}-${d.year}';
      _months.add(m);
    }
    _selectedMonth = _months[2]; // current month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadPayments(_selectedMonth);
    });
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
                Text(
                  'Filter by month',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedMonth,
                  decoration: const InputDecoration(labelText: 'Month'),
                  items: _months
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedMonth = v);
                    context.read<AdminProvider>().loadPayments(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (admin.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (admin.payments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No payments found for this month.'),
              ),
            )
          else
            ...admin.payments.map(
              (p) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.paid
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                        : const Color(0xFFFF5252).withValues(alpha: 0.15),
                    child: Icon(
                      p.paid ? Icons.check : Icons.close,
                      color: p.paid
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF5252),
                    ),
                  ),
                  title: Text(p.studentName),
                  trailing: Switch.adaptive(
                    value: p.paid,
                    activeTrackColor: const Color(0xFF4CAF50),
                    onChanged: (_) => admin.togglePayment(p.id, p.paid),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
