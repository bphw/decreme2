class Cake {
  final int id;
  final String name;
  final String variant;
  final double price;
  final String? images;
  final String? description;
  final bool? isAvailable;
  final String cakeTypes;
  final DateTime? createdAt;

  Cake({
    required this.id,
    required this.name,
    required this.variant,
    required this.price,
    this.images,
    this.description,
    this.isAvailable,
    required this.cakeTypes,
    this.createdAt,
  });

  factory Cake.fromJson(Map<String, dynamic> json) {
    return Cake(
      id: json['id'] as int,
      name: json['name'] as String,
      variant: json['variant'] as String,
      price: (json['price'] as num).toDouble(),
      images: json['images'] as String?,
      description: json['description'] as String?,
      isAvailable: json['is_available'] as bool?,
      cakeTypes: json['cake_types'] as String,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'variant': variant,
      'price': price,
      'images': images,
      'description': description,
      'is_available': isAvailable,
      'cake_types': cakeTypes,
      'created_at': createdAt?.toIso8601String(),
    };
  }
} 