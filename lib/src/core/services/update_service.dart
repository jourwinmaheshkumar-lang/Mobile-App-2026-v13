import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import '../models/version_info.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<OtaEvent>? _updateStream;
  
  Future<VersionInfo?> getLatestVersion() async {
    try {
      final doc = await _firestore.collection('app_config').doc('version').get();
      if (!doc.exists) return null;
      return VersionInfo.fromDoc(doc);
    } catch (e) {
      print('Error fetching version info: $e');
      return null;
    }
  }

  Future<bool> isUpdateAvailable() async {
    final latest = await getLatestVersion();
    if (latest == null) return false;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    // Compare versions (simplified for demo, usually use a proper semver compare)
    if (_isVersionGreater(latest.latestVersion, currentVersion)) {
      return true;
    }
    
    // If version is same, check build number
    if (latest.latestVersion == currentVersion && latest.buildNumber > currentBuild) {
      return true;
    }

    return false;
  }

  bool _isVersionGreater(String latest, String current) {
    List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (var i = 0; i < latestParts.length && i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return latestParts.length > currentParts.length;
  }

  Stream<OtaEvent> downloadAndInstall(String url) {
    try {
      // url should be the direct link to the APK
      return OtaUpdate().execute(
        url,
        destinationFilename: 'director_hub_update.apk',
      );
    } catch (e) {
      print('OTA Update failed: $e');
      rethrow;
    }
  }

  Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }
}

final updateService = UpdateService();
