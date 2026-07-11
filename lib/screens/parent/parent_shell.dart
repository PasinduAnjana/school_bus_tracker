import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/monitor_provider.dart';
import '../../widgets/live_map_view.dart';
import '../profile_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  String? _selectedRouteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<MonitorProvider>().loadParentStudents(auth.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitorProvider>();
    final students = monitor.parentStudents;

    final routeAssignments = students
        .where((s) => s.routeId != null && s.routeName != null)
        .map((s) => (s.routeId!, s.routeName!))
        .toSet()
        .toList();

    if (_selectedRouteId == null && routeAssignments.length == 1) {
      _selectedRouteId = routeAssignments.first.$1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            ),
          ),
        ],
      ),
      body: students.isEmpty
          ? _EmptyState()
          : routeAssignments.isEmpty
              ? _NoBusAssigned(students: students)
              : Column(
                  children: [
                    if (routeAssignments.length > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedRouteId,
                          decoration: const InputDecoration(
                            labelText: 'Select bus to track',
                            isDense: true,
                          ),
                          items: routeAssignments
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r.$1,
                                  child: Text(r.$2),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedRouteId = v),
                        ),
                      ),
                    Expanded(
                      child: LiveMapView(routeId: _selectedRouteId),
                    ),
                  ],
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.child_care_outlined,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'No students linked to your account',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoBusAssigned extends StatelessWidget {
  final List<dynamic> students;

  const _NoBusAssigned({required this.students});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            students.length == 1
                ? 'Your child has not been assigned a bus yet'
                : 'Your children have not been assigned buses yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
