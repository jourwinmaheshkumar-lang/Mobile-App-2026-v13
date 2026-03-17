import 'package:mantra_mfs100/mantra_mfs100.dart';
import '../models/director.dart';
import '../repositories/director_repository.dart';
import 'dart:convert';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final MantraMfs100 _mfs100 = MantraMfs100();
  final DirectorRepository _directorRepo = DirectorRepository();

  /// Initialize the device. Returns true if successful.
  Future<bool> initialize() async {
    try {
      final res = await _mfs100.initialize();
      return res == 0; // 0 usually means success in these SDKs
    } catch (e) {
      print('Biometric Init Error: $e');
      return false;
    }
  }

  /// Capture a fingerprint and return the ISO template as a string.
  Future<String?> captureTemplate() async {
    try {
      final res = await _mfs100.capture();
      if (res != null && res.isoTemplate != null) {
        // Store as Base64 for easy database storage
        return base64Encode(res.isoTemplate!);
      }
      return null;
    } catch (e) {
      print('Biometric Capture Error: $e');
      return null;
    }
  }

  /// Match a live scan against a stored template.
  Future<bool> verifyMatch(String storedTemplateBase64) async {
    try {
      final liveRes = await _mfs100.capture();
      if (liveRes == null || liveRes.isoTemplate == null) return false;

      final storedTemplate = base64Decode(storedTemplateBase64);
      final matchScore = await _mfs100.matchISO(liveRes.isoTemplate!, storedTemplate);
      
      // Typical threshold for matching is 14000+ or a specific score depending on SDK
      return (matchScore ?? 0) > 14000;
    } catch (e) {
      print('Biometric Match Error: $e');
      return false;
    }
  }

  /// Search for a director by scanning their finger (1:N Identification).
  Future<Director?> identifyDirector() async {
    try {
      final liveRes = await _mfs100.capture();
      if (liveRes == null || liveRes.isoTemplate == null) return null;

      final allDirectors = _directorRepo.all.where((d) => d.fingerprintTemplate != null).toList();
      
      for (var director in allDirectors) {
        final storedTemplate = base64Decode(director.fingerprintTemplate!);
        final matchScore = await _mfs100.matchISO(liveRes.isoTemplate!, storedTemplate);
        if ((matchScore ?? 0) > 14000) {
          return director;
        }
      }
      return null;
    } catch (e) {
      print('Biometric Identification Error: $e');
      return null;
    }
  }

  /// Stop/Uninitialize the device.
  Future<void> dispose() async {
    await _mfs100.uninitialize();
  }
}

final biometricService = BiometricService();
