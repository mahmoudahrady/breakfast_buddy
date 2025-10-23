class Allergen {
  final int id;
  final Map<String, String> name;
  final Map<String, String> icon;

  Allergen({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory Allergen.fromJson(Map<String, dynamic> json) {
    try {
      final attributes = json['attributes'] as Map<String, dynamic>;

      // Parse name map, handling various data types
      final nameMap = attributes['name'] as Map<dynamic, dynamic>;
      final parsedName = <String, String>{};
      nameMap.forEach((key, value) {
        parsedName[key.toString()] = value.toString();
      });

      // Parse icon map, handling various data types
      final iconMap = attributes['icon'] as Map<dynamic, dynamic>;
      final parsedIcon = <String, String>{};
      iconMap.forEach((key, value) {
        parsedIcon[key.toString()] = value.toString();
      });

      // Helper function to safely parse int
      int parseInt(dynamic value) {
        if (value is int) return value;
        if (value is String) return int.parse(value);
        if (value is num) return value.toInt();
        throw Exception('Cannot parse int from $value');
      }

      return Allergen(
        id: parseInt(json['id']),
        name: parsedName,
        icon: parsedIcon,
      );
    } catch (e) {
      throw Exception('Error parsing Allergen: $e');
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

  String getLocalizedIcon(String locale) {
    // Try exact locale first
    if (icon[locale] != null) return icon[locale]!;

    // For 'ar', try common Arabic variants
    if (locale == 'ar') {
      if (icon['ar-sa'] != null) return icon['ar-sa']!;
      if (icon['ar-SA'] != null) return icon['ar-SA']!;
      if (icon['ar_sa'] != null) return icon['ar_sa']!;
      if (icon['ar_SA'] != null) return icon['ar_SA']!;
    }

    // Fall back to English
    return icon['en-us'] ?? icon['en-US'] ?? icon['en'] ?? '';
  }
}
