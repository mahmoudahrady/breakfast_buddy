class MenuItem {
  final int id;
  final int? parentCategoryId;
  final String code;
  final int displayOrder;
  final Map<String, String> name;
  final Map<String, String> description;
  final String? imageUri;
  final double price;
  final double listPrice;
  final double originalPrice;
  final int calorieCount;
  final int personCountPerServing;
  final bool favorite;
  final bool enabled;
  final bool disableForPickup;
  final bool disableForDelivery;
  final bool isCustomizable;
  final bool isCombo;
  final bool isFavouritable;
  final bool isReorderable;
  final bool isDiscountAllowed;
  final int preparationTime;
  final bool isHiddenFromMenu;
  final List<dynamic> ingredients;
  final List<int> modifierGroups;
  final List<int> allergens;
  final List<dynamic> excludedApps;
  final List<dynamic> excludedLocations;
  final List<dynamic> outOfStockLocations;
  final List<dynamic> prices;
  final bool mustBeCustomized;
  final Map<String, dynamic> customFields;
  final dynamic calories;
  final int? recommendedComboId;
  final String? barcode;
  final bool hasTimedEvent;

  MenuItem({
    required this.id,
    this.parentCategoryId,
    required this.code,
    required this.displayOrder,
    required this.name,
    required this.description,
    this.imageUri,
    required this.price,
    required this.listPrice,
    required this.originalPrice,
    required this.calorieCount,
    required this.personCountPerServing,
    required this.favorite,
    required this.enabled,
    required this.disableForPickup,
    required this.disableForDelivery,
    required this.isCustomizable,
    required this.isCombo,
    required this.isFavouritable,
    required this.isReorderable,
    required this.isDiscountAllowed,
    required this.preparationTime,
    required this.isHiddenFromMenu,
    required this.ingredients,
    required this.modifierGroups,
    required this.allergens,
    required this.excludedApps,
    required this.excludedLocations,
    required this.outOfStockLocations,
    required this.prices,
    required this.mustBeCustomized,
    this.customFields = const {},
    this.calories,
    this.recommendedComboId,
    this.barcode,
    this.hasTimedEvent = false,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    try {
      // Parse name map, handling various data types
      final nameMap = json['name'] as Map<dynamic, dynamic>;
      final parsedName = <String, String>{};
      nameMap.forEach((key, value) {
        parsedName[key.toString()] = value.toString();
      });

      // Parse description map, handling various data types
      final descMap = json['description'] as Map<dynamic, dynamic>;
      final parsedDescription = <String, String>{};
      descMap.forEach((key, value) {
        parsedDescription[key.toString()] = value.toString();
      });

      // Parse modifier groups - handle both int and object formats
      final modifierGroupsList = json['modifier-groups'] as List<dynamic>;
      final parsedModifierGroups = <int>[];
      for (var item in modifierGroupsList) {
        if (item is int) {
          parsedModifierGroups.add(item);
        } else if (item is Map) {
          // If it's an object, try to get the id
          parsedModifierGroups.add(item['id'] as int);
        }
      }

      // Parse allergens - handle both int and object formats
      final allergensList = json['allergens'] as List<dynamic>;
      final parsedAllergens = <int>[];
      for (var item in allergensList) {
        if (item is int) {
          parsedAllergens.add(item);
        } else if (item is Map) {
          // If it's an object, try to get the id
          parsedAllergens.add(item['id'] as int);
        }
      }

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

      return MenuItem(
        id: parseInt(json['id']),
        parentCategoryId: json['parent-category-id'] == null ? null : parseInt(json['parent-category-id']),
        code: json['code'].toString(),
        displayOrder: parseInt(json['display-order']),
        name: parsedName,
        description: parsedDescription,
        imageUri: json['image-uri'] as String?,
        price: (json['price'] as num).toDouble(),
        listPrice: (json['list-price'] as num).toDouble(),
        originalPrice: (json['original-price'] as num).toDouble(),
        calorieCount: parseInt(json['calorie-count']),
        personCountPerServing: parseInt(json['person-count-per-serving']),
        favorite: json['favorite'] as bool,
        enabled: parseBoolFromInt(json['enabled']),
        disableForPickup: parseBoolFromInt(json['disable-for-pickup']),
        disableForDelivery: parseBoolFromInt(json['disable-for-delivery']),
        isCustomizable: json['is-customizable'] as bool,
        isCombo: json['is-combo'] as bool,
        isFavouritable: json['is-favouritable'] as bool,
        isReorderable: json['is-reorderable'] as bool,
        isDiscountAllowed: json['is-discount-allowed'] as bool,
        preparationTime: parseInt(json['preparation-time']),
        isHiddenFromMenu: json['is-hidden-from-menu'] as bool,
        ingredients: json['ingredients'] as List<dynamic>? ?? [],
        modifierGroups: parsedModifierGroups,
        allergens: parsedAllergens,
        excludedApps: json['excluded-apps'] as List<dynamic>? ?? [],
        excludedLocations: json['excluded-locations'] as List<dynamic>? ?? [],
        outOfStockLocations: json['out-of-stock-locations'] as List<dynamic>? ?? [],
        prices: json['prices'] as List<dynamic>? ?? [],
        mustBeCustomized: json['must-be-customized'] as bool,
        customFields: json['custom-fields'] as Map<String, dynamic>? ?? {},
        calories: json['calories'],
        recommendedComboId: json['recommended-combo-id'] == null ? null : parseInt(json['recommended-combo-id']),
        barcode: json['barcode'] as String?,
        hasTimedEvent: json['has-timed-event'] as bool? ?? false,
      );
    } catch (e, stackTrace) {
      throw Exception('Error parsing MenuItem (id: ${json['id']}): $e\n$stackTrace');
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
    if (description[locale] != null) return description[locale]!;

    // For 'ar', try common Arabic variants
    if (locale == 'ar') {
      if (description['ar-sa'] != null) return description['ar-sa']!;
      if (description['ar-SA'] != null) return description['ar-SA']!;
      if (description['ar_sa'] != null) return description['ar_sa']!;
      if (description['ar_SA'] != null) return description['ar_SA']!;
    }

    // Fall back to English
    return description['en-us'] ?? description['en-US'] ?? description['en'] ?? '';
  }

  MenuItem copyWith({
    int? id,
    int? parentCategoryId,
    String? code,
    int? displayOrder,
    Map<String, String>? name,
    Map<String, String>? description,
    String? imageUri,
    double? price,
    double? listPrice,
    double? originalPrice,
    int? calorieCount,
    int? personCountPerServing,
    bool? favorite,
    bool? enabled,
    bool? disableForPickup,
    bool? disableForDelivery,
    bool? isCustomizable,
    bool? isCombo,
    bool? isFavouritable,
    bool? isReorderable,
    bool? isDiscountAllowed,
    int? preparationTime,
    bool? isHiddenFromMenu,
    List<dynamic>? ingredients,
    List<int>? modifierGroups,
    List<int>? allergens,
    List<dynamic>? excludedApps,
    List<dynamic>? excludedLocations,
    List<dynamic>? outOfStockLocations,
    List<dynamic>? prices,
    bool? mustBeCustomized,
    Map<String, dynamic>? customFields,
    dynamic calories,
    int? recommendedComboId,
    String? barcode,
    bool? hasTimedEvent,
  }) {
    return MenuItem(
      id: id ?? this.id,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      code: code ?? this.code,
      displayOrder: displayOrder ?? this.displayOrder,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUri: imageUri ?? this.imageUri,
      price: price ?? this.price,
      listPrice: listPrice ?? this.listPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      calorieCount: calorieCount ?? this.calorieCount,
      personCountPerServing: personCountPerServing ?? this.personCountPerServing,
      favorite: favorite ?? this.favorite,
      enabled: enabled ?? this.enabled,
      disableForPickup: disableForPickup ?? this.disableForPickup,
      disableForDelivery: disableForDelivery ?? this.disableForDelivery,
      isCustomizable: isCustomizable ?? this.isCustomizable,
      isCombo: isCombo ?? this.isCombo,
      isFavouritable: isFavouritable ?? this.isFavouritable,
      isReorderable: isReorderable ?? this.isReorderable,
      isDiscountAllowed: isDiscountAllowed ?? this.isDiscountAllowed,
      preparationTime: preparationTime ?? this.preparationTime,
      isHiddenFromMenu: isHiddenFromMenu ?? this.isHiddenFromMenu,
      ingredients: ingredients ?? this.ingredients,
      modifierGroups: modifierGroups ?? this.modifierGroups,
      allergens: allergens ?? this.allergens,
      excludedApps: excludedApps ?? this.excludedApps,
      excludedLocations: excludedLocations ?? this.excludedLocations,
      outOfStockLocations: outOfStockLocations ?? this.outOfStockLocations,
      prices: prices ?? this.prices,
      mustBeCustomized: mustBeCustomized ?? this.mustBeCustomized,
      customFields: customFields ?? this.customFields,
      calories: calories ?? this.calories,
      recommendedComboId: recommendedComboId ?? this.recommendedComboId,
      barcode: barcode ?? this.barcode,
      hasTimedEvent: hasTimedEvent ?? this.hasTimedEvent,
    );
  }
}
