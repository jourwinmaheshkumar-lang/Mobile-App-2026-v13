import 'package:cloud_firestore/cloud_firestore.dart';

class VersionInfo {
  final String latestVersion;
  final int buildNumber;
  final String downloadUrl;
  final String changelog;
  final bool isMandatory;
  final DateTime releasedAt;

  VersionInfo({
    required this.latestVersion,
    required this.buildNumber,
    required this.downloadUrl,
    required this.changelog,
    this.isMandatory = false,
    required this.releasedAt,
  });

  factory VersionInfo.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VersionInfo(
      latestVersion: data['latestVersion'] ?? '1.0.0',
      buildNumber: data['buildNumber'] ?? 0,
      downloadUrl: data['downloadUrl'] ?? '',
      changelog: data['changelog'] ?? 'Regular bug fixes and improvements.',
      isMandatory: data['isMandatory'] ?? false,
      releasedAt: (data['releasedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latestVersion': latestVersion,
      'buildNumber': buildNumber,
      'downloadUrl': downloadUrl,
      'changelog': changelog,
      'isMandatory': isMandatory,
      'releasedAt': Timestamp.fromDate(releasedAt),
    };
  }
}
