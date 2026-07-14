import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';
import 'package:moneyexpenx/views/dashboard/home_view.dart';
import 'package:moneyexpenx/views/saving_jars/saving_jars_screen.dart';
import 'package:moneyexpenx/views/statistics/statistics_screen.dart';
import 'package:moneyexpenx/views/categories/categories_screen.dart';
import 'package:moneyexpenx/views/transactions/add_transaction_screen.dart';
import 'package:moneyexpenx/core/utils/route_transitions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeView(),
    const SavingJarsScreen(),
    const StatisticsScreen(),
    const CategoriesScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background subtle lights
          Positioned(
            bottom: 100,
            left: 50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow.withOpacity(0.03),
              ),
            ),
          ),
          // Selected Page View constrained to end above the navbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 80, // Navbar is bottom 16 + height 64 = 80
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
          ),
          // Floating Glassmorphism Bottom Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GlassContainer(
              height: 64,
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: Colors.black.withOpacity(0.5),
              borderColor: Colors.white.withOpacity(0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Tổng quan',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.savings_outlined,
                    activeIcon: Icons.savings,
                    label: 'Hũ tiết kiệm',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    label: 'Thống kê',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.category_outlined,
                    activeIcon: Icons.category,
                    label: 'Danh mục',
                  ),
                ],
              ),
            ),
          ),
          // Fixed add button positioned above the navbar on the right side
          Positioned(
            right: 28,
            bottom: 92, // Sits exactly on top of the navbar (which is bottom 16 + height 64 = 80)
            child: Hero(
              tag: 'add_transaction_btn',
              child: GlassIconButton(
                icon: Icons.add,
                size: 32,
                iconColor: AppTheme.primaryYellow, // Plus sign changed to gold
                onTap: () {
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      page: const AddTransactionScreen(),
                      direction: AxisDirection.up,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primaryYellow : AppTheme.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            )
          ],
        ),
      ),
    );
  }
}
