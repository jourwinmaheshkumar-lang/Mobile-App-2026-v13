import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/models/company.dart';
import '../../../core/models/director.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';

class CelebrationCard extends StatefulWidget {
  final Company company;
  final List<Director> directors;
  final bool isCompact;
  final VoidCallback? onTap;

  const CelebrationCard({
    super.key,
    required this.company,
    required this.directors,
    this.isCompact = false,
    this.onTap,
  });

  @override
  State<CelebrationCard> createState() => _CelebrationCardState();
}

class _CelebrationCardState extends State<CelebrationCard> with TickerProviderStateMixin {
  late Timer _timer;
  late Duration _timeLeft;
  late AnimationController _shineController;
  late AnimationController _pulseController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeLeft();
        });
      }
    });

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  bool _isCelebratingToday = false;
  bool _isTomorrow = false;

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final birth = widget.company.incorporationDateTime;
    if (birth == null) {
      _timeLeft = Duration.zero;
      _isCelebratingToday = false;
      _isTomorrow = false;
      return;
    }

    // Check dates (Today/Tomorrow)
    _isCelebratingToday = now.day == birth.day && now.month == birth.month;
    final tomorrow = now.add(const Duration(days: 1));
    _isTomorrow = tomorrow.day == birth.day && tomorrow.month == birth.month;

    DateTime next = DateTime(now.year, birth.month, birth.day, 0, 0, 0);
    if (now.isAfter(next) && !_isCelebratingToday) {
      next = DateTime(now.year + 1, birth.month, birth.day, 0, 0, 0);
    }
    
    if (_isCelebratingToday) {
      _timeLeft = Duration.zero;
    } else {
      _timeLeft = next.difference(now);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _shineController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Premium Zomato-inspired Color Palette
    final primaryRed = AppTheme.primary;
    final secondaryOrange = const Color(0xFFFF6B35);
    final accentBlue = const Color(0xFF6366F1);
    final accentGold = const Color(0xFFFFD700);
    
    if (widget.isCompact) {
      return _buildUpcomingTile(context);
    }

    final milestone = widget.company.age;
    final suffix = _getOrdinalSuffix(milestone);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFFF6BC59), Color(0xFFE8960A), Color(0xFFFFD700), Color(0xFFF6BC59)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.25),
              blurRadius: 25,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFFF37950).withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.5), // The border thickness
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Company row
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFA425A), Color(0xFFF37950)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.business_rounded, color: Colors.white, size: 20),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.company.companyName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D1B2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "CORPORATE ANNIVERSARY",
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFA425A),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFF9F0F5), height: 1),
            // Anniversary body
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFF8F5),
                    Color(0xFFFFFDF8),
                    Color(0xFFF5FFFE),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Milestone row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF6BC59)),
                      const SizedBox(width: 8),
                      Text(
                        "EXCELLENCE MILESTONE",
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF813563),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF6BC59)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Happy",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF2D1B2E),
                      letterSpacing: 2.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Anniversary number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFF6BC59), Color(0xFFE8960A)],
                        ).createShader(bounds),
                        child: Text(
                          milestone.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFF6BC59), Color(0xFFE8960A)],
                        ).createShader(bounds),
                        child: Text(
                          suffix,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(0, -4),
                    child: Text(
                      "Anniversary",
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D1B2E),
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Quote box
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6BC59).withOpacity(0.10),
                      border: Border.all(color: const Color(0xFFF6BC59).withOpacity(0.30)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "\"Building a legacy of excellence, one year at a time. Congratulations on this remarkable journey of growth and innovation!\"",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF6B4C6B),
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildUpcomingTile(BuildContext context) {
    // Anniversary Milestone
    final milestone = widget.company.age + 1;
    final suffix = _getOrdinalSuffix(milestone);
    
    // Countdown logic for subtitle
    final days = _timeLeft.inDays;
    final daysText = _isTomorrow 
      ? 'Celebrating Tomorrow!' 
      : 'Anniversary in ${days + 1} days';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFA425A), Color(0xFFF37950)]),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.company.companyName,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      daysText,
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.78)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$milestone$suffix Year",
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.70), size: 20),
        ],
      ),
    );
  }

  Widget _buildCompanyIcon(bool isDark) {
    final primaryRed = AppTheme.primary;
    final secondaryOrange = AppTheme.secondary;
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryRed,
            secondaryOrange,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: secondaryOrange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.business_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildCountdownBillboard(bool isDark) {
    final primaryRed = AppTheme.primary;
    final secondaryOrange = AppTheme.secondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 10, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'TIME REMAINING',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModernTimeSeg(_timeLeft.inDays.toString().padLeft(2, '0'), 'DAYS', isDark),
                const SizedBox(width: 16),
                _buildModernTimeSeg((_timeLeft.inHours % 24).toString().padLeft(2, '0'), 'HOURS', isDark),
                const SizedBox(width: 16),
                _buildModernTimeSeg((_timeLeft.inMinutes % 60).toString().padLeft(2, '0'), 'MINS', isDark),
                const SizedBox(width: 16),
                _buildModernTimeSeg((_timeLeft.inSeconds % 60).toString().padLeft(2, '0'), 'SECS', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationBillboard(bool isDark) {
    final primaryRed = AppTheme.primary;
    final secondaryOrange = AppTheme.secondary;
    const goldDeep = Color(0xFF926014); // Dark Bronze/Gold
    const goldMain = Color(0xFFC5A059); // Metallic Gold
    const goldLight = Color(0xFFF1E5AC); // Shimmer Gold
    const goldAccent = Color(0xFFA67C00); // Deep Amber Gold
    
    final milestone = widget.company.age;
    final suffix = _getOrdinalSuffix(milestone);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [
                const Color(0xFF1A1C20),
                const Color(0xFF2C2518), // Warm dark gold tint
                const Color(0xFF1A1C20),
              ]
            : [
                const Color(0xFFFFFFFF),
                const Color(0xFFFFFBEB), // Very soft gold tint
                const Color(0xFFFFFFFF),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: goldMain.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: goldMain.withOpacity(isDark ? 0.15 : 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Elegant Header Ribbon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.auto_awesome_rounded, size: 14, color: goldAccent),
              const SizedBox(width: 10),
              Text(
                'EXCELLENCE MILESTONE',
                style: TextStyle(
                  color: goldAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.auto_awesome_rounded, size: 14, color: goldAccent),
            ],
          ),
          const SizedBox(height: 16),
          
          // Main Title stacked vertically with script font
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Happy',
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF6B7A90), // Dusty blue-grey
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6.0,
                  height: 1.0,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF996B1C), // Deep Bronze
                    Color(0xFFC7A158), // Medium Gold
                    Color(0xFFFDE6AA), // Bright Highlight
                    Color(0xFFCE9E41), // Rich Gold
                    Color(0xFF996B1C), // Deep Bronze
                  ],
                  stops: [0.0, 0.3, 0.5, 0.7, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  '$milestone$suffix',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 68,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    height: 1.1,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -10), // Pull up script text to overlap slightly
                child: Text(
                  'Anniversary',
                  style: TextStyle(
                    fontFamily: 'cursive', // Renders as native script font
                    color: isDark ? Colors.white : const Color(0xFF16243A), // Deep navy
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Quote Container with Glass Effect
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: goldMain.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: goldMain.withOpacity(0.1)),
            ),
            child: Text(
              "\"Building a legacy of excellence, one year at a time. Congratulations on this remarkable journey of growth and innovation!\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF334155),
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                height: 1.6,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTomorrowBillboard(bool isDark) {
    final accentColor = AppTheme.primary;
    final primaryRed = AppTheme.primary;
    final secondaryOrange = AppTheme.secondary;
    final milestone = widget.company.age + 1;
    final suffix = _getOrdinalSuffix(milestone);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm_on_rounded, size: 12, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'CELEBRATION TOMORROW',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'T-MINUS ',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '1 DAY ',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'TO $milestone$suffix',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rocket_launch_rounded, size: 14, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  'GET READY FOR THE BIG DAY!',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'th';
    }
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  Widget _buildModernTimeSeg(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 26,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white24 : Colors.black26,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label, bool isDark, {bool isPrimary = false}) {
    final accentColor = const Color(0xFF6366F1);
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isPrimary 
            ? accentColor 
            : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary 
            ? null 
            : Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 14, 
              color: isPrimary ? Colors.white.withOpacity(0.7) : (isDark ? Colors.white38 : Colors.black38)
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: isPrimary ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white.withOpacity(0.6) : (isDark ? Colors.white24 : Colors.black26),
                fontSize: 6,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingParticle extends StatefulWidget {
  final double size;
  final Duration duration;
  final Color color;
  final bool isDark;

  const _FloatingParticle({
    required this.size,
    required this.duration,
    required this.color,
    required this.isDark,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _top;
  late double _left;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    
    // Seed initial positions based on size/duration to avoid true randomness across rebuilds
    _top = (widget.size * 17) % 200;
    _left = (widget.duration.inSeconds * 42) % 300;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: _top + (30 * _controller.value),
          left: _left + (20 * _controller.value),
          child: Opacity(
            opacity: 0.3 * (1 - _controller.value),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: widget.size % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.size % 3 != 0 ? BorderRadius.circular(4) : null,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

