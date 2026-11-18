import 'package:go_router/go_router.dart';

import '../../core/session/session_controller.dart';
import '../../features/access/presentation/login_page.dart';
import '../../features/availability/presentation/availability_page.dart';
import '../../features/categories/presentation/categories_page.dart';
import '../../features/accounts/presentation/accounts_page.dart';
import '../../features/contacts/presentation/contacts_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/memberships/presentation/memberships_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/reviews/presentation/reviews_page.dart';
import '../layout/admin_scaffold.dart';

GoRouter createAdminRouter(AdminSession session) => GoRouter(
  initialLocation: '/login',
  refreshListenable: session,
  redirect: (context, state) {
    if (session.isChecking) return null;
    final isLogin = state.matchedLocation == '/login';
    if (!session.isAuthenticated && !isLogin) return '/login';
    if (session.isAuthenticated && isLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    ShellRoute(
      builder: (context, state, child) =>
          AdminScaffold(location: state.matchedLocation, child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/contacts',
          builder: (context, state) => const ContactsPage(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsPage(),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoriesPage(),
        ),
        GoRoute(path: '/accounts', builder: (context, state) => const AccountsPage()),
        GoRoute(
          path: '/reviews',
          builder: (context, state) => const ReviewsPage(),
        ),
        GoRoute(
          path: '/availability',
          builder: (context, state) => const AvailabilityPage(),
        ),
        GoRoute(
          path: '/memberships',
          builder: (context, state) => const MembershipsPage(),
        ),
      ],
    ),
  ],
);
