import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_logger.dart';

/// Migration script to add isActive field to all existing groups
/// Run this once to fix groups that were created before the isActive field was added
///
/// Usage:
/// - Import this file in your app
/// - Call migrateGroupsAddIsActive() once (e.g., from a button in settings or debug screen)
/// - Remove the call after migration is complete
Future<void> migrateGroupsAddIsActive() async {
  try {
    AppLogger.info('Starting migration: Adding isActive field to all groups...');

    final firestore = FirebaseFirestore.instance;
    final groupsCollection = firestore.collection('groups');

    // Get all groups
    final snapshot = await groupsCollection.get();
    AppLogger.info('Found ${snapshot.docs.length} groups to check');

    int updatedCount = 0;
    int skippedCount = 0;
    int errorCount = 0;

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data();

        // Check if isActive field exists
        if (data.containsKey('isActive')) {
          AppLogger.debug('Group ${doc.id} already has isActive field (value: ${data['isActive']}), skipping');
          skippedCount++;
          continue;
        }

        // Add isActive field with value true
        await doc.reference.update({
          'isActive': true,
        });

        AppLogger.info('Updated group ${doc.id} | Name: ${data['name']} | Added isActive: true');
        updatedCount++;
      } catch (e) {
        AppLogger.error('Failed to update group ${doc.id}', e);
        errorCount++;
      }
    }

    AppLogger.info('Migration complete! Updated: $updatedCount | Skipped: $skippedCount | Errors: $errorCount');

    if (errorCount > 0) {
      throw Exception('Migration completed with $errorCount errors. Check logs for details.');
    }
  } catch (e) {
    AppLogger.error('Migration failed', e);
    rethrow;
  }
}

/// Check how many groups are missing the isActive field
/// Useful for determining if migration is needed
Future<Map<String, int>> checkGroupsMissingIsActive() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final groupsCollection = firestore.collection('groups');

    final snapshot = await groupsCollection.get();

    int missingCount = 0;
    int hasFieldCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('isActive')) {
        hasFieldCount++;
      } else {
        missingCount++;
        AppLogger.warning('Group ${doc.id} (${data['name']}) is missing isActive field');
      }
    }

    AppLogger.info('Groups with isActive: $hasFieldCount | Groups missing isActive: $missingCount');

    return {
      'total': snapshot.docs.length,
      'hasField': hasFieldCount,
      'missing': missingCount,
    };
  } catch (e) {
    AppLogger.error('Failed to check groups', e);
    rethrow;
  }
}
