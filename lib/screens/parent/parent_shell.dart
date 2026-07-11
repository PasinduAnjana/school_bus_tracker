import 'package:flutter/material.dart';
import '../profile_screen.dart';
import '../../widgets/frosted_card.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  String? _selectedBus;

  @override
  Widget build(BuildContext context) {
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
      body: Stack(
        children: [
          // Map placeholder
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE8E8E8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'OpenStreetMap will render here',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a bus below to track',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Frosted glass card at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: FrostedCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBus,
                    decoration: const InputDecoration(
                      labelText: 'Select bus',
                      border: InputBorder.none,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'r1',
                        child: Text('Colombo 1 - Morning'),
                      ),
                      DropdownMenuItem(
                        value: 'r2',
                        child: Text('Colombo 1 - Afternoon'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedBus = v),
                  ),
                  if (_selectedBus != null) ...[
                    const Divider(),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bus is moving',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          'ETA: 12 min',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
