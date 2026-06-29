import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/halt.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_client.dart';
import '../../widgets/squishy_button.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  List<Map<String, dynamic>> _routes = [];
  List<Halt> _halts = [];
  String? _selectedRouteId;
  bool _tripActive = false;
  final Set<String> _completedHalts = {};

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final data = await SupabaseService.client
          .from('routes')
          .select('id, name')
          .order('name');
      setState(() => _routes = (data as List).cast<Map<String, dynamic>>());
    } catch (e) {
      debugPrint('Driver loadRoutes error: $e');
    }
  }

  Future<void> _loadHalts(String routeId) async {
    try {
      final data = await SupabaseService.client
          .from('halts')
          .select('*')
          .eq('route_id', routeId)
          .order('stop_order');
      setState(() {
        _halts = (data as List).map((e) => Halt.fromMap(e)).toList();
        _completedHalts.clear();
      });
    } catch (e) {
      debugPrint('Driver loadHalts error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text(
              _tripActive ? 'Trip in progress' : 'Ready',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            DropdownButtonFormField<String>(
              initialValue: _selectedRouteId,
              decoration: const InputDecoration(labelText: 'Select route'),
              items: _routes
                  .map((r) => DropdownMenuItem(
                      value: r['id'] as String,
                      child: Text(r['name'] as String)))
                  .toList(),
              onChanged: _tripActive
                  ? null
                  : (v) {
                      setState(() => _selectedRouteId = v);
                      if (v != null) _loadHalts(v);
                    },
            ),
            if (_selectedRouteId != null && _halts.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Halts', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: _halts.map((halt) {
                    final done = _completedHalts.contains(halt.id);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: done
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFD700).withValues(alpha: 0.3),
                          child: Text('${halt.stopOrder + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: done ? Colors.white : null,
                              )),
                        ),
                        title: Text(halt.name),
                        subtitle: Text('Arrival: ${halt.arrivalTime}'),
                        trailing: done
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFF4CAF50))
                            : IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                onPressed: () => setState(
                                    () => _completedHalts.add(halt.id)),
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const Spacer(flex: 2),
            SquishyButton(
              label: _tripActive ? 'STOP TRIP' : 'START TRIP',
              backgroundColor: _tripActive
                  ? const Color(0xFFFF5252)
                  : const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF1E1E1E),
              onTap: _selectedRouteId == null && !_tripActive
                  ? null
                  : () => setState(() => _tripActive = !_tripActive),
            ),
            const SizedBox(height: 16),
            if (_tripActive)
              Text(
                'GPS active — pinging every 20s',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4CAF50),
                    ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
