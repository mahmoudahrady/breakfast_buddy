import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_category.dart';
import '../models/modifier.dart';
import '../models/allergen.dart';

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
  Future<MenuData> fetchMenuData(String apiUrl) async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        return _parseMenuData(jsonData);
      } else {
        throw Exception('Failed to load menu data: ${response.statusCode}');
      }
    } catch (e) {
              print('error test: $e');

      throw Exception('Error fetching menu data: $e');
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
              print('Warning: Skipping modifier group at index $i with null id');
              continue;
            }
            final group = ModifierGroup.fromJson(groupJson);
            modifierGroupsMap[group.id] = group;
          } catch (e) {
            print('Warning: Failed to parse modifier group at index $i: $e');
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
              print('Warning: Skipping modifier at index $i with null id');
              continue;
            }
            final modifier = Modifier.fromJson(modifierJson);
            modifiersMap[modifier.id] = modifier;
          } catch (e) {
            print('Warning: Failed to parse modifier at index $i: $e');
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
              print('Warning: Skipping allergen at index $i with null id');
              continue;
            }
            final allergen = Allergen.fromJson(allergenJson);
            allergensMap[allergen.id] = allergen;
          } catch (e) {
            print('Warning: Failed to parse allergen at index $i: $e');
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
