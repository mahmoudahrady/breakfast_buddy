import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/tropical_theme.dart';

class GroupSettingsScreen extends StatefulWidget {
  final String groupId;

  const GroupSettingsScreen({super.key, required this.groupId});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late TextEditingController _nameController;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final group = groupProvider.selectedGroup;

    _nameController = TextEditingController(text: group?.name ?? '');

    _nameController.addListener(_markAsChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _saveSettings() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final group = groupProvider.selectedGroup;

    if (group == null) return;

    // Validate inputs
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Update group settings
      await groupProvider.updateGroup(
        groupId: widget.groupId,
        name: _nameController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        setState(() {
          _hasUnsavedChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final group = groupProvider.selectedGroup;

    if (group == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = authProvider.user != null && group.isAdmin(authProvider.user!.id);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Group Settings'),
        ),
        body: const Center(
          child: Text('Only group admins can access settings'),
        ),
      );
    }

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: TropicalColors.background,
        appBar: AppBar(
          title: const Text('Group Settings'),
          backgroundColor: Colors.white,
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TropicalColors.mint,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionHeader(context, 'Basic Information', Icons.info_rounded),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    labelStyle: const TextStyle(
                      color: TropicalColors.mediumText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: 'Enter group name',
                    hintStyle: TextStyle(
                      color: TropicalColors.mediumText.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.group_rounded,
                        color: TropicalColors.orange,
                        size: 22,
                      ),
                    ),
                    filled: true,
                    fillColor: TropicalColors.orange.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: TropicalColors.orange,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              // Group Status Section
              _buildSectionHeader(context, 'Group Status', Icons.toggle_on_rounded),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: group.isActive
                            ? TropicalColors.mint.withValues(alpha: 0.15)
                            : TropicalColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        group.isActive ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                        color: group.isActive ? TropicalColors.mint : TropicalColors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Group Active',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: TropicalColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            group.isActive
                                ? 'Members can place orders'
                                : 'Orders are disabled',
                            style: const TextStyle(
                              fontSize: 14,
                              color: TropicalColors.mediumText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: group.isActive,
                      activeColor: TropicalColors.mint,
                      onChanged: (value) async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(value ? 'Activate Group?' : 'Deactivate Group?'),
                            content: Text(
                              value
                                  ? 'Members will be able to place orders.'
                                  : 'Members will not be able to place orders.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: value ? TropicalColors.mint : TropicalColors.orange,
                                ),
                                child: Text(value ? 'Activate' : 'Deactivate'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && mounted) {
                          await groupProvider.toggleGroupActiveStatus(
                            widget.groupId,
                            value,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Statistics Section
              _buildSectionHeader(context, 'Statistics', Icons.bar_chart_rounded),
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Total Members', '${group.memberIds.length}'),
                    Divider(height: 32, color: Colors.black.withValues(alpha: 0.08)),
                    _buildStatRow('Total Restaurants', '${groupProvider.restaurants.length}'),
                    Divider(height: 32, color: Colors.black.withValues(alpha: 0.08)),
                    _buildStatRow(
                      'Created On',
                      DateFormat('MMM d, yyyy').format(group.createdAt),
                    ),
                    Divider(height: 32, color: Colors.black.withValues(alpha: 0.08)),
                    _buildStatRow('Group ID', group.id, isMonospace: true),
                  ],
                ),
              ),
              // Danger Zone
              _buildSectionHeader(
                context,
                'Danger Zone',
                Icons.warning_rounded,
                color: TropicalColors.error,
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TropicalColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: TropicalColors.error.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: TropicalColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.delete_forever_rounded,
                            color: TropicalColors.error,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Delete Group',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: TropicalColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Permanently delete this group and all associated data. This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 14,
                        color: TropicalColors.error.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDeleteGroup(groupProvider),
                        icon: const Icon(Icons.delete_forever_rounded, size: 20),
                        label: const Text(
                          'Delete Group Permanently',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TropicalColors.error,
                          side: BorderSide(color: TropicalColors.error, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: color ?? TropicalColors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color ?? TropicalColors.darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isMonospace = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: TropicalColors.mediumText,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: isMonospace ? 'monospace' : null,
              color: TropicalColors.darkText,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteGroup(GroupProvider groupProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Group?'),
          ],
        ),
        content: const Text(
          'This will permanently delete the group, all its restaurants, orders, and member records. '
          'This action cannot be undone.\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await groupProvider.deleteGroup(widget.groupId);

      if (mounted) {
        if (success) {
          Navigator.pop(context); // Go back to previous screen
          Navigator.pop(context); // Go back again to groups list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                groupProvider.errorMessage ?? 'Failed to delete group',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
