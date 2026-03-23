class Office {
  final String id;
  final String name;
  final String type; // 'Head Office', 'Corporate Office', 'Branch Office'
  final String location;
  final String? address;
  final String? phone;

  Office({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    this.address,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'location': location,
      'address': address,
      'phone': phone,
    };
  }

  factory Office.fromMap(Map<String, dynamic> map, String id) {
    return Office(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? 'Branch Office',
      location: map['location'] ?? '',
      address: map['address'],
      phone: map['phone'],
    );
  }

  Office copyWith({
    String? name,
    String? type,
    String? location,
    String? address,
    String? phone,
  }) {
    return Office(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      location: location ?? this.location,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }
}
