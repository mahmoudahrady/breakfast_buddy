import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/group_restaurant.dart';
import '../models/app_user.dart';
import '../services/group_service.dart';

class GroupProvider with ChangeNotifier {
  final GroupService _groupService = GroupService();

  List<Group> _userGroups = [];
  Group? _selectedGroup;
  List<GroupMember> _members = [];
  List<GroupRestaurant> _restaurants = [];

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _groupsSubscription;
  StreamSubscription? _selectedGroupSubscription;
  StreamSubscription? _membersSubscription;
  StreamSubscription? _restaurantsSubscription;

  // Getters
  List<Group> get userGroups => _userGroups;
  Group? get selectedGroup => _selectedGroup;
  List<GroupMember> get members => _members;
  List<GroupRestaurant> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize and load user's groups
  Future<void> loadUserGroups(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      // Cancel existing subscription
      await _groupsSubscription?.cancel();

      // Subscribe to user's groups
      _groupsSubscription = _groupService.getUserGroups(userId).listen(
        (groups) {
          _userGroups = groups;
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _setError('Failed to load groups: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Failed to load groups: $e');
      _setLoading(false);
    }
  }

  // Select a group and load its details
  Future<void> selectGroup(String groupId) async {
    _setLoading(true);
    _clearError();

    try {
      // Load group details
      final group = await _groupService.getGroup(groupId);
      if (group != null) {
        _selectedGroup = group;

        // Cancel existing subscriptions
        await _selectedGroupSubscription?.cancel();
        await _membersSubscription?.cancel();
        await _restaurantsSubscription?.cancel();

        // Subscribe to real-time group updates
        _selectedGroupSubscription = _groupService.getGroupStream(groupId).listen(
          (group) {
            if (group != null) {
              _selectedGroup = group;
              notifyListeners();
            }
          },
          onError: (error) {
            _setError('Failed to load group updates: $error');
          },
        );

        // Subscribe to members
        _membersSubscription = _groupService.getGroupMembers(groupId).listen(
          (members) {
            _members = members;
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load members: $error');
          },
        );

        // Subscribe to restaurants
        _restaurantsSubscription =
            _groupService.getGroupRestaurants(groupId).listen(
          (restaurants) {
            _restaurants = restaurants;
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load restaurants: $error');
          },
        );

        _setLoading(false);
        notifyListeners();
      } else {
        _setError('Group not found');
        _setLoading(false);
      }
    } catch (e) {
      _setError('Failed to select group: $e');
      _setLoading(false);
    }
  }

  // Create a new group
  Future<Group?> createGroup({
    required String name,
    required String description,
    required AppUser admin,
    required bool allowMembersToAddItems,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final group = await _groupService.createGroup(
        name: name,
        description: description,
        admin: admin,
        allowMembersToAddItems: allowMembersToAddItems,
      );
      _setLoading(false);
      notifyListeners();
      return group;
    } catch (e) {
      _setError('Failed to create group: $e');
      _setLoading(false);
      return null;
    }
  }

  // Update group settings
  Future<bool> updateGroup({
    required String groupId,
    String? name,
    String? description,
    bool? allowMembersToAddItems,
    bool? isActive,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        allowMembersToAddItems: allowMembersToAddItems,
        isActive: isActive,
      );

      // Refresh selected group if it's the one being updated
      if (_selectedGroup?.id == groupId) {
        final updatedGroup = await _groupService.getGroup(groupId);
        if (updatedGroup != null) {
          _selectedGroup = updatedGroup;
        }
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update group: $e');
      _setLoading(false);
      return false;
    }
  }

  // Toggle group active status
  Future<bool> toggleGroupActiveStatus(String groupId, bool isActive) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.updateGroupActiveStatus(groupId, isActive);

      // Refresh selected group if it's the one being updated
      if (_selectedGroup?.id == groupId) {
        final updatedGroup = await _groupService.getGroup(groupId);
        if (updatedGroup != null) {
          _selectedGroup = updatedGroup;
        }
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to toggle group status: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete a group
  Future<bool> deleteGroup(String groupId) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.deleteGroup(groupId);

      // Clear selected group if it's the one being deleted
      if (_selectedGroup?.id == groupId) {
        _selectedGroup = null;
        _members = [];
        _restaurants = [];
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete group: $e');
      _setLoading(false);
      return false;
    }
  }

  // Add a member to the group
  Future<bool> addMember({
    required String groupId,
    required AppUser user,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.addMember(
        groupId: groupId,
        user: user,
        isAdmin: false,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add member: $e');
      _setLoading(false);
      return false;
    }
  }

  // Remove a member from the group
  Future<bool> removeMember({
    required String groupId,
    required String userId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.removeMember(
        groupId: groupId,
        userId: userId,
      );
      _setLoading(false);
      // Don't call notifyListeners() - stream subscription will handle it
      return true;
    } catch (e) {
      _setError('Failed to remove member: $e');
      _setLoading(false);
      return false;
    }
  }

  // Add a restaurant to the group
  Future<bool> addRestaurant({
    required String groupId,
    required String restaurantId,
    required String restaurantName,
    String? restaurantApiUrl,
    String? restaurantImageUrl,
    String? restaurantDescription,
    required String addedBy,
    required String addedByName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.addRestaurant(
        groupId: groupId,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        restaurantApiUrl: restaurantApiUrl,
        restaurantImageUrl: restaurantImageUrl,
        restaurantDescription: restaurantDescription,
        addedBy: addedBy,
        addedByName: addedByName,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add restaurant: $e');
      _setLoading(false);
      return false;
    }
  }

  // Remove a restaurant from the group
  Future<bool> removeRestaurant(String restaurantDocId) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.removeRestaurant(restaurantDocId);
      _setLoading(false);
      // Don't call notifyListeners() - stream subscription will handle it
      return true;
    } catch (e) {
      _setError('Failed to remove restaurant: $e');
      _setLoading(false);
      return false;
    }
  }

  // Join a group
  Future<bool> joinGroup({
    required String groupId,
    required AppUser user,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.joinGroup(
        groupId: groupId,
        user: user,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to join group: $e');
      _setLoading(false);
      return false;
    }
  }

  // Leave a group
  Future<bool> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _groupService.leaveGroup(
        groupId: groupId,
        userId: userId,
      );

      // Clear selected group if user is leaving it
      if (_selectedGroup?.id == groupId) {
        _selectedGroup = null;
        _members = [];
        _restaurants = [];
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to leave group: $e');
      _setLoading(false);
      return false;
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Clear selected group
  void clearSelectedGroup() {
    _selectedGroup = null;
    _members = [];
    _restaurants = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    _selectedGroupSubscription?.cancel();
    _membersSubscription?.cancel();
    _restaurantsSubscription?.cancel();
    super.dispose();
  }
}
