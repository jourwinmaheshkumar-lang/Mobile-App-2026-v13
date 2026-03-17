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

  /// Capture a fingerprint and return the PidData XML string.
  Future<String?> captureRawResponse() async {
    try {
      final pidData = await Msf100.capture();
      if (pidData != null && pidData.pidData != null) {
        return pidData.pidData;
      }
      return null;
    } catch (e) {
      debugPrint('Biometric Identification Error: $e');
      return null;
    }
  }

  /// Extracts the biometric template or unique hash from the RD Service response.
  String? _getTemplateFromXml(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final dataElement = document.findAllElements('Data').firstOrNull;
      if (dataElement != null) {
        return dataElement.innerText; // This is the encrypted PID block or template
      }
    } catch (e) {
      debugPrint('XML Parse Error: $e');
    }
    return null;
  }

  /// Capture and return a template for enrollment.
  Future<String?> captureTemplate() async {
    final response = await captureRawResponse();
    if (response != null) {
      return _getTemplateFromXml(response);
    }
    return null;
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
