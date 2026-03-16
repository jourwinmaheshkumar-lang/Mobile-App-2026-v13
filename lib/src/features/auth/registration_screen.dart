import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/services/localization_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user.dart';
import '../../core/models/director.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with TickerProviderStateMixin {
  final _mobileController = TextEditingController();
  final _dinController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  
  int _currentStep = 0; 
  bool _loading = false;
  String? _error;
  Director? _detectedDirector;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _mobileController.dispose();
    _dinController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _changeStep(int newStep) async {
    await _fadeController.reverse();
    setState(() {
      _currentStep = newStep;
      _error = null;
    });
    _fadeController.forward();
  }

  void _nextStep() async {
    if (_loading) return;
    HapticFeedback.mediumImpact();

    if (_currentStep == 0) {
      if (_mobileController.text.isEmpty || _dinController.text.isEmpty) {
        setState(() => _error = 'Please enter both Mobile and DIN');
        return;
      }
      
      setState(() => _loading = true);
      // Passing BOTH values to the service for a combined robust search
      final director = await _authService.findDirectorByMobile(
        _mobileController.text, 
        _dinController.text
      );
      
      if (director != null) {
        _detectedDirector = director;
        setState(() => _loading = false);
        _changeStep(1);
      } else {
        setState(() {
          _error = 'Record not found. Please check your details.';
          _loading = false;
        });
      }
    } else if (_currentStep == 1) {
      if (_otpController.text == '123456') {
        _changeStep(2);
      } else {
        setState(() => _error = 'Invalid verification code');
      }
    } else if (_currentStep == 2) {
      if (_passwordController.text.length < 6) {
        setState(() => _error = 'Password must be at least 6 characters');
        return;
      }

      setState(() => _loading = true);
      try {
        await _authService.register(
          mobile: _mobileController.text,
          din: _dinController.text,
          password: _passwordController.text,
          role: UserRole.director,
          directorId: _detectedDirector!.id,
          name: _detectedDirector!.name,
        );
        if (mounted) {
          _showSuccessSheet();
        }
      } catch (e) {
        setState(() {
          _error = 'Registration failed: ${e.toString()}';
          _loading = false;
        });
      }
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Account Created!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Your Director account is now active.'),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.pop(context); // Close registration
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF),
      body: Stack(
        children: [
          // Background Decorations
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(height: 12),
                        
                        // Header
                        Text(
                          _getStepTitle(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStepSubtitle(),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : AppTheme.textTertiary,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Progress Indicator
                        _buildProgressDots(),
                        
                        const SizedBox(height: 16),
                        
                        // Form Card
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                if (_error != null) _buildErrorLabel(),
                                if (_currentStep == 0) _buildStep0(),
                                if (_currentStep == 1) _buildStep1(),
                                if (_currentStep == 2) _buildStep2(),
                              ],
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        const SizedBox(height: 16),
                        
                        // Action Button
                        GestureDetector(
                          onTap: _nextStep,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _loading
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : Text(
                                      _currentStep == 2 ? 'CREATE ACCOUNT' : 'CONTINUE',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Verify Details';
      case 1: return 'Verification';
      case 2: return 'Secure Account';
      default: return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0: return 'Enter your registered mobile linked with Aadhaar.';
      case 1: return 'A 6-digit code has been sent to your mobile.';
      case 2: return 'Create a strong password for your hub access.';
      default: return '';
    }
  }

  Widget _buildProgressDots() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF6366F1) : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _error!,
        style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      children: [
        _buildTextField(
          controller: _mobileController,
          label: 'Mobile Number',
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _dinController,
          label: 'DIN Number',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
         _buildTextField(
          controller: _otpController,
          label: 'OTP Code',
          icon: Icons.sms_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 12),
        const Text('Use 123456 for testing', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline, size: 20, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Text(
              'Welcome, ${_detectedDirector?.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _passwordController,
          label: 'New Password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            maxLength: maxLength,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
