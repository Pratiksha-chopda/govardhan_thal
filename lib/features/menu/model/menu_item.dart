// Map of curated real food image URLs by category (Unsplash)
const Map<String, String> kCategoryImages = {
  'Thali': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&fit=crop',
  'Farsan': 'https://images.unsplash.com/photo-1567337710282-00832b415979?w=400&fit=crop',
  'Sweets': 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=400&fit=crop',
  'Breads': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400&fit=crop',
  'Drinks': 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&fit=crop',
  'Dal & Rice': 'https://images.unsplash.com/photo-1546549032-9571cd6b27df?w=400&fit=crop',
  'Sabzi': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&fit=crop',
};

class MenuItem {
  final String id;
  final String name;
  final double price;
  final double priceSGD;
  final String image;
  final String category;
  final String description;
  final bool isVeg;
  final double rating;
  final bool isPopular;
  final bool isRecommended;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.priceSGD = 0.0,
    required this.image,
    required this.category,
    required this.description,
    this.isVeg = true,
    this.rating = 4.5,
    this.isPopular = false,
    this.isRecommended = false,
  });

  // Get network image URL (real food photo)
  String get photoUrl {
    if (image.startsWith('http')) return image;
    return kCategoryImages[category] ??
        'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&fit=crop';
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final imgUrl = json['image_url'] ?? json['imageUrl'] ?? '';

    return MenuItem(
      id: (json['menu_id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      priceSGD: double.tryParse(json['priceSGD']?.toString() ?? '') ?? 0.0,
      image: imgUrl,
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      isVeg: json['is_veg'] ?? json['isVeg'] ?? true,
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 4.5,
      isPopular: json['is_popular'] ?? json['isPopular'] ?? false,
      isRecommended: json['is_recommended'] ?? json['isRecommended'] ?? false,
    );
  }
}
