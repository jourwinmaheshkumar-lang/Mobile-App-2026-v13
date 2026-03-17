import 'package:rdservice/rdservice.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import '../models/director.dart';
import '../repositories/director_repository.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final DirectorRepository _directorRepo = DirectorRepository();

  /// Check if the RD Service app is installed and device is ready.
  Future<bool> isServiceAvailable() async {
    try {
      final rdService = await Msf100.getDeviceInfo();
      // RDService model usually has a status or exists if ready
      return rdService != null && rdService.status.toUpperCase() == 'READY';
    } catch (e) {
      debugPrint('RD Service Check Error: $e');
      return false;
    }
  }

  /// Initialize the device. Returns true if successful.
  Future<bool> initialize() async {
    return await isServiceAvailable();
  }

  /// Capture a fingerprint and return the biometric data value.
  Future<String?> captureTemplate() async {
    try {
      final pidData = await Msf100.capture();
      if (pidData != null && pidData.data != null) {
        return pidData.data!.value;
      }
      return null;
    } catch (e) {
      debugPrint('Biometric Capture Error: $e');
      return null;
    }
  }

  /// Match locally.
  Future<bool> verifyMatch(String storedTemplate) async {
    final liveTemplate = await captureTemplate();
    if (liveTemplate == null) return false;
    
    // Exact match for the same capture session (unlikely for L1 every time)
    return liveTemplate == storedTemplate;
  }

  /// Search for a director (1:N Identification).
  Future<Director?> identifyDirector() async {
    final liveTemplate = await captureTemplate();
    if (liveTemplate == null) return null;

    final allDirectors = _directorRepo.all.where((d) => d.fingerprintTemplate != null).toList();
    
    for (var director in allDirectors) {
      if (director.fingerprintTemplate == liveTemplate) {
        return director;
      }
    }
    return null;
  }

  Future<void> dispose() async {
    // rdservice 1.0.0 uses static methods, no explicit dispose usually needed
  }
}

final biometricService = BiometricService();
