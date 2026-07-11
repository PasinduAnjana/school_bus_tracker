import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
      context.read<AdminProvider>().loadStudents();
    });
  }

  Future<void> _showAddStudentDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final parentNameCtrl = TextEditingController();
    var showParentName = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void onPhoneChanged(String value) {
              final admin = context.read<AdminProvider>();
              final exists = value.trim().isNotEmpty &&
                  admin.findUserByPhone(value.trim()) != null;
              final show = value.trim().isNotEmpty && !exists;
              if (show != showParentName) {
                setDialogState(() => showParentName = show);
              }
            }

            return AlertDialog(
              title: const Text('Add Student'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Student name',
                          hintText: 'Amaya Perera',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: onPhoneChanged,
                        decoration: const InputDecoration(
                          labelText: 'Parent phone number',
                          hintText: '077 123 4567',
                        ),
                      ),
                      if (showParentName) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: parentNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Parent name',
                            hintText: 'Nimal Perera',
                          ),
                        ),
                      ] else if (phoneCtrl.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Parent already registered',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      parentNameCtrl.dispose();
      return;
    }

    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    nameCtrl.dispose();
    phoneCtrl.dispose();

    if (name.isEmpty || phone.isEmpty) {
      parentNameCtrl.dispose();
      return;
    }

    final parentName =
        showParentName ? parentNameCtrl.text.trim() : null;
    parentNameCtrl.dispose();

    if (!mounted) return;
    await context
        .read<AdminProvider>()
        .addStudentWithParent(name, phone, parentName);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Students',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: admin.students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No students yet.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: admin.students.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final s = admin.students[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text(
                                s.name.isNotEmpty
                                    ? s.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                            title: Text(
                              s.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              s.parentPhone ?? 'No parent',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () => admin.deleteStudent(s.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
    );
  }
}
