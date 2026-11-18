import 'package:dashboard_tooapp/src/core/network/api_client.dart';
import 'package:dashboard_tooapp/src/core/session/session_controller.dart';
import 'package:dashboard_tooapp/src/features/providers/presentation/providers_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_api.dart';

const _providerProfileId = 'provider-profile-id';
const _userId = 'provider-user-id';
const _categoryId = 'provider-category-id';
const _localityId = 'provider-locality-id';

Map<String, Object?> _providerListRow() => {
  'id': _providerProfileId,
  'userId': _userId,
  'isAvailable': false,
  'primaryCategory': {'id': _categoryId, 'name': 'Plomería'},
  'user': {
    'id': _userId,
    'firstName': 'Ada',
    'lastName': 'Lovelace',
    'email': 'ada@example.test',
    'isAccountActive': true,
    'locality': {'id': _localityId, 'name': 'Moreno'},
  },
};

Map<String, Object?> _providerDetails() => {
  ..._providerListRow(),
  'bio': 'Perfil original',
  'experienceYears': 7,
  'minPrice': 15000,
  'isMatriculado': true,
  'secondaryCategories': <Object?>[],
  'user': {
    ...(_providerListRow()['user']! as Map<String, Object?>),
    'phone': '5551234',
  },
};

Future<void> _pumpProviders(WidgetTester tester, ApiClient api) async {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(create: (_) => AdminSession(api)),
      ],
      child: const MaterialApp(home: Scaffold(body: ProvidersPage())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('loads detail and patches by provider profile ID when editing', (
    tester,
  ) async {
    final requests = <RequestOptions>[];
    final api = fakeApiClient((request) {
      requests.add(request);
      if (request.method == 'GET' && request.uri.path == '/admin/categories') {
        return fakeJsonResponse(
          request,
          apiEnvelope([
            {'id': _categoryId, 'name': 'Plomería'},
          ]),
        );
      }
      if (request.method == 'GET' && request.uri.path == '/localities') {
        return fakeJsonResponse(
          request,
          apiEnvelope([
            {'id': _localityId, 'name': 'Moreno'},
          ]),
        );
      }
      if (request.method == 'GET' && request.uri.path == '/admin/providers') {
        return fakeJsonResponse(request, {
          'data': [_providerListRow()],
          'total': 1,
          'page': 1,
          'limit': 20,
        });
      }
      if (request.method == 'GET' &&
          request.uri.path == '/admin/providers/$_providerProfileId') {
        return fakeJsonResponse(request, apiEnvelope(_providerDetails()));
      }
      if (request.method == 'PATCH' &&
          request.uri.path == '/admin/providers/$_providerProfileId') {
        return fakeJsonResponse(request, apiEnvelope(_providerDetails()));
      }
      throw StateError('Unexpected request');
    });

    await _pumpProviders(tester, api);
    final action = find.byType(PopupMenuButton<String>).first;
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar ficha'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(2))
          .controller!
          .text,
      '5551234',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(3))
          .controller!
          .text,
      'Perfil original',
    );

    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(DropdownButtonFormField<String?>),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Moreno'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Localidad'),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(
      requests.any(
        (request) =>
            request.method == 'GET' &&
            request.uri.path == '/admin/providers/$_providerProfileId',
      ),
      isTrue,
    );
    final update = requests.singleWhere((request) => request.method == 'PATCH');
    expect(update.uri.path, '/admin/providers/$_providerProfileId');
    expect(update.data, isA<Map<String, Object?>>());
    final body = update.data! as Map<String, Object?>;
    expect(body['user'], containsPair('phone', '5551234'));
    expect(body['user'], isNot(contains('localityId')));
    expect(body['providerProfile'], containsPair('bio', 'Perfil original'));
  });
}
