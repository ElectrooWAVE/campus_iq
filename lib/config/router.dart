import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/student/home/student_home_screen.dart';
import '../features/student/chatbot/chatbot_screen.dart';
import '../features/student/schedule/schedule_screen.dart';
import '../features/student/notes/notes_screen.dart';
import '../features/student/deadlines/deadlines_screen.dart';
import '../features/student/notifications/notifications_screen.dart';
import '../features/student/announcements/announcements_screen.dart';
import '../features/student/profile/student_profile_screen.dart';
import '../features/admin/home/admin_home_screen.dart';
import '../features/admin/content/admin_content_screen.dart';
import '../features/admin/timetable/timetable_upload_screen.dart';
import '../features/admin/timetable/timetable_edit_screen.dart';
import '../features/admin/notes/notes_upload_screen.dart';
import '../features/admin/notes/notes_edit_screen.dart';
import '../features/admin/announcements/create_announcement_screen.dart';
import '../features/admin/announcements/edit_announcement_screen.dart';
import '../features/admin/deadlines/create_deadline_screen.dart';
import '../features/admin/deadlines/edit_deadline_screen.dart';
import '../features/admin/students/students_screen.dart';
import '../features/admin/analytics/analytics_screen.dart';
import '../features/admin/knowledge_base/knowledge_base_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(BuildContext context) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = auth.isAuthenticated;
      final goingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn && !goingToAuth) return '/login';
      if (isLoggedIn && goingToAuth) {
        return auth.isAdmin ? '/admin/home' : '/student/home';
      }

      // Role guard
      if (isLoggedIn && !auth.isAdmin &&
          state.matchedLocation.startsWith('/admin')) {
        return '/student/home';
      }
      if (isLoggedIn && auth.isAdmin &&
          state.matchedLocation.startsWith('/student')) {
        return '/admin/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),

      // Student routes
      GoRoute(path: '/student/home', builder: (_, __) => const StudentHomeScreen()),
      GoRoute(path: '/student/chat', builder: (_, __) => const ChatbotScreen()),
      GoRoute(path: '/student/schedule', builder: (_, __) => const ScheduleScreen()),
      GoRoute(path: '/student/notes', builder: (_, __) => const NotesScreen()),
      GoRoute(path: '/student/deadlines', builder: (_, __) => const DeadlinesScreen()),
      GoRoute(path: '/student/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/student/profile', builder: (_, __) => const StudentProfileScreen()),
      GoRoute(path: '/student/announcements', builder: (_, __) => const AnnouncementsScreen()),

      // Admin routes
      GoRoute(path: '/admin/home', builder: (_, __) => const AdminHomeScreen()),
      GoRoute(path: '/admin/content', builder: (_, __) => const AdminContentScreen()),
      GoRoute(path: '/admin/timetable/upload', builder: (_, __) => const TimetableUploadScreen()),
      GoRoute(
        path: '/admin/timetable/edit/:id',
        builder: (_, state) => TimetableEditScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/admin/notes/upload', builder: (_, __) => const NotesUploadScreen()),
      GoRoute(
        path: '/admin/notes/edit/:id',
        builder: (_, state) => NotesEditScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/admin/announcements/create', builder: (_, __) => const CreateAnnouncementScreen()),
      GoRoute(
        path: '/admin/announcements/edit/:id',
        builder: (_, state) => EditAnnouncementScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/admin/deadlines/create', builder: (_, __) => const CreateDeadlineScreen()),
      GoRoute(
        path: '/admin/deadlines/edit/:id',
        builder: (_, state) => EditDeadlineScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/admin/students', builder: (_, __) => const StudentsScreen()),
      GoRoute(path: '/admin/analytics', builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: '/admin/knowledge-base', builder: (_, __) => const KnowledgeBaseScreen()),
    ],
  );
}
