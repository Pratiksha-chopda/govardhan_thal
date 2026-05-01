class CartItem {
  final String id;       // cart_item_id from DB (String for MongoDB ObjectId)
  final String menuId;   // menu_id (String)
  final String name;
  final double price;
  final String image;    // category string for emoji lookup
  final String category;
  final double gstRate;
  int quantity;

  CartItem({
    required this.id,
    required this.menuId,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    this.gstRate = 5.0,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'menu_id': menuId,
    'name': name,
    'price': price,
    'image': image,
    'category': category,
    'gstRate': gstRate,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: (json['cart_item_id'] ?? json['cart_id'] ?? json['id'] ?? '').toString(),
      menuId: (json['menu_id'] ?? json['menuId'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      image: json['image_url'] ?? json['image'] ?? '',
      category: json['category'] ?? '',
      gstRate: double.tryParse((json['gstRate'] ?? 5).toString()) ?? 5.0,
      quantity: json['quantity'] ?? 1,
    );
  }
}
