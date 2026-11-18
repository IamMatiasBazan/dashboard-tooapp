import 'package:dashboard_tooapp/src/core/network/api_client.dart';
import 'package:dashboard_tooapp/src/core/session/session_controller.dart';
import 'package:dashboard_tooapp/src/features/accounts/presentation/accounts_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_api.dart';

Map<String, Object?> _account({required String id, required String type}) => {
  'id': id,
  'accountType': type,
  'firstName': type == 'CLIENT' ? 'Ada' : 'Grace',
  'lastName': type == 'CLIENT' ? 'Lovelace' : 'Hopper',
  'email': '$type@example.test',
  'isAccountActive': true,
  'createdAt': '2026-11-01T00:00:00.000Z',
  'locality': {'id': 'locality-1', 'name': 'Moreno'},
  'providerProfile': type == 'CLIENT'
      ? null
      : {
          'id': 'profile-1',
          'primaryCategory': {'id': 'category-1', 'name': 'Electricidad'},
          'isAvailable': true,
        },
};

Future<void> _pumpAccounts(WidgetTester tester, ApiClient api) async {
  tester.view.physicalSize = const Size(1280, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final session = AdminSession(api);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AdminSession>.value(value: session),
      ],
      child: const MaterialApp(home: Scaffold(body: AccountsPage())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows clients and providers together without mutation actions', (
    tester,
  ) async {
    final requests = <RequestOptions>[];
    final api = fakeApiClient((request) {
      requests.add(request);
      if (request.method == 'GET' && request.uri.path == '/admin/accounts') {
        return fakeJsonResponse(request, {
          'data': [
            _account(id: 'client-1', type: 'CLIENT'),
            _account(id: 'provider-1', type: 'PROVIDER'),
          ],
          'total': 2,
          'page': 1,
          'limit': 20,
        });
      }
      if (request.method == 'GET' && request.uri.path == '/localities') {
        return fakeJsonResponse(
          request,
          apiEnvelope([
            {'id': 'locality-1', 'name': 'Moreno'},
          ]),
        );
      }
      if (request.method == 'GET' && request.uri.path == '/admin/categories') {
        return fakeJsonResponse(
          request,
          apiEnvelope([
            {'id': 'category-1', 'name': 'Electricidad'},
          ]),
        );
      }
      throw StateError(
        'Unexpected request: ${request.method} ${request.uri.path}',
      );
    });

    await _pumpAccounts(tester, api);

    expect(find.text('Usuarios y prestadores'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text('Cliente'), findsOneWidget);
    expect(find.text('Prestador'), findsOneWidget);
    expect(find.text('Electricidad'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.text('Editar'), findsNothing);
    expect(find.textContaining('Desactivar'), findsNothing);
    expect(requests.where((request) => request.method != 'GET'), isEmpty);
  });

  testWidgets('paginates over the combined account total', (tester) async {
    final pages = <int>[];
    final api = fakeApiClient((request) {
      if (request.uri.path == '/admin/accounts') {
        final page = int.parse(request.queryParameters['page']!.toString());
        pages.add(page);
        return fakeJsonResponse(request, {
          'data': [
            _account(
              id: page == 1 ? 'client-1' : 'provider-2',
              type: page == 1 ? 'CLIENT' : 'PROVIDER',
            ),
          ],
          'total': 21,
          'page': page,
          'limit': 20,
        });
      }
      if (request.uri.path == '/localities' ||
          request.uri.path == '/admin/categories') {
        return fakeJsonResponse(request, apiEnvelope(<Object?>[]));
      }
      throw StateError(
        'Unexpected request: ${request.method} ${request.uri.path}',
      );
    });

    await _pumpAccounts(tester, api);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(pages, [1, 2]);
    expect(find.text('Página 2 · 21 cuentas'), findsOneWidget);
  });

  testWidgets('shows a clear state when filters return no accounts', (
    tester,
  ) async {
    final api = fakeApiClient((request) {
      if (request.uri.path == '/admin/accounts') {
        return fakeJsonResponse(request, {
          'data': <Object?>[],
          'total': 0,
          'page': 1,
          'limit': 20,
        });
      }
      if (request.uri.path == '/localities' ||
          request.uri.path == '/admin/categories') {
        return fakeJsonResponse(request, apiEnvelope(<Object?>[]));
      }
      throw StateError(
        'Unexpected request: ${request.method} ${request.uri.path}',
      );
    });

    await _pumpAccounts(tester, api);
    expect(
      find.text('No hay cuentas que coincidan con estos filtros.'),
      findsOneWidget,
    );
  });

  testWidgets('keeps the combined list queryable and shows retry on failure', (
    tester,
  ) async {
    var fail = true;
    final requests = <RequestOptions>[];
    final api = fakeApiClient((request) {
      requests.add(request);
      if (request.uri.path == '/admin/accounts') {
        if (fail) {
          return fakeJsonResponse(
            request,
            apiError('TEMPORARY', 'Error temporal'),
            statusCode: 503,
          );
        }
        return fakeJsonResponse(request, {
          'data': [_account(id: 'client-1', type: 'CLIENT')],
          'total': 1,
          'page': 1,
          'limit': 20,
        });
      }
      if (request.uri.path == '/localities' ||
          request.uri.path == '/admin/categories') {
        return fakeJsonResponse(request, apiEnvelope(<Object?>[]));
      }
      throw StateError(
        'Unexpected request: ${request.method} ${request.uri.path}',
      );
    });

    await _pumpAccounts(tester, api);
    expect(find.text('Reintentar'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(
      requests
          .where(
            (request) =>
                request.method == 'GET' &&
                request.uri.path == '/admin/accounts',
          )
          .length,
      2,
    );
  });
}
