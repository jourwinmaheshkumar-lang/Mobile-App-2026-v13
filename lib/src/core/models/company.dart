class Company {
  final String companyName;
  final String cin;
  final String registrationNumber;
  final String dateOfIncorporation;
  final String address;

  Company({
    required this.companyName,
    required this.cin,
    required this.registrationNumber,
    required this.dateOfIncorporation,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'company_name': companyName,
      'cin': cin,
      'registration_number': registrationNumber,
      'date_of_incorporation': dateOfIncorporation,
      'address': address,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      companyName: map['company_name'] ?? '',
      cin: map['cin'] ?? '',
      registrationNumber: map['registration_number'] ?? '',
      dateOfIncorporation: map['date_of_incorporation'] ?? '',
      address: map['address'] ?? '',
    );
  }
}
