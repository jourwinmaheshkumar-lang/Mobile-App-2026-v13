import 'package:flutter/material.dart';

class CompanyDetail {
  final String companyName;
  final String designation;
  final String appointmentDate;

  CompanyDetail({
    required this.companyName,
    required this.designation,
    required this.appointmentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'designation': designation,
      'appointmentDate': appointmentDate,
    };
  }

  factory CompanyDetail.fromMap(Map<String, dynamic> map) {
    return CompanyDetail(
      companyName: map['companyName'] ?? map['Company'] ?? '',
      designation: map['designation'] ?? map['Designation'] ?? '',
      appointmentDate: map['appointmentDate'] ?? map['Appointment'] ?? '',
    );
  }
}

class Director {
  final String id;
  final int serialNo;
  final String name;
  final String din;
  final String email;
  final String status;
  final String aadhaarAddress;
  final String residentialAddress;
  final String aadhaarNumber;
  final String pan;
  
  // IDBI Account Details (multi-line string)
  final String idbiAccountDetails;
  
  // eMudhra Account Details (multi-line string)
  final String emudhraAccountDetails;
  
  // Phone Numbers
  final String bankLinkedPhone;
  final String aadhaarPanLinkedPhone;
  final String emailLinkedPhone;
  
  // Soft delete fields
  final bool isRemoved;
  final DateTime? removedAt;

  // New fields for multiple companies
  final List<CompanyDetail> companies;

  Director({
    required this.id,
    this.serialNo = 0,
    required this.name,
    String din = '',
    this.email = '',
    this.status = 'Active',
    this.aadhaarAddress = '',
    this.residentialAddress = '',
    this.aadhaarNumber = '',
    this.pan = '',
    this.idbiAccountDetails = '',
    this.emudhraAccountDetails = '',
    this.bankLinkedPhone = '',
    this.aadhaarPanLinkedPhone = '',
    this.emailLinkedPhone = '',
    this.isRemoved = false,
    this.removedAt,
    this.companies = const [],
  }) : din = _padDin(din);

  static String _padDin(String din) {
    final trimmed = din.trim();
    if (trimmed.isEmpty) return '';
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 7) {
      return '0$digitsOnly';
    }
    return trimmed;
  }

  // Check if DIN is missing or is a proposal
  // DIN is valid if it's an 8 digit number
  bool get hasNoDin {
    if (din.isEmpty) return true;
    
    final dinLower = din.toLowerCase().trim();
    if (dinLower == 'proposal' || dinLower == 'proposed' || dinLower.contains('proposal')) {
      return true;
    }
    
    // Check if DIN is a valid 8 digit number
    final digitsOnly = din.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.length != 8;
  }

  // Get formatted DIN for display
  String get displayDin {
    if (hasNoDin) return '';
    return din;
  }

  bool get hasAddressMismatch {
    if (aadhaarAddress.isEmpty || residentialAddress.isEmpty) return false;
    // Normalize addresses for comparison (case-sensitive as requested)
    final normalizedAadhaar = aadhaarAddress.replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalizedResidential = residentialAddress.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalizedAadhaar != normalizedResidential;
  }

  Director copyWith({
    int? serialNo,
    String? name,
    String? din,
    String? email,
    String? status,
    String? aadhaarAddress,
    String? residentialAddress,
    String? aadhaarNumber,
    String? pan,
    String? idbiAccountDetails,
    String? emudhraAccountDetails,
    String? bankLinkedPhone,
    String? aadhaarPanLinkedPhone,
    String? emailLinkedPhone,
    bool? isRemoved,
    DateTime? removedAt,
    List<CompanyDetail>? companies,
  }) {
    return Director(
      id: id,
      serialNo: serialNo ?? this.serialNo,
      name: name ?? this.name,
      din: din ?? this.din,
      email: email ?? this.email,
      status: status ?? this.status,
      aadhaarAddress: aadhaarAddress ?? this.aadhaarAddress,
      residentialAddress: residentialAddress ?? this.residentialAddress,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      pan: pan ?? this.pan,
      idbiAccountDetails: idbiAccountDetails ?? this.idbiAccountDetails,
      emudhraAccountDetails: emudhraAccountDetails ?? this.emudhraAccountDetails,
      bankLinkedPhone: bankLinkedPhone ?? this.bankLinkedPhone,
      aadhaarPanLinkedPhone: aadhaarPanLinkedPhone ?? this.aadhaarPanLinkedPhone,
      emailLinkedPhone: emailLinkedPhone ?? this.emailLinkedPhone,
      isRemoved: isRemoved ?? this.isRemoved,
      removedAt: removedAt ?? this.removedAt,
      companies: companies ?? this.companies,
    );
  }
}

