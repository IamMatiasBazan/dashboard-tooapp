import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import '../core/session/session_controller.dart';
import '../core/theme/admin_theme.dart';
import 'router/admin_router.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final session = context.read<AdminSession>();
    _router = createAdminRouter(session);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) session.restore();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'TÖÖ Administración',
    debugShowCheckedModeBanner: false,
    theme: AdminTheme.data,
    routerConfig: _router,
  );
}

ApiClient createApiClient() => ApiClient(
  baseUrl: const String.fromEnvironment(
    'TOO_API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  ),
);
