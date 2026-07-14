import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../config/app_theme.dart';
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
    _selectedMonth = _months[2];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadPayments(_selectedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final payments = admin.payments;
    final paidCount = payments.where((p) => p.paid).length;
    final unpaidCount = payments.length - paidCount;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Payments',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedMonth,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _months
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedMonth = v);
                    context.read<AdminProvider>().loadPayments(v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!admin.isLoading && payments.isNotEmpty)
            _SummaryRow(
              total: payments.length,
              paid: paidCount,
              unpaid: unpaidCount,
            ),
          const SizedBox(height: 12),
          Expanded(
            child: admin.isLoading
                ? const Center(child: CircularProgressIndicator())
                : payments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No payments found for this month.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final p = payments[i];
                      return _PaymentCard(
                        name: p.studentName,
                        paid: p.paid,
                        onToggle: (_) => admin.togglePayment(p.id, p.paid),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Color _paidColor = AppColors.primary;
Color _unpaidColor = AppColors.onSurfaceVariant;

class _SummaryRow extends StatelessWidget {
  final int total;
  final int paid;
  final int unpaid;

  const _SummaryRow({
    required this.total,
    required this.paid,
    required this.unpaid,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Total',
                value: '$total',
                color: AppColors.onSurface,
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: AppColors.outline.withValues(alpha: 0.3),
            ),
            Expanded(
              child: _StatTile(
                label: 'Paid',
                value: '$paid',
                color: _paidColor,
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: AppColors.outline.withValues(alpha: 0.3),
            ),
            Expanded(
              child: _StatTile(
                label: 'Unpaid',
                value: '$unpaid',
                color: _unpaidColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatefulWidget {
  final String name;
  final bool paid;
  final ValueChanged<bool> onToggle;

  const _PaymentCard({
    required this.name,
    required this.paid,
    required this.onToggle,
  });

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bgAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    if (widget.paid) _animCtrl.value = 1;
  }

  @override
  void didUpdateWidget(_PaymentCard old) {
    super.didUpdateWidget(old);
    if (widget.paid != old.paid) {
      if (widget.paid) {
        _animCtrl.forward();
      } else {
        _animCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, _) {
        final t = _bgAnim.value;
        return FrostedCard(
          child: InkWell(
            onTap: () => widget.onToggle(!widget.paid),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Color.lerp(_unpaidColor, _paidColor, t)!,
                    width: 3,
                  ),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      _unpaidColor.withValues(alpha: 0.12),
                      _paidColor.withValues(alpha: 0.15),
                      t,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.paid ? Icons.check : Icons.close,
                    color: Color.lerp(_unpaidColor, _paidColor, t),
                    size: 20,
                  ),
                ),
                title: Text(
                  widget.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Switch.adaptive(
                  value: widget.paid,
                  activeTrackColor: _paidColor,
                  activeThumbColor: Colors.white,
                  onChanged: widget.onToggle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
