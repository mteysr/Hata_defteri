import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Screens
import '../../features/dashboard/presentation/views/dashboard_screen.dart';
import '../../features/mistakes/presentation/views/mistake_list_screen.dart';
import '../../features/mistakes/presentation/views/mistake_detail_screen.dart';
import '../../features/mistakes/presentation/views/add_edit_mistake_screen.dart';
import '../../features/review/presentation/views/review_screen.dart';
import '../../features/statistics/presentation/views/statistics_screen.dart';
import '../../features/settings/presentation/views/settings_screen.dart';
import '../../features/academy/presentation/views/academy_dashboard_screen.dart';
import '../../features/academy/presentation/views/academy_quiz_screen.dart';
import '../../features/academy/presentation/views/academy_result_screen.dart';
import '../../features/academy/presentation/views/academy_notes_screen.dart';
import '../../features/academy/presentation/views/academy_notes_viewer_screen.dart';
import '../../features/academy/presentation/views/academy_topic_tracker_screen.dart';
import '../../features/academy/domain/models/academy_note_booklet.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/mistakes',
            builder: (context, state) => const MistakeListScreen(),
          ),
          GoRoute(
            path: '/academy',
            builder: (context, state) => const AcademyDashboardScreen(),
          ),
          GoRoute(
            path: '/review',
            builder: (context, state) => const ReviewScreen(),
          ),
          GoRoute(
            path: '/statistics',
            builder: (context, state) => const StatisticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/add-mistake',
        builder: (context, state) {
          final mistakeId = state.extra as String?;
          return AddEditMistakeScreen(mistakeId: mistakeId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/mistake-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MistakeDetailScreen(mistakeId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/academy-quiz',
        builder: (context, state) {
          final mode = state.extra as String? ?? 'daily';
          return AcademyQuizScreen(mode: mode);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/academy-result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AcademyResultScreen(
            total: extra['total'] as int,
            correct: extra['correct'] as int,
            incorrect: extra['incorrect'] as int,
            categoryStats: extra['categoryStats'] as Map<String, double>,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/academy-notes',
        builder: (context, state) => const AcademyNotesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/academy-notes-viewer',
        builder: (context, state) {
          final booklet = state.extra as AcademyNoteBooklet;
          return AcademyNotesViewerScreen(booklet: booklet);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/academy-topic-tracker',
        builder: (context, state) => const AcademyTopicTrackerScreen(),
      ),
    ],
  );
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    int calculateSelectedIndex() {
      if (location == '/') return 0;
      if (location.startsWith('/mistakes')) return 1;
      if (location.startsWith('/academy')) return 2;
      if (location.startsWith('/review')) return 3;
      if (location.startsWith('/statistics')) return 4;
      if (location.startsWith('/settings')) return 5;
      return 0;
    }

    void onItemTapped(int index) {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/mistakes');
          break;
        case 2:
          context.go('/academy');
          break;
        case 3:
          context.go('/review');
          break;
        case 4:
          context.go('/statistics');
          break;
        case 5:
          context.go('/settings');
          break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: calculateSelectedIndex(),
        onDestinationSelected: onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Yanlışlarım',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Akademi',
          ),
          NavigationDestination(
            icon: Icon(Icons.replay_outlined),
            selectedIcon: Icon(Icons.replay),
            label: 'Tekrarlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'İstatistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
