import 'package:dashboard_tooapp/src/app/router/admin_router.dart';
import 'package:dashboard_tooapp/src/core/network/api_client.dart';
import 'package:dashboard_tooapp/src/core/session/session_controller.dart';

import '../../support/fake_api.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _TestAdminSession extends AdminSession {
  _TestAdminSession(super.api);
  bool _authenticated = false;

  @override
  bool get isChecking => false;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Future<bool> login(String email, String password) async {
    _authenticated = true;
    notifyListeners();
    return true;
  }

  @override
  Future<void> logout() async {
    _authenticated = false;
    notifyListeners();
  }

  @override
  void expire() {
    _authenticated = false;
    notifyListeners();
  }
}

ApiClient _routerApi() => fakeApiClient((request) {
  if (request.uri.path == '/admin/users') {
    return fakeJsonResponse(
      request,
      apiEnvelope({
        'items': <Object?>[],
        'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0},
      }),
    );
  }
  return fakeJsonResponse(
    request,
    apiError('UNAUTHORIZED', 'Sesión ausente'),
    statusCode: 401,
  );
});

void main() {
  testWidgets('redirects protected routes and clears content after logout', (
    tester,
  ) async {
    final api = _routerApi();
    final session = _TestAdminSession(api);
    final router = createAdminRouter(session);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<AdminSession>.value(value: session),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/users');
    await tester.pumpAndSettle();
    expect(find.text('Administración'), findsOneWidget);
    expect(find.text('Usuarios'), findsNothing);

    expect(await session.login('ada@example.test', 'password123'), isTrue);
    router.go('/users');
    await tester.pumpAndSettle();
    expect(find.text('Usuarios'), findsWidgets);

    await session.logout();
    await tester.pumpAndSettle();
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Usuarios'), findsNothing);

    expect(await session.login('ada@example.test', 'password123'), isTrue);
    router.go('/users');
    await tester.pumpAndSettle();
    session.expire();
    await tester.pumpAndSettle();
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Usuarios'), findsNothing);
    router.dispose();
  });
}
