import 'package:dashboard_tooapp/src/core/network/api_client.dart';
import 'package:dashboard_tooapp/src/core/session/session_controller.dart';
import 'package:dashboard_tooapp/src/features/reports/presentation/reports_page.dart';

import '../../../support/fake_api.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _report = <String, Object?>{
  'id': 'report-1',
  'type': 'CLAIM',
  'content': 'El trabajo no se completó.',
  'isResolved': false,
  'createdAt': '2026-10-30T12:00:00.000Z',
  'author': {
    'id': 'client-1',
    'firstName': 'Ada',
    'lastName': 'Lovelace',
    'email': 'ada@example.test',
  },
};

Map<String, Object?> _reportPage(List<Object?> items) => {
  'items': items,
  'pagination': {
    'page': 1,
    'limit': 20,
    'total': items.length,
    'totalPages': 1,
  },
};

Future<void> _pumpReports(WidgetTester tester, ApiClient api) async {
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
      child: const MaterialApp(home: Scaffold(body: ReportsPage())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows empty result and sends only supported filters', (
    tester,
  ) async {
    final requests = <RequestOptions>[];
    final api = fakeApiClient((request) {
      requests.add(request);
      return fakeJsonResponse(request, apiEnvelope(_reportPage([])));
    });

    await _pumpReports(tester, api);
    expect(
      find.text('No hay reportes que coincidan con estos filtros.'),
      findsOneWidget,
    );
    expect(requests.first.uri.queryParameters, isEmpty);
  });

  testWidgets('advances to the next report page', (tester) async {
    final requests = <RequestOptions>[];
    final api = fakeApiClient((request) {
      requests.add(request);
      return fakeJsonResponse(
        request,
        apiEnvelope(
          List<Object?>.generate(
            21,
            (index) => {..._report, 'id': 'report-$index'},
          ),
        ),
      );
    });

    await _pumpReports(tester, api);
    expect(find.text('Página 1'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -5000));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right).last);
    await tester.pumpAndSettle();

    expect(find.text('Página 2'), findsOneWidget);
    expect(requests.last.uri.queryParameters, isEmpty);
  });

  testWidgets(
    'supports filter selection and only resolves after confirmation',
    (tester) async {
      final requests = <RequestOptions>[];
      final api = fakeApiClient((request) {
        requests.add(request);
        if (request.method == 'PATCH') {
          return fakeJsonResponse(request, apiEnvelope({}));
        }
        return fakeJsonResponse(request, apiEnvelope(_reportPage([_report])));
      });

      await _pumpReports(tester, api);
      expect(find.text('El trabajo no se completó.'), findsOneWidget);
      await tester.tap(find.text('Todos los tipos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reclamo').last);
      await tester.pumpAndSettle();
      expect(requests.last.uri.queryParameters, containsPair('type', 'CLAIM'));

      var resolveButton = find.widgetWithText(TextButton, 'Resolver');
      await tester.ensureVisible(resolveButton);
      await tester.tap(resolveButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();
      expect(requests.where((request) => request.method == 'PATCH'), isEmpty);

      resolveButton = find.widgetWithText(TextButton, 'Resolver');
      await tester.ensureVisible(resolveButton);
      await tester.tap(resolveButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Resolver'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        requests.where((request) => request.method == 'PATCH'),
        hasLength(1),
      );
    },
  );

  for (final status in [401, 403, 409]) {
    testWidgets('renders the API error for HTTP $status', (tester) async {
      final api = fakeApiClient(
        (request) => fakeJsonResponse(
          request,
          apiError('HTTP_$status', 'Respuesta $status'),
          statusCode: status,
        ),
      );
      await _pumpReports(tester, api);
      expect(find.text('Respuesta $status'), findsOneWidget);
    });
  }
}
