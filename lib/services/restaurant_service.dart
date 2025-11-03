import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_category.dart';
import '../models/modifier.dart';
import '../models/allergen.dart';
import '../utils/app_logger.dart';
import '../config/app_config.dart';

class MenuData {
  final List<MenuCategory> categories;
  final Map<int, ModifierGroup> modifierGroups;
  final Map<int, Modifier> modifiers;
  final Map<int, Allergen> allergens;

  MenuData({
    required this.categories,
    required this.modifierGroups,
    required this.modifiers,
    required this.allergens,
  });
}

class RestaurantService {
  static const String _cacheKeyPrefix = 'menu_cache_';
  static const String _cacheTimePrefix = 'menu_cache_time_';

  /// Fetch menu data with caching support
  /// First tries to fetch from API, falls back to cache if offline
  Future<MenuData> fetchMenuData(String apiUrl, {bool forceRefresh = false}) async {
    final cacheKey = _getCacheKey(apiUrl);

    // Try to use valid cache first
    if (!forceRefresh) {
      final cachedJson = await _getCachedRawJson(cacheKey);
      if (cachedJson != null && await _isCacheValid(cacheKey)) {
        AppLogger.info('Using cached menu data');
        return _parseMenuData(cachedJson);
      }
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        // Cache the raw JSON response
        await _cacheRawJson(cacheKey, jsonData);

        AppLogger.info('Fetched fresh menu data from API');
        return _parseMenuData(jsonData);
      } else {
        throw Exception('Failed to load menu data: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching menu data', e);

      // Try to use cached data as fallback (even if expired)
      final cachedJson = await _getCachedRawJson(cacheKey);
      if (cachedJson != null) {
        AppLogger.info('Using cached menu data (offline fallback)');
        return _parseMenuData(cachedJson);
      }

      throw Exception('Error fetching menu data: $e');
    }
  }

  /// Get cache key for a specific API URL
  String _getCacheKey(String apiUrl) {
    return '$_cacheKeyPrefix${apiUrl.hashCode}';
  }

  /// Cache raw JSON response to SharedPreferences
  Future<void> _cacheRawJson(String cacheKey, Map<String, dynamic> jsonData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(jsonData);

      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(_cacheTimePrefix + cacheKey, DateTime.now().millisecondsSinceEpoch);

      AppLogger.info('Menu data cached successfully');
    } catch (e) {
      AppLogger.error('Error caching menu data', e);
      // Don't throw - caching failure shouldn't break the app
    }
  }

  /// Retrieve cached raw JSON
  Future<Map<String, dynamic>?> _getCachedRawJson(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey);

      if (jsonString == null) {
        return null;
      }

      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error retrieving cached menu data', e);
      return null;
    }
  }

  /// Check if cached data is still valid
  Future<bool> _isCacheValid(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt(_cacheTimePrefix + cacheKey);

      if (cacheTime == null) {
        return false;
      }

      final cachedDate = DateTime.fromMillisecondsSinceEpoch(cacheTime);
      final now = DateTime.now();
      final difference = now.difference(cachedDate);

      return difference < AppConfig.menuCacheDuration;
    } catch (e) {
      AppLogger.error('Error checking cache validity', e);
      return false;
    }
  }

  /// Clear all cached menu data
  Future<void> clearMenuCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix) || key.startsWith(_cacheTimePrefix)) {
          await prefs.remove(key);
        }
      }

      AppLogger.info('Menu cache cleared');
    } catch (e) {
      AppLogger.error('Error clearing menu cache', e);
    }
  }

  MenuData _parseMenuData(Map<String, dynamic> jsonData) {
    try {
      // Parse categories with items
      final dataList = jsonData['data'] as List<dynamic>;
      final categories = <MenuCategory>[];

      for (var i = 0; i < dataList.length; i++) {
        try {
          final category = MenuCategory.fromJson(dataList[i] as Map<String, dynamic>);
          categories.add(category);
        } catch (e) {
          throw Exception('Error parsing category at index $i: $e');
        }
      }

      // Parse included data
      final included = jsonData['included'] as Map<String, dynamic>?;

      // Parse modifier groups
      final modifierGroupsMap = <int, ModifierGroup>{};
      if (included != null && included.containsKey('modifierGroups')) {
        final modifierGroupsList = included['modifierGroups'] as List<dynamic>;
        for (var i = 0; i < modifierGroupsList.length; i++) {
          try {
            final groupJson = modifierGroupsList[i] as Map<String, dynamic>;
            // Skip modifier groups with null or missing id
            if (groupJson['id'] == null) {
              AppLogger.warning('Skipping modifier group at index $i with null id');
              continue;
            }
            final group = ModifierGroup.fromJson(groupJson);
            modifierGroupsMap[group.id] = group;
          } catch (e) {
            AppLogger.warning('Failed to parse modifier group at index $i', e);
            // Skip invalid modifier groups instead of crashing
            continue;
          }
        }
      }

      // Parse modifiers
      final modifiersMap = <int, Modifier>{};
      if (included != null && included.containsKey('modifiers')) {
        final modifiersList = included['modifiers'] as List<dynamic>;
        for (var i = 0; i < modifiersList.length; i++) {
          try {
            final modifierJson = modifiersList[i] as Map<String, dynamic>;
            // Skip modifiers with null or missing id
            if (modifierJson['id'] == null) {
              AppLogger.warning('Skipping modifier at index $i with null id');
              continue;
            }
            final modifier = Modifier.fromJson(modifierJson);
            modifiersMap[modifier.id] = modifier;
          } catch (e) {
            AppLogger.warning('Failed to parse modifier at index $i', e);
            // Skip invalid modifiers instead of crashing
            continue;
          }
        }
      }

      // Parse allergens
      final allergensMap = <int, Allergen>{};
      if (included != null && included.containsKey('allergens')) {
        final allergensList = included['allergens'] as List<dynamic>;
        for (var i = 0; i < allergensList.length; i++) {
          try {
            final allergenJson = allergensList[i] as Map<String, dynamic>;
            // Skip allergens with null or missing id
            if (allergenJson['id'] == null) {
              AppLogger.warning('Skipping allergen at index $i with null id');
              continue;
            }
            final allergen = Allergen.fromJson(allergenJson);
            allergensMap[allergen.id] = allergen;
          } catch (e) {
            AppLogger.warning('Failed to parse allergen at index $i', e);
            // Skip invalid allergens instead of crashing
            continue;
          }
        }
      }

      return MenuData(
        categories: categories,
        modifierGroups: modifierGroupsMap,
        modifiers: modifiersMap,
        allergens: allergensMap,
      );
    } catch (e) {
      throw Exception('Error in _parseMenuData: $e');
    }
  }
}
