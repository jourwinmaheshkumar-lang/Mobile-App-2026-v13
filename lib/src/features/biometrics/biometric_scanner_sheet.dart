import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/services/biometric_service.dart';
import '../../core/models/director.dart';

enum BiometricMode { enroll, identify }

class BiometricScannerSheet extends StatefulWidget {
  final BiometricMode mode;
  final Function(String template)? onEnrolled;
  final Function(Director director)? onIdentified;

  const BiometricScannerSheet({
    super.key,
    required this.mode,
    this.onEnrolled,
    this.onIdentified,
  });

  @override
  State<BiometricScannerSheet> createState() => _BiometricScannerSheetState();
}

class _BiometricScannerSheetState extends State<BiometricScannerSheet> with SingleTickerProviderStateMixin {
  bool _isInitializing = true;
  bool _isDeviceConnected = false;
  bool _isScanning = false;
  String? _statusMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initDevice();
  }

  Future<void> _initDevice() async {
    setState(() {
      _isInitializing = true;
      _statusMessage = 'Connecting to Mantra device...';
    });

    final success = await biometricService.initialize();
    
    if (mounted) {
      setState(() {
        _isInitializing = false;
        _isDeviceConnected = success;
        _statusMessage = success ? 'Device Connected. Ready to Scan.' : 'Device not found. Please check OTG connection.';
      });
    }
  }

  Future<void> _startScan() async {
    if (!_isDeviceConnected) return;

    setState(() {
      _isScanning = true;
      _statusMessage = 'Place your finger on the scanner...';
    });

    try {
      if (widget.mode == BiometricMode.enroll) {
        final template = await biometricService.captureTemplate();
        if (template != null) {
          HapticFeedback.heavyImpact();
          widget.onEnrolled?.call(template);
          if (mounted) Navigator.pop(context);
        } else {
          setState(() => _statusMessage = 'Fingerprint capture failed. Try again.');
        }
      } else {
        final director = await biometricService.identifyDirector();
        if (director != null) {
          HapticFeedback.heavyImpact();
          widget.onIdentified?.call(director);
          if (mounted) Navigator.pop(context);
        } else {
          setState(() => _statusMessage = 'No matching director found.');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    biometricService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            widget.mode == BiometricMode.enroll ? 'Enroll Fingerprint' : 'Identify by Fingerprint',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          Text(
            _statusMessage ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 48),
          
          // Scanner Visual
          GestureDetector(
            onTap: _isScanning || _isInitializing ? null : _startScan,
            child: ScaleTransition(
              scale: _isScanning ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isDeviceConnected 
                      ? AppTheme.primary.withOpacity(0.1) 
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isDeviceConnected ? AppTheme.primary : (isDark ? Colors.white12 : Colors.black12),
                    width: 3,
                  ),
                  boxShadow: _isScanning ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    )
                  ] : null,
                ),
                child: Center(
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 64,
                    color: _isDeviceConnected ? AppTheme.primary : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          if (!_isDeviceConnected && !_isInitializing)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _initDevice,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Connection'),
              ),
            ),
            
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
