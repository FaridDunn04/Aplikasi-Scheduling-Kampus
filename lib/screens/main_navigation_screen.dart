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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF3B82F6).withAlpha(30),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xFF2563EB));
              }
              return IconThemeData(color: Colors.grey.shade400);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
              }
              return TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (int index) {
              MainNavigationScreen.activeTabNotifier.value = index;
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Schedule',
              ),
              NavigationDestination(
                icon: Icon(Icons.check_box_outlined),
                selectedIcon: Icon(Icons.check_box_rounded),
                label: 'Tasks',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
