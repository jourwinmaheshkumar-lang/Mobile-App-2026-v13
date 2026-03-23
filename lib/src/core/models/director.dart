import 'package:flutter/material.dart';

class CompanyDetail {
  final String companyName;
  final String designation;
  final String appointmentDate;
  final int boardOrder;

  CompanyDetail({
    required this.companyName,
    required this.designation,
    required this.appointmentDate,
    this.boardOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'designation': designation,
      'appointmentDate': appointmentDate,
      'boardOrder': boardOrder,
    };
  }

  factory CompanyDetail.fromMap(Map<String, dynamic> map) {
    return CompanyDetail(
      companyName: map['companyName'] ?? map['Company'] ?? '',
      designation: map['designation'] ?? map['Designation'] ?? '',
      appointmentDate: map['appointmentDate'] ?? map['Appointment'] ?? '',
      boardOrder: map['boardOrder'] ?? 0,
    );
  }

  CompanyDetail copyWith({
    String? companyName,
    String? designation,
    String? appointmentDate,
    int? boardOrder,
  }) {
    return CompanyDetail(
      companyName: companyName ?? this.companyName,
      designation: designation ?? this.designation,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      boardOrder: boardOrder ?? this.boardOrder,
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

  // Biometric details
  final String? fingerprintTemplate;

  // New fields for multiple companies
  final List<CompanyDetail> companies;

  // New fields for Office & Group Structure
  final String? officeId;
  final String? officeName;
  final String? officePosting;
  final bool isSpecial;
  final String? specialRole; // e.g., 'Chairman', 'Corporate Secretary', etc.

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
    this.fingerprintTemplate,
    this.companies = const [],
    this.officeId,
    this.officeName,
    this.officePosting,
    this.isSpecial = false,
    this.specialRole,
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
    String? fingerprintTemplate,
    List<CompanyDetail>? companies,
    String? officeId,
    String? officeName,
    String? officePosting,
    bool? isSpecial,
    String? specialRole,
    bool clearOffice = false,
    bool clearSpecial = false,
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
      fingerprintTemplate: fingerprintTemplate ?? this.fingerprintTemplate,
      companies: companies ?? this.companies,
      officeId: clearOffice ? null : (officeId ?? this.officeId),
      officeName: clearOffice ? null : (officeName ?? this.officeName),
      officePosting: clearOffice ? null : (officePosting ?? this.officePosting),
      isSpecial: isSpecial ?? (clearSpecial ? false : this.isSpecial),
      specialRole: clearSpecial ? null : (specialRole ?? this.specialRole),
    );
  }
}

