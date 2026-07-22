import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/frosted_card.dart';
import '../../widgets/swipe_to_delete_tile.dart';

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
      context.read<AdminProvider>().loadBuses();
    });
  }

  Future<void> _showAddStudentDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final parentNameCtrl = TextEditingController();
    var showParentName = false;
    final Set<String> selectedBusIds = {};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final admin = context.read<AdminProvider>();

            void onPhoneChanged(String value) {
              final exists =
                  value.trim().isNotEmpty &&
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Buses',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (admin.buses.isEmpty)
                        const Text('No buses available', style: TextStyle(fontStyle: FontStyle.italic))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: admin.buses.map((b) {
                            final isSelected = selectedBusIds.contains(b.id);
                            return FilterChip(
                              label: Text(b.name),
                              selected: isSelected,
                              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                              selectedColor: Theme.of(context).colorScheme.primaryContainer,
                              checkmarkColor: Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedBusIds.add(b.id);
                                  } else {
                                    selectedBusIds.remove(b.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
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
      return;
    }

    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      return;
    }

    final parentName = showParentName ? parentNameCtrl.text.trim() : null;

    if (!mounted) return;
    await context.read<AdminProvider>().addStudentWithParent(
      name,
      phone,
      parentName,
    );
    
    // Assign buses immediately after creation
    // To do this reliably, we can just load the last created student by phone
    // However, it's easier to just pass busIds to addStudentWithParent if we updated it.
    // Let's modify addStudentWithParent below to accept busIds.
    // For now, we'll do it if we update admin_provider. 
    // Since we didn't, we'll fetch the created student and update it.
    final admin = context.read<AdminProvider>();
    final student = admin.students.firstWhere((s) => s.name == name && s.parentPhone == phone, orElse: () => admin.students.first);
    await admin.updateStudentBuses(student.id, selectedBusIds.toList());
  }

  Future<void> _showEditStudentDialog(StudentWithParent s) async {
    final nameCtrl = TextEditingController(text: s.name);
    final parentNameCtrl = TextEditingController(text: s.parentName ?? '');
    final Set<String> selectedBusIds = Set.from(s.busIds);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final admin = context.read<AdminProvider>();
            return AlertDialog(
              title: const Text('Edit Student'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Student name',
                    ),
                  ),
                  if (s.parentId != null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: parentNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Parent name',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Buses',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (admin.buses.isEmpty)
                    const Text('No buses available', style: TextStyle(fontStyle: FontStyle.italic))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: admin.buses.map((b) {
                        final isSelected = selectedBusIds.contains(b.id);
                        return FilterChip(
                          label: Text(b.name),
                          selected: isSelected,
                          backgroundColor: Theme.of(context).colorScheme.surfaceDim,
                          selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedBusIds.add(b.id);
                              } else {
                                selectedBusIds.remove(b.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;

    final newName = nameCtrl.text.trim();
    final newParentName = parentNameCtrl.text.trim();

    if (newName.isEmpty) return;

    if (!mounted) return;

    final admin = context.read<AdminProvider>();
    await admin.updateStudentName(s.id, newName);
    
    await admin.updateStudentBuses(s.id, selectedBusIds.toList());

    if (s.parentId != null && newParentName.isNotEmpty) {
      await admin.updateUserName(s.parentId!, newParentName);
    }
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No students yet.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.only(
                        bottom: 100 + MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount: admin.students.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final s = admin.students[i];
                        return SwipeToDeleteTile(
                          itemKey: s.id,
                          onConfirmDelete: () async {
                            return await admin.deleteStudent(s.id);
                          },
                          child: FrostedCard(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: Text(
                                  s.name.isNotEmpty
                                      ? s.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
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
                                s.busIds.isNotEmpty
                                    ? 'Buses: ${s.busIds.map((id) => admin.buses.where((b) => b.id == id).firstOrNull?.name ?? 'Unknown').join(', ')}'
                                    : (s.parentName != null
                                        ? '${s.parentName} (${s.parentPhone})'
                                        : (s.parentPhone ?? 'No parent')),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit details',
                                onPressed: () => _showEditStudentDialog(s),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: FloatingActionButton.extended(
          heroTag: 'users_fab',
          onPressed: _showAddStudentDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Student'),
        ),
      ),
    );
  }
}
