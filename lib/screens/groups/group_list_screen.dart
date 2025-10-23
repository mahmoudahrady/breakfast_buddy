import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/group.dart';
import 'create_group_screen.dart';
import 'group_details_screen.dart';
import 'join_group_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  @override
  void initState() {
    super.initState();
    // Defer the call to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }

  void _loadGroups() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.user != null) {
      groupProvider.loadUserGroups(authProvider.user!.id);
    }
  }

  void _navigateToCreateGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      ),
    );

    if (result != null && mounted) {
      // Refresh the groups list after creating a group
      _loadGroups();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully!')),
      );
    }
  }

  void _navigateToGroupDetails(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(groupId: group.id),
      ),
    );
  }

  void _navigateToJoinGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JoinGroupScreen(),
      ),
    );

    if (result != null && mounted) {
      // Refresh the groups list after joining a group
      _loadGroups();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined group successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Join Group',
            onPressed: _navigateToJoinGroup,
          ),
        ],
      ),
      body: groupProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupProvider.userGroups.isEmpty
              ? _buildEmptyState()
              : _buildGroupList(groupProvider.userGroups, authProvider.user?.id),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateGroup,
        icon: const Icon(Icons.add),
        label: const Text('Create Group'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Groups Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group to share meals with friends',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateGroup,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Group'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList(List<Group> groups, String? currentUserId) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadGroups();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final isAdmin = currentUserId != null && group.isAdmin(currentUserId);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isAdmin ? Colors.orange : Colors.blue,
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.group,
                  color: Colors.white,
                ),
              ),
              title: Text(
                group.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    group.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${group.memberIds.length} members',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              isThreeLine: true,
              onTap: () => _navigateToGroupDetails(group),
            ),
          );
        },
      ),
    );
  }
}
