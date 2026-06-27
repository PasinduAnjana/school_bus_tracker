import 'package:flutter/material.dart';
import '../../widgets/squishy_button.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  String? _selectedRoute;
  bool _tripActive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {},
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
              initialValue: _selectedRoute,
              decoration: const InputDecoration(
                labelText: 'Select route',
              ),
              items: const [
                DropdownMenuItem(value: 'r1', child: Text('Colombo 1 - Morning')),
                DropdownMenuItem(value: 'r2', child: Text('Colombo 1 - Afternoon')),
              ],
              onChanged: _tripActive
                  ? null
                  : (v) => setState(() => _selectedRoute = v),
            ),
            const Spacer(flex: 2),
            SquishyButton(
              label: _tripActive ? 'STOP TRIP' : 'START TRIP',
              backgroundColor: _tripActive
                  ? const Color(0xFFFF5252)
                  : const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF1E1E1E),
              onTap: _selectedRoute == null && !_tripActive
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
