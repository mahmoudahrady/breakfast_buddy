import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/group_restaurant.dart';
import '../models/app_user.dart';
import '../utils/app_logger.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _groupsCollection => _firestore.collection('groups');
  CollectionReference get _membersCollection =>
      _firestore.collection('groupMembers');
  CollectionReference get _restaurantsCollection =>
      _firestore.collection('groupRestaurants');

  // Create a new group
  Future<Group> createGroup({
    required String name,
    required String description,
    required AppUser admin,
    required bool allowMembersToAddItems,
    DateTime? orderDeadline,
  }) async {
    try {
      final groupData = {
        'name': name,
        'description': description,
        'adminId': admin.id,
        'adminName': admin.name,
        'memberIds': [admin.id], // Admin is automatically a member
        'allowMembersToAddItems': allowMembersToAddItems,
        'isActive': true, // New groups are active by default
        'createdAt': FieldValue.serverTimestamp(),
        if (orderDeadline != null)
          'orderDeadline': Timestamp.fromDate(orderDeadline),
      };

      final docRef = await _groupsCollection.add(groupData);
      final doc = await docRef.get();

      AppLogger.info('Group created: ${doc.id} | Name: $name | isActive: true | Admin: ${admin.name}');

      // Add admin as first member
      await addMember(
        groupId: doc.id,
        user: admin,
        isAdmin: true,
      );

      final createdGroup = Group.fromFirestore(doc);
      AppLogger.debug('Group loaded from Firestore: ${createdGroup.id} | isActive: ${createdGroup.isActive}');

      return createdGroup;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  // Get all groups where user is a member
  Stream<List<Group>> getUserGroups(String userId) {
    return _groupsCollection
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList());
  }

  // Get a specific group by ID
  Future<Group?> getGroup(String groupId) async {
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      if (!doc.exists) {
        AppLogger.warning('Group not found: $groupId');
        return null;
      }
      final group = Group.fromFirestore(doc);
      AppLogger.debug('Group fetched: ${group.id} | isActive: ${group.isActive} | Name: ${group.name}');
      return group;
    } catch (e) {
      AppLogger.error('Failed to get group: $groupId', e);
      throw Exception('Failed to get group: $e');
    }
  }

  // Get real-time updates for a specific group
  Stream<Group?> getGroupStream(String groupId) {
    return _groupsCollection.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Group.fromFirestore(doc);
    });
  }

  // Update group settings
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
    bool? allowMembersToAddItems,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (allowMembersToAddItems != null) {
        updateData['allowMembersToAddItems'] = allowMembersToAddItems;
      }
      if (isActive != null) updateData['isActive'] = isActive;

      if (updateData.isNotEmpty) {
        await _groupsCollection.doc(groupId).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  // Update group active status
  Future<void> updateGroupActiveStatus(String groupId, bool isActive) async {
    try {
      await _groupsCollection.doc(groupId).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw Exception('Failed to update group active status: $e');
    }
  }

  // Delete a group
  Future<void> deleteGroup(String groupId) async {
    try {
      // Delete all members
      final members = await _membersCollection
          .where('groupId', isEqualTo: groupId)
          .get();
      for (var doc in members.docs) {
        await doc.reference.delete();
      }

      // Delete all restaurants
      final restaurants = await _restaurantsCollection
          .where('groupId', isEqualTo: groupId)
          .get();
      for (var doc in restaurants.docs) {
        await doc.reference.delete();
      }

      // Delete the group
      await _groupsCollection.doc(groupId).delete();
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  // Add a member to a group
  Future<GroupMember> addMember({
    required String groupId,
    required AppUser user,
    bool isAdmin = false,
  }) async {
    try {
      final memberData = {
        'groupId': groupId,
        'userId': user.id,
        'userName': user.name,
        'userEmail': user.email,
        'userPhotoUrl': user.photoUrl,
        'joinedAt': FieldValue.serverTimestamp(),
        'isAdmin': isAdmin,
      };

      final docRef = await _membersCollection.add(memberData);
      final doc = await docRef.get();

      // Update group's memberIds array
      await _groupsCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([user.id]),
      });

      return GroupMember.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  // Remove a member from a group
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      // Find and delete the member document
      final members = await _membersCollection
          .where('groupId', isEqualTo: groupId)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in members.docs) {
        await doc.reference.delete();
      }

      // Update group's memberIds array
      await _groupsCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  // Get all members of a group
  Stream<List<GroupMember>> getGroupMembers(String groupId) {
    return _membersCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupMember.fromFirestore(doc))
            .toList());
  }

  // Add a restaurant to a group
  Future<GroupRestaurant> addRestaurant({
    required String groupId,
    required String restaurantId,
    required String restaurantName,
    String? restaurantApiUrl,
    String? restaurantImageUrl,
    String? restaurantDescription,
    required String addedBy,
    required String addedByName,
  }) async {
    try {
      // Check if group already has a restaurant
      final existingRestaurants = await _restaurantsCollection
          .where('groupId', isEqualTo: groupId)
          .get();

      if (existingRestaurants.docs.isNotEmpty) {
        throw Exception('This group already has a restaurant. Please remove it first before adding a new one.');
      }

      final restaurantData = {
        'groupId': groupId,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'restaurantApiUrl': restaurantApiUrl,
        'restaurantImageUrl': restaurantImageUrl,
        'restaurantDescription': restaurantDescription,
        'addedBy': addedBy,
        'addedByName': addedByName,
        'addedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _restaurantsCollection.add(restaurantData);
      final doc = await docRef.get();

      return GroupRestaurant.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to add restaurant: $e');
    }
  }

  // Remove a restaurant from a group
  Future<void> removeRestaurant(String restaurantDocId) async {
    try {
      await _restaurantsCollection.doc(restaurantDocId).delete();
    } catch (e) {
      throw Exception('Failed to remove restaurant: $e');
    }
  }

  // Get all restaurants in a group
  Stream<List<GroupRestaurant>> getGroupRestaurants(String groupId) {
    return _restaurantsCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupRestaurant.fromFirestore(doc))
            .toList());
  }

  // Join a group by group ID (for users who receive an invite link)
  Future<void> joinGroup({
    required String groupId,
    required AppUser user,
  }) async {
    try {
      // Check if user is already a member
      final existingMembers = await _membersCollection
          .where('groupId', isEqualTo: groupId)
          .where('userId', isEqualTo: user.id)
          .get();

      if (existingMembers.docs.isNotEmpty) {
        throw Exception('User is already a member of this group');
      }

      // Add user as a member
      await addMember(
        groupId: groupId,
        user: user,
        isAdmin: false,
      );
    } catch (e) {
      throw Exception('Failed to join group: $e');
    }
  }

  // Leave a group (for non-admin members)
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      // Check if user is admin
      final group = await getGroup(groupId);
      if (group != null && group.adminId == userId) {
        throw Exception('Admin cannot leave the group. Transfer admin rights or delete the group.');
      }

      await removeMember(groupId: groupId, userId: userId);
    } catch (e) {
      throw Exception('Failed to leave group: $e');
    }
  }
}
