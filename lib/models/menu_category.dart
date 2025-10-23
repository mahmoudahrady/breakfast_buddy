import 'menu_item.dart';

class MenuCategory {
  final int id;
  final String? code;
  final int displayOrder;
  final Map<String, String> name;
  final Map<String, String> description;
  final String? imageUri;
  final bool enabled;
  final List<dynamic> excludedLocations;
  final Map<String, dynamic> customFields;
  final List<dynamic> excludedApps;
  final List<MenuItem> items;

  MenuCategory({
    required this.id,
    this.code,
    required this.displayOrder,
    required this.name,
    required this.description,
    this.imageUri,
    required this.enabled,
    required this.excludedLocations,
    this.customFields = const {},
    this.excludedApps = const [],
    required this.items,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    try {
      final attributes = json['attributes'] as Map<String, dynamic>;
      final category = attributes['category'] as Map<String, dynamic>;
      final itemsList = attributes['items'] as List<dynamic>;

      // Parse name map, handling various data types
      final nameMap = category['name'] as Map<dynamic, dynamic>;
      final parsedName = <String, String>{};
      nameMap.forEach((key, value) {
        parsedName[key.toString()] = value.toString();
      });

      // Parse description map, handling various data types
      final descMap = category['description'] as Map<dynamic, dynamic>;
      final parsedDescription = <String, String>{};
      descMap.forEach((key, value) {
        parsedDescription[key.toString()] = value.toString();
      });

      // Handle code field which might be the string "null"
      final codeValue = category['code'];
      final String? code = (codeValue == null || codeValue == 'null') ? null : codeValue.toString();

      // Helper function to safely parse int
      int parseInt(dynamic value) {
        if (value is int) return value;
        if (value is String) return int.parse(value);
        if (value is num) return value.toInt();
        throw Exception('Cannot parse int from $value');
      }

      // Helper function to safely parse bool from int
      bool parseBoolFromInt(dynamic value) {
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) return value == '1' || value.toLowerCase() == 'true';
        return false;
      }

      return MenuCategory(
        id: parseInt(category['id']),
        code: code,
        displayOrder: parseInt(category['display-order']),
        name: parsedName,
        description: parsedDescription,
        imageUri: category['image-uri'] as String?,
        enabled: parseBoolFromInt(category['enabled']),
        excludedLocations: category['excluded-locations'] as List<dynamic>? ?? [],
        customFields: category['custom-fields'] as Map<String, dynamic>? ?? {},
        excludedApps: category['excluded-apps'] as List<dynamic>? ?? [],
        items: itemsList.map((item) => MenuItem.fromJson(item as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      throw Exception('Error parsing MenuCategory: $e');
    }
  }

  String getLocalizedName(String locale) {
    // Try exact locale first
    if (name[locale] != null) return name[locale]!;

    // For 'ar', try common Arabic variants
    if (locale == 'ar') {
      if (name['ar-sa'] != null) return name['ar-sa']!;
      if (name['ar-SA'] != null) return name['ar-SA']!;
      if (name['ar_sa'] != null) return name['ar_sa']!;
      if (name['ar_SA'] != null) return name['ar_SA']!;
    }

    // Fall back to English
    return name['en-us'] ?? name['en-US'] ?? name['en'] ?? '';
  }

  String getLocalizedDescription(String locale) {
    // Try exact locale first
    if (description[locale] != null) {
      final desc = description[locale]!;
      return desc == 'undefined' ? '' : desc;
    }

    // For 'ar', try common Arabic variants
    if (locale == 'ar') {
      if (description['ar-sa'] != null) {
        final desc = description['ar-sa']!;
        return desc == 'undefined' ? '' : desc;
      }
      if (description['ar-SA'] != null) {
        final desc = description['ar-SA']!;
        return desc == 'undefined' ? '' : desc;
      }
      if (description['ar_sa'] != null) {
        final desc = description['ar_sa']!;
        return desc == 'undefined' ? '' : desc;
      }
      if (description['ar_SA'] != null) {
        final desc = description['ar_SA']!;
        return desc == 'undefined' ? '' : desc;
      }
    }

    // Fall back to English
    final desc = description['en-us'] ?? description['en-US'] ?? description['en'] ?? '';
    return desc == 'undefined' ? '' : desc;
  }

  MenuCategory copyWith({
    int? id,
    String? code,
    int? displayOrder,
    Map<String, String>? name,
    Map<String, String>? description,
    String? imageUri,
    bool? enabled,
    List<dynamic>? excludedLocations,
    Map<String, dynamic>? customFields,
    List<dynamic>? excludedApps,
    List<MenuItem>? items,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      code: code ?? this.code,
      displayOrder: displayOrder ?? this.displayOrder,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUri: imageUri ?? this.imageUri,
      enabled: enabled ?? this.enabled,
      excludedLocations: excludedLocations ?? this.excludedLocations,
      customFields: customFields ?? this.customFields,
      excludedApps: excludedApps ?? this.excludedApps,
      items: items ?? this.items,
    );
  }
}
