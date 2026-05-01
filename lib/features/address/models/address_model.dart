class AddressModel {
  final String? id;
  final String? userId;
  final String label;
  final String houseNo;
  final String street;
  final String area;
  final String city;
  final String pincode;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  AddressModel({
    this.id,
    this.userId,
    this.label = 'Home',
    required this.houseNo,
    required this.street,
    required this.area,
    this.city = 'Surat',
    required this.pincode,
    this.landmark,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: (json['address_id'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      label: json['type'] ?? json['label'] ?? 'Home',
      houseNo: json['house'] ?? json['house_no'] ?? json['houseNo'] ?? '',
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? 'Surat',
      pincode: json['pincode'] ?? '',
      landmark: json['landmark']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      isDefault: json['is_default'] ?? json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'label': label,
      'house_no': houseNo,
      'street': street,
      'area': area,
      'city': city,
      'pincode': pincode,
      if (landmark != null) 'landmark': landmark,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_default': isDefault,
    };
  }

  String get fullAddress => "$houseNo, $street, $area, $city - $pincode";
  
  String get shortAddress => "$houseNo, $street, $area";
}
