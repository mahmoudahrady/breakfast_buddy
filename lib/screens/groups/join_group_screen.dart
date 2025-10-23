import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupIdController = TextEditingController();

  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to join a group')),
      );
      return;
    }

    final success = await groupProvider.joinGroup(
      groupId: _groupIdController.text.trim(),
      user: authProvider.user!,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined group successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(groupProvider.errorMessage ?? 'Failed to join group'),
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
        title: const Text('Join Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                            'How to Join',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ask the group admin to share the Group ID with you. '
                        'Enter it below to join the group.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Group ID input
              TextFormField(
                controller: _groupIdController,
                decoration: const InputDecoration(
                  labelText: 'Group ID',
                  hintText: 'Enter the group ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Join button
              ElevatedButton(
                onPressed: groupProvider.isLoading ? null : _joinGroup,
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
                        'Join Group',
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
