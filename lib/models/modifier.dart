class Modifier {
  final int id;
  final String code;
  final int displayOrder;
  final Map<String, String> name;
  final String? imageUri;
  final double price;
  final int calorieCount;
  final int minimum;
  final int maximum;
  final bool enabled;
  final List<dynamic> excludedLocations;
  final List<dynamic> prices;
  final Map<String, dynamic> customFields;

  Modifier({
    required this.id,
    required this.code,
    required this.displayOrder,
    required this.name,
    this.imageUri,
    required this.price,
    required this.calorieCount,
    required this.minimum,
    required this.maximum,
    required this.enabled,
    required this.excludedLocations,
    required this.prices,
    this.customFields = const {},
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    try {
      final attributes = json['attributes'] as Map<String, dynamic>;

      // Parse name map, handling various data types
      final nameMap = attributes['name'] as Map<dynamic, dynamic>;
      final parsedName = <String, String>{};
      nameMap.forEach((key, value) {
        parsedName[key.toString()] = value.toString();
      });

      // Helper function to safely parse int
      int parseInt(dynamic value, String fieldName) {
        if (value == null) {
          throw Exception('Cannot parse int from null for field: $fieldName');
        }
        if (value is int) return value;
        if (value is String) {
          if (value.isEmpty) {
            throw Exception('Cannot parse int from empty string for field: $fieldName');
          }
          return int.parse(value);
        }
        if (value is num) return value.toInt();
        throw Exception('Cannot parse int from $value (type: ${value.runtimeType}) for field: $fieldName');
      }

      // Helper function to safely parse bool from int
      bool parseBoolFromInt(dynamic value) {
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) return value == '1' || value.toLowerCase() == 'true';
        return false;
      }

      return Modifier(
        id: parseInt(json['id'], 'id'),
        code: attributes['code'].toString(),
        displayOrder: parseInt(attributes['display-order'], 'display-order'),
        name: parsedName,
        imageUri: attributes['image-uri'] as String?,
        price: (attributes['price'] as num).toDouble(),
        calorieCount: parseInt(attributes['calorie-count'], 'calorie-count'),
        minimum: parseInt(attributes['minimum'], 'minimum'),
        maximum: parseInt(attributes['maximum'], 'maximum'),
        enabled: parseBoolFromInt(attributes['enabled']),
        excludedLocations: attributes['excluded-locations'] as List<dynamic>? ?? [],
        prices: attributes['prices'] as List<dynamic>? ?? [],
        customFields: attributes['custom-fields'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      throw Exception('Error parsing Modifier (json keys: ${json.keys.join(', ')}): $e');
    }
  }

  String getLocalizedName(String locale) {
    return name[locale] ?? name['en-us'] ?? '';
  }
}

class ModifierGroup {
  final int id;
  final String? code;
  final String label;
  final int displayOrder;
  final Map<String, String> name;
  final String? imageUri;
  final int minimum;
  final int maximum;
  final bool enabled;
  final String type;
  final List<int> modifierIds;
  final List<dynamic> excludedLocations;
  final List<dynamic> excludeModifiers;
  final List<dynamic> defaultModifiers;
  final Map<String, dynamic> customFields;
  final dynamic visibilityConfig;

  ModifierGroup({
    required this.id,
    this.code,
    required this.label,
    required this.displayOrder,
    required this.name,
    this.imageUri,
    required this.minimum,
    required this.maximum,
    required this.enabled,
    required this.type,
    required this.modifierIds,
    required this.excludedLocations,
    required this.excludeModifiers,
    required this.defaultModifiers,
    this.customFields = const {},
    this.visibilityConfig,
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    try {
      final attributes = json['attributes'] as Map<String, dynamic>;

      // Parse name map, handling various data types
      final nameMap = attributes['name'] as Map<dynamic, dynamic>;
      final parsedName = <String, String>{};
      nameMap.forEach((key, value) {
        parsedName[key.toString()] = value.toString();
      });

      // Handle code field which might be the string "null"
      final codeValue = attributes['code'];
      final String? code = (codeValue == null || codeValue == 'null') ? null : codeValue.toString();

      // Helper function to safely parse int
      int parseInt(dynamic value, String fieldName) {
        if (value == null) {
          throw Exception('Cannot parse int from null for field: $fieldName');
        }
        if (value is int) return value;
        if (value is String) {
          if (value.isEmpty) {
            throw Exception('Cannot parse int from empty string for field: $fieldName');
          }
          return int.parse(value);
        }
        if (value is num) return value.toInt();
        throw Exception('Cannot parse int from $value (type: ${value.runtimeType}) for field: $fieldName');
      }

      // Helper function to safely parse bool from int
      bool parseBoolFromInt(dynamic value) {
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) return value == '1' || value.toLowerCase() == 'true';
        return false;
      }

      // Parse modifiers list - handle both int and object formats
      final modifiersList = attributes['modifiers'] as List<dynamic>;
      final parsedModifiers = <int>[];
      for (var item in modifiersList) {
        if (item is int) {
          parsedModifiers.add(item);
        } else if (item is Map) {
          parsedModifiers.add(parseInt(item['id'], 'modifier-id-in-list'));
        }
      }

      return ModifierGroup(
        id: parseInt(json['id'], 'id'),
        code: code,
        label: attributes['label'].toString(),
        displayOrder: parseInt(attributes['display-order'], 'display-order'),
        name: parsedName,
        imageUri: attributes['image-uri'] as String?,
        minimum: parseInt(attributes['minimum'], 'minimum'),
        maximum: parseInt(attributes['maximum'], 'maximum'),
        enabled: parseBoolFromInt(attributes['enabled']),
        type: attributes['type'].toString(),
        modifierIds: parsedModifiers,
        excludedLocations: attributes['excluded-locations'] as List<dynamic>? ?? [],
        excludeModifiers: attributes['exclude-modifiers'] as List<dynamic>? ?? [],
        defaultModifiers: attributes['default-modifiers'] as List<dynamic>? ?? [],
        customFields: attributes['custom-fields'] as Map<String, dynamic>? ?? {},
        visibilityConfig: attributes['visibility-config'],
      );
    } catch (e) {
      throw Exception('Error parsing ModifierGroup (json keys: ${json.keys.join(', ')}): $e');
    }
  }

  String getLocalizedName(String locale) {
    return name[locale] ?? name['en-us'] ?? '';
  }
}
