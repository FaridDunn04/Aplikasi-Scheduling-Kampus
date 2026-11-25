import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'schedule/schedule_screen.dart';
import 'task/task_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  static final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);

  const MainNavigationScreen({super.key});

  static void switchTab(int index) {
    activeTabNotifier.value = index;
  }

  static void showAllTasks() {
    TaskScreen.requestShowAllTasks();
    switchTab(2);
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final List<Widget> _screens = const [
    HomeScreen(),
    ScheduleScreen(),
    TaskScreen(),
  ];

  static const List<_NavItemData> _navItems = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItemData(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Schedule',
    ),
    _NavItemData(
      icon: Icons.check_box_outlined,
      activeIcon: Icons.check_box_rounded,
      label: 'Tasks',
    ),
  ];

  @override
  void initState() {
    super.initState();
    MainNavigationScreen.activeTabNotifier.addListener(_onTabChange);
  }

  @override
  void dispose() {
    MainNavigationScreen.activeTabNotifier.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = MainNavigationScreen.activeTabNotifier.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FD),
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: _CurvedPopUpNavBar(
        currentIndex: currentIndex,
        items: _navItems,
        onTap: (int index) {
          MainNavigationScreen.activeTabNotifier.value = index;
        },
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _CurvedPopUpNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItemData> items;
  final ValueChanged<int> onTap;

  const _CurvedPopUpNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  static const Color _barColor = Color(0xFF2563EB);
  static const double _barHeight = 66.0;
  static const double _popUpHeight = 26.0;
  static const double _circleSize = 52.0;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding > 0 ? bottomPadding : 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = width / items.length;
          final totalHeight = _barHeight + _popUpHeight;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: currentIndex.toDouble()),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, animatedIndex, _) {
              final activeCenterX = (animatedIndex + 0.5) * itemWidth;

              return SizedBox(
                height: totalHeight,
                width: width,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Blue Curved Bar with Concave Notch
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CurvedNotchPainter(
                          centerX: activeCenterX,
                          topOffset: _popUpHeight,
                          barColor: _barColor,
                        ),
                      ),
                    ),

                    // 2. Floating Pop-Up Active Circle
                    Positioned(
                      left: activeCenterX - (_circleSize / 2),
                      top: 0,
                      width: _circleSize,
                      height: _circleSize,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _barColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _barColor.withAlpha(85),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) => ScaleTransition(
                              scale: anim,
                              child: child,
                            ),
                            child: Icon(
                              items[currentIndex].activeIcon,
                              key: ValueKey<int>(currentIndex),
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. Tab Hitboxes, Inactive Icons & Labels
                    Positioned(
                      left: 0,
                      right: 0,
                      top: _popUpHeight,
                      bottom: 0,
                      child: Row(
                        children: List.generate(items.length, (index) {
                          final item = items[index];
                          final isSelected = index == currentIndex;

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onTap(index),
                              child: Column(
                                mainAxisAlignment: isSelected
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.center,
                                children: [
                                  if (!isSelected) ...[
                                    Icon(
                                      item.icon,
                                      color: Colors.white.withAlpha(215),
                                      size: 23,
                                    ),
                                    const SizedBox(height: 3),
                                  ],
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: isSelected ? 9.0 : 0.0,
                                    ),
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withAlpha(215),
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: isSelected ? 12 : 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CurvedNotchPainter extends CustomPainter {
  final double centerX;
  final double topOffset;
  final Color barColor;

  _CurvedNotchPainter({
    required this.centerX,
    required this.topOffset,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final topY = topOffset;

    const double bottomR = 24.0;
    const double topR = 20.0;
    const double notchHalfWidth = 42.0;
    const double notchDepth = 34.0;

    final notchStartX = math.max(4.0, centerX - notchHalfWidth);
    final notchEndX = math.min(w - 4.0, centerX + notchHalfWidth);
    final leftCornerR = math.min(topR, math.max(0.0, notchStartX));
    final rightCornerR = math.min(topR, math.max(0.0, w - notchEndX));

    final path = Path()
      // Start from bottom-left above corner
      ..moveTo(0, h - bottomR)
      ..quadraticBezierTo(0, h, bottomR, h)
      // Bottom edge
      ..lineTo(w - bottomR, h)
      ..quadraticBezierTo(w, h, w, h - bottomR)
      // Right edge up to top-right corner
      ..lineTo(w, topY + rightCornerR)
      ..quadraticBezierTo(w, topY, w - rightCornerR, topY)
      // Top-right straight edge to notch start
      ..lineTo(notchEndX, topY)
      // Smooth concave curve down to notch center
      ..cubicTo(
        centerX + notchHalfWidth * 0.52,
        topY,
        centerX + notchHalfWidth * 0.56,
        topY + notchDepth,
        centerX,
        topY + notchDepth,
      )
      // Smooth concave curve back up from notch center
      ..cubicTo(
        centerX - notchHalfWidth * 0.56,
        topY + notchDepth,
        centerX - notchHalfWidth * 0.52,
        topY,
        notchStartX,
        topY,
      )
      // Top-left straight edge to top-left corner
      ..lineTo(leftCornerR, topY)
      ..quadraticBezierTo(0, topY, 0, topY + leftCornerR)
      ..close();

    // Subtle elevation shadow under the blue navbar
    canvas.drawShadow(
      path,
      const Color(0xFF1E3A8A).withAlpha(65),
      10.0,
      false,
    );

    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedNotchPainter oldDelegate) {
    return oldDelegate.centerX != centerX ||
        oldDelegate.topOffset != topOffset ||
        oldDelegate.barColor != barColor;
  }
}
