import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/models/company.dart';
import '../../../core/models/director.dart';

class CelebrationCard extends StatefulWidget {
  final Company company;
  final List<Director> directors;

  const CelebrationCard({
    super.key,
    required this.company,
    required this.directors,
  });

  @override
  State<CelebrationCard> createState() => _CelebrationCardState();
}

class _CelebrationCardState extends State<CelebrationCard> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _timeLeft;
  late AnimationController _shineController;

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
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final birth = widget.company.incorporationDateTime;
    if (birth == null) {
      _timeLeft = Duration.zero;
      return;
    }

    DateTime next = DateTime(now.year, birth.month, birth.day);
    if (next.isBefore(now)) {
      next = DateTime(now.year + 1, birth.month, birth.day);
    }
    _timeLeft = next.difference(now);
  }

  @override
  void dispose() {
    _timer.cancel();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Royal Colors
    const royalDark = Color(0xFF0A0A0B);
    const royalGold = Color(0xFFD4AF37); // Metallic Gold
    const softGold = Color(0xFFF9E79F);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: royalGold.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Royal Dark Background with subtle noise/texture
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.5, -0.6),
                    radius: 1.5,
                    colors: [
                      Color(0xFF1C1C1E),
                      royalDark,
                    ],
                  ),
                ),
              ),
            ),

            // Animated Royal Shine
            AnimatedBuilder(
              animation: _shineController,
              builder: (context, child) {
                return Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.transparent,
                          royalGold.withOpacity(0.03),
                          royalGold.withOpacity(0.08),
                          royalGold.withOpacity(0.03),
                          Colors.transparent,
                        ],
                        stops: [
                          0.0,
                          _shineController.value - 0.2,
                          _shineController.value,
                          _shineController.value + 0.2,
                          1.0,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                   Row(
                    children: [
                      _buildRoyalBadge(Icons.stars_rounded, royalGold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.company.companyName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'CORPORATE ANNIVERSARY',
                              style: TextStyle(
                                color: royalGold.withOpacity(0.7),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                  
                  // Countdown Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: royalGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: royalGold.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'CELEBRATION COUNTDOWN',
                      style: TextStyle(
                        color: royalGold,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),

                  // Segmented Royal Countdown
                  FittedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimeSegment(_timeLeft.inDays.toString().padLeft(2, '0'), 'DAYS', royalGold),
                        _buildDivider(royalGold),
                        _buildTimeSegment((_timeLeft.inHours % 24).toString().padLeft(2, '0'), 'HRS', royalGold),
                        _buildDivider(royalGold),
                        _buildTimeSegment((_timeLeft.inMinutes % 60).toString().padLeft(2, '0'), 'MINS', royalGold),
                        _buildDivider(royalGold),
                        _buildTimeSegment((_timeLeft.inSeconds % 60).toString().padLeft(2, '0'), 'SECS', royalGold),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom Royal Stats Row
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(child: _buildRoyalStat('DIRECTORS', '${widget.directors.length}', royalGold)),
                        _buildVerticalDivider(),
                        Expanded(child: _buildRoyalStat('ESTD.', widget.company.dateOfIncorporation.split(' ').last, royalGold)),
                        _buildVerticalDivider(),
                        Expanded(child: _buildRoyalStat('MILESTONE', '${widget.company.age + 1}nd YR', royalGold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoyalBadge(IconData icon, Color gold) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gold, gold.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.black, size: 24),
    );
  }

  Widget _buildTimeSegment(String value, String label, Color gold) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: gold,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(Color gold) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        ':',
        style: TextStyle(
          color: gold.withOpacity(0.3),
          fontSize: 24,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildRoyalStat(String label, String value, Color gold) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: gold,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withOpacity(0.1),
    );
  }
}
