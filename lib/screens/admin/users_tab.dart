import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/frosted_card.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final _studentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentNameController = TextEditingController();
  bool _showParentName = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
      context.read<AdminProvider>().loadStudents();
    });
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _parentPhoneController.dispose();
    _parentNameController.dispose();
    super.dispose();
  }

  void _onParentPhoneChanged(String value) {
    final admin = context.read<AdminProvider>();
    final exists =
        value.trim().isNotEmpty && admin.findUserByPhone(value.trim()) != null;
    final showName = value.trim().isNotEmpty && !exists;
    if (showName != _showParentName) {
      setState(() => _showParentName = showName);
    }
  }

  Future<void> _addStudent() async {
    final name = _studentNameController.text.trim();
    final phone = _parentPhoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) return;
    if (_showParentName && _parentNameController.text.trim().isEmpty) return;

    final admin = context.read<AdminProvider>();
    final ok = await admin.addStudentWithParent(
      name,
      phone,
      _showParentName ? _parentNameController.text.trim() : null,
    );

    if (ok && mounted) {
      _studentNameController.clear();
      _parentPhoneController.clear();
      _parentNameController.clear();
      setState(() => _showParentName = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // ── Add Student ──
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Student',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _studentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Student name',
                    hintText: 'Amaya Perera',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _parentPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: _onParentPhoneChanged,
                  decoration: const InputDecoration(
                    labelText: 'Parent phone number',
                    hintText: '077 123 4567',
                  ),
                ),
                if (_showParentName) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _parentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Parent name',
                      hintText: 'Nimal Perera',
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'Parent already registered',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addStudent,
                    child: const Text('Add student'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Students List ──
          Text('Students', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (admin.students.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No students yet.'),
              ),
            )
          else
            ...admin.students.map(
              (s) => Card(
                child: ListTile(
                  leading: const Icon(Icons.school),
                  title: Text(s.name),
                  subtitle: Text(s.parentPhone ?? 'No parent'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => admin.deleteStudent(s.id),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
