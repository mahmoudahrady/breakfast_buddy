import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create a group')),
      );
      return;
    }

    final group = await groupProvider.createGroup(
      name: _nameController.text.trim(),
      description: '',
      admin: authProvider.user!,
      allowMembersToAddItems: false,
    );

    if (mounted) {
      if (group != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
        );
        Navigator.pop(context, group);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(groupProvider.errorMessage ?? 'Failed to create group'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Group name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  if (value.trim().length < 3) {
                    return 'Group name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Info card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'About Groups',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• You will be the admin of this group\n'
                        '• Add restaurants to the group\n'
                        '• Invite others to join\n'
                        '• Control who can add menu items\n'
                        '• Members can order from group restaurants',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Create button
              ElevatedButton(
                onPressed: groupProvider.isLoading ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: groupProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Create Group',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
