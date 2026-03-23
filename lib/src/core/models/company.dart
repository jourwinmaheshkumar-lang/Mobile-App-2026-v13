import 'package:intl/intl.dart';

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

  DateTime? get incorporationDateTime {
    try {
      return DateFormat('d MMMM yyyy').parse(dateOfIncorporation);
    } catch (e) {
      return null;
    }
  }

  String get formattedIncorporationDate {
    final date = incorporationDateTime;
    if (date == null) return dateOfIncorporation;
    return DateFormat('dd MMM yyyy').format(date).toUpperCase();
  }

  int get age {
    final date = incorporationDateTime;
    if (date == null) return 0;
    final now = DateTime.now();
    int age = now.year - date.year;
    if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
      age--;
    }
    return age;
  }

  bool get isBirthdayThisMonth {
    final date = incorporationDateTime;
    if (date == null) return false;
    return DateTime.now().month == date.month;
  }

  bool get isAnniversaryToday {
    final date = incorporationDateTime;
    if (date == null) return false;
    final now = DateTime.now();
    return now.day == date.day && now.month == date.month;
  }

  bool get isAnniversaryTomorrow {
    final date = incorporationDateTime;
    if (date == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return tomorrow.day == date.day && tomorrow.month == date.month;
  }

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
