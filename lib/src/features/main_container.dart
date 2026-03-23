import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/services/localization_service.dart';
import '../core/services/auth_service.dart';
import '../core/models/user.dart';
import 'dashboard/dashboard_screen.dart';
import 'directors/director_list_screen.dart';
import 'directors/director_profile_screen.dart';
import 'reports/report_list_screen.dart';
import 'settings/settings_screen.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    localizationService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    localizationService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  List<_NavItem> _getNavItems(AppUser? user) {
    if (user?.role == UserRole.director) {
      return [
        _NavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: localizationService.tr('profile'),
        ),
        _NavItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          label: localizationService.tr('settings'),
        ),
      ];
    }

    return [
      _NavItem(
        icon: Icons.grid_view_rounded,
        activeIcon: Icons.grid_view_rounded,
        label: localizationService.tr('dashboard'),
      ),
       _NavItem(
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        label: localizationService.tr('directors'),
      ),
      _NavItem(
        icon: Icons.analytics_outlined,
        activeIcon: Icons.analytics_rounded,
        label: localizationService.tr('reports'),
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: localizationService.tr('settings'),
      ),
    ];
  }

  List<Widget> _getScreens(AppUser? user) {
    if (user?.role == UserRole.director) {
      return [
        const DirectorProfileScreen(),
        const SettingsScreen(),
      ];
    }

    return [
      DashboardScreen(onNavigate: (index) => _onTabTapped(index)),
      const DirectorListScreen(),
      const ReportListScreen(),
      const SettingsScreen(),
    ];
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final navItems = _getNavItems(user);
        final screens = _getScreens(user);

        // Reset index if it's out of bounds for the current role
        if (_currentIndex >= navItems.length) {
          _currentIndex = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _pageController.jumpToPage(0);
          });
        }

        return Scaffold(
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentIndex = index),
            children: screens,
          ),
          bottomNavigationBar: _buildBottomNavBar(navItems),
        );
      }
    );
  }

  Widget _buildBottomNavBar(List<_NavItem> navItems) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              navItems.length,
              (index) => _buildNavItem(navItems[index], index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, int index) {
    final isSelected = index == _currentIndex;
    const inactiveColor = Color(0xFFBDBDBD);
    const accentColor = AppTheme.primary;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabTapped(index),
          splashColor: accentColor.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                size: 24,
                color: isSelected ? accentColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? accentColor : inactiveColor,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
