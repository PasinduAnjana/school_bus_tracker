import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/frosted_card.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final _phoneController = TextEditingController();
  final _studentNameController = TextEditingController();
  String? _selectedRole;
  String? _selectedParentId;

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
    _phoneController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || _selectedRole == null) return;
    final ok = await context.read<AdminProvider>().addUser(phone, _selectedRole!);
    if (ok && mounted) {
      _phoneController.clear();
      setState(() => _selectedRole = null);
    }
  }

  Future<void> _addStudent() async {
    final name = _studentNameController.text.trim();
    if (name.isEmpty || _selectedParentId == null) return;
    await context.read<AdminProvider>().addStudent(name, _selectedParentId!);
    if (mounted) {
      _studentNameController.clear();
      setState(() => _selectedParentId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // ── Add User ──
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add User', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '077 123 4567',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Driver', child: Text('Driver')),
                    DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                  ],
                  onChanged: (v) => setState(() => _selectedRole = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addUser,
                    child: const Text('Add to whitelist'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Whitelisted Users ──
          Text('Whitelisted Users',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (admin.users.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No users yet.'),
              ),
            )
          else
            ...admin.users.map((u) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(u.role[0]),
                    ),
                    title: Text(u.phoneNumber),
                    subtitle: Text(u.role),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => admin.deleteUser(u.id),
                    ),
                  ),
                )),

          const SizedBox(height: 24),

          // ── Add Student ──
          FrostedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Student',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _studentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Student name',
                    hintText: 'Amaya Perera',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedParentId,
                  decoration: const InputDecoration(labelText: 'Parent'),
                  items: admin.parents
                      .map((p) => DropdownMenuItem(
                          value: p.id, child: Text(p.phoneNumber)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedParentId = v),
                ),
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
            ...admin.students.map((s) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.school),
                    title: Text(s.name),
                    subtitle: Text(s.parentPhone ?? 'No parent'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => admin.deleteStudent(s.id),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
