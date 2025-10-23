class Restaurant {
  final String id;
  final String name;
  final String apiUrl;
  final String? imageUrl;
  final String? description;

  Restaurant({
    required this.id,
    required this.name,
    required this.apiUrl,
    this.imageUrl,
    this.description,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      apiUrl: json['apiUrl'] as String,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'apiUrl': apiUrl,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? apiUrl,
    String? imageUrl,
    String? description,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      apiUrl: apiUrl ?? this.apiUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
  }
}
