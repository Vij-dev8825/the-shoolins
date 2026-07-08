class User {
  final String id;
  final String name;
  final String mobile;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? photoBase64;

  User({
    required this.id,
    required this.name,
    required this.mobile,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.photoBase64,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      photoBase64: json['photoBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mobile': mobile,
    'address': address,
    'city': city,
    'state': state,
    'pincode': pincode,
    'photoBase64': photoBase64,
  };
}
