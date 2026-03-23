import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ClubLevel {
  royal,
  diamond,
  platinum,
  gold,
}

extension ClubLevelExtension on ClubLevel {
  String get id {
    switch (this) {
      case ClubLevel.royal:
        return 'royal';
      case ClubLevel.diamond:
        return 'diamond';
      case ClubLevel.platinum:
        return 'platinum';
      case ClubLevel.gold:
        return 'gold';
    }
  }

  String get displayName {
    switch (this) {
      case ClubLevel.royal:
        return 'ROYAL CLUB';
      case ClubLevel.diamond:
        return 'DIAMOND CLUB';
      case ClubLevel.platinum:
        return 'PLATINUM CLUB';
      case ClubLevel.gold:
        return 'GOLD CLUB';
    }
  }

  String get displayNameTamil {
    switch (this) {
      case ClubLevel.royal:
        return 'ROYAL CLUB POSITION (முதல்நிலை)';
      case ClubLevel.diamond:
        return 'DIAMOND CLUB POSITION (இரண்டாம் நிலை)';
      case ClubLevel.platinum:
        return 'PLATINUM CLUB POSITION (மூன்றாம் நிலை)';
      case ClubLevel.gold:
        return 'GOLD CLUB POSITION (நான்காவது நிலை)';
    }
  }

  List<Color> get gradient {
    switch (this) {
      case ClubLevel.royal:
        return [const Color(0xFFEF4444), const Color(0xFFB91C1C)];
      case ClubLevel.diamond:
        return [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
      case ClubLevel.platinum:
        return [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)];
      case ClubLevel.gold:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
    }
  }
}

class ClubMember {
  final String id;
  final String directorId;
  final String directorName;
  final ClubLevel level;
  final DateTime joinedAt;
  final int order;

  ClubMember({
    required this.id,
    required this.directorId,
    required this.directorName,
    required this.level,
    required this.joinedAt,
    this.order = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'directorId': directorId,
      'directorName': directorName,
      'level': level.id,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'order': order,
    };
  }

  factory ClubMember.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClubMember(
      id: doc.id,
      directorId: data['directorId'] ?? '',
      directorName: data['directorName'] ?? '',
      level: ClubLevel.values.firstWhere(
        (e) => e.id == data['level'],
        orElse: () => ClubLevel.gold,
      ),
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      order: data['order'] ?? 0,
    );
  }
}
