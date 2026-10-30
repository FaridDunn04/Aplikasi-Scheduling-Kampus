import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../state/app_state_manager.dart';
import 'widgets/next_class_card.dart';
import 'widgets/today_courses_section.dart';
import 'widgets/urgent_tasks_section.dart';
import 'dialogs/settings_dialog.dart';
import '../main_navigation_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final datePillText = DateFormat('EEE, MMM d').format(now);

    return ListenableBuilder(
      listenable: AppStateManager.instance,
      builder: (context, _) {
        final state = AppStateManager.instance;
        final nextClass = state.getNextClass();
        final todayCourses = state.getCoursesForDay(now.weekday);
        final urgentTasks = state.getUrgentTasks(limit: 5);

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FD),
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: const Color(0xFF2563EB),
              backgroundColor: Colors.white,
              onRefresh: () async {
                await state.refresh();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                children: [
                  // Row 1: Brand Header "SyncClass" & Settings Gear Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Sync',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Class',
                                  style: TextStyle(
                                    color: Color(0xFF4F46E5),
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Plan Better. Study Smarter.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Settings Gear Button
                      InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => const SettingsDialog(),
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF64748B).withAlpha(20),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: Color(0xFF475569),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Row 2: Greeting & Date Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Student 👋',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Keep going, your progress matters!',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      // Date Pill
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => MainNavigationScreen.switchTab(1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF64748B).withAlpha(18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF64748B),
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                datePillText,
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. Featured Card: Upcoming Next
                  NextClassCard(nextCourse: nextClass),
                  const SizedBox(height: 24),

                  // 2. Today's Flow Section
                  TodayCoursesSection(todayCourses: todayCourses),
                  const SizedBox(height: 24),

                  // 3. Urgent Tasks Section
                  UrgentTasksSection(urgentTasks: urgentTasks),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
