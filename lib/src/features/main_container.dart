import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: isDark 
            ? Border(top: BorderSide(color: const Color(0xFF334155), width: 1))
            : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : AppTheme.textTertiary;
    final accentColor = isDark ? const Color(0xFF818CF8) : AppTheme.primary;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabTapped(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 22,
                  color: isSelected ? accentColor : inactiveColor,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? accentColor : inactiveColor,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
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
