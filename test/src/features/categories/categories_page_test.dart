import 'package:dashboard_tooapp/src/core/network/api_client.dart';
import 'package:dashboard_tooapp/src/core/session/session_controller.dart';
import 'package:dashboard_tooapp/src/features/categories/presentation/categories_page.dart';

import '../../../support/fake_api.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _pendingCategory = <String, Object?>{
  'id': 'category-pending',
  'name': 'Plomería',
  'iconUrl': null,
  'status': 'PENDING',
  'isActive': true,
  'createdAt': '2026-10-30T12:00:00.000Z',
  '_count': {'primaryProviders': 2, 'secondaryProviders': 1},
};

const _approvedCategory = <String, Object?>{
  'id': 'category-approved',
  'name': 'Construcción',
  'iconUrl': null,
  'status': 'APPROVED',
  'isActive': true,
  'createdAt': '2026-10-29T12:00:00.000Z',
  '_count': {'primaryProviders': 4, 'secondaryProviders': 0},
};

Map<String, Object?> _page(List<Object?> items) => {
  'items': items,
  'pagination': {
    'page': 1,
    'limit': 20,
    'total': items.length,
    'totalPages': 1,
  },
};

Map<String, Object?> _categoryResponse(RequestOptions request) {
  final status = request.uri.queryParameters['status'];
  final items = switch (status) {
    'PENDING' => <Object?>[_pendingCategory],
    'APPROVED' => <Object?>[_approvedCategory],
    _ => <Object?>[_pendingCategory, _approvedCategory],
  };
  return apiEnvelope(_page(items));
}

Future<void> _pumpCategories(WidgetTester tester, ApiClient api) async {
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
      child: const MaterialApp(home: Scaffold(body: CategoriesPage())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows empty categories and supports approved filters', (
    tester,
  ) async {
    final requests = <RequestOptions>[];
    final api = fakeApiClient((request) {
      requests.add(request);
      return fakeJsonResponse(request, apiEnvelope(_page([])));
    });

    await _pumpCategories(tester, api);
    expect(
      find.text('No hay categorías que coincidan con estos filtros.'),
      findsOneWidget,
    );
    expect(requests, hasLength(3));
  });

  testWidgets('creates a category only after form validation', (tester) async {
    final requests = <RequestOptions>[];
    final api = fakeApiClient((request) {
      requests.add(request);
      if (request.method == 'POST') {
        return fakeJsonResponse(request, apiEnvelope({'id': 'new-category'}));
      }
      return fakeJsonResponse(request, _categoryResponse(request));
    });

    await _pumpCategories(tester, api);
    await tester.tap(find.text('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresá al menos 2 caracteres'), findsOneWidget);
    expect(requests.where((request) => request.method == 'POST'), isEmpty);

    await tester.enterText(find.byType(TextFormField).first, 'Gasista');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final createRequest = requests.singleWhere(
      (request) => request.method == 'POST',
    );
    expect(createRequest.uri.path, '/admin/categories');
    expect(createRequest.data, containsPair('name', 'Gasista'));
    expect(find.text('Categoría creada en estado pendiente.'), findsOneWidget);
  });

  testWidgets(
    'cancels category deactivation and reports conflict without success',
    (tester) async {
      final requests = <RequestOptions>[];
      final api = fakeApiClient((request) {
        requests.add(request);
        if (request.method == 'PATCH') {
          return fakeJsonResponse(
            request,
            apiError('CONFLICT', 'La categoría cambió. Actualizá la lista.'),
            statusCode: 409,
          );
        }
        return fakeJsonResponse(request, _categoryResponse(request));
      });

      await _pumpCategories(tester, api);
      final actions = find.byType(PopupMenuButton<String>).first;
      await tester.ensureVisible(actions);
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desactivar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(requests.where((request) => request.method == 'PATCH'), isEmpty);
      expect(find.text('Estado actualizado.'), findsNothing);

      await tester.ensureVisible(actions);
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desactivar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(
        requests.where((request) => request.method == 'PATCH'),
        hasLength(1),
      );
      final update = requests.singleWhere(
        (request) => request.method == 'PATCH',
      );
      expect(update.uri.path, '/admin/categories/category-pending/active');
      expect(update.data, containsPair('isActive', false));
      expect(
        find.text('La categoría cambió. Actualizá la lista.'),
        findsOneWidget,
      );
      expect(find.text('Estado actualizado.'), findsNothing);
    },
  );

  testWidgets(
    'shows the unification impact and sends only after confirmation',
    (tester) async {
      final requests = <RequestOptions>[];
      final api = fakeApiClient((request) {
        requests.add(request);
        if (request.method == 'POST') {
          return fakeJsonResponse(
            request,
            apiEnvelope({
              'updatedProvidersCount': 3,
              'sourceCategoryId': 'category-pending',
              'targetCategoryId': 'category-approved',
            }),
          );
        }
        return fakeJsonResponse(request, _categoryResponse(request));
      });

      await _pumpCategories(tester, api);
      final dropdowns = find.byType(DropdownButton<String>);
      await tester.ensureVisible(dropdowns.first);
      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plomería').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(dropdowns.last);
      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Construcción').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Unificar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Plomería'), findsWidgets);
      expect(find.textContaining('Construcción'), findsWidgets);
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();
      expect(requests.where((request) => request.method == 'POST'), isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'Unificar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pumpAndSettle();
      final unifyRequest = requests.singleWhere(
        (request) => request.method == 'POST',
      );
      expect(unifyRequest.uri.path, '/admin/categories/unify');
      expect(
        unifyRequest.data,
        containsPair('sourceCategoryId', 'category-pending'),
      );
      expect(
        unifyRequest.data,
        containsPair('targetCategoryId', 'category-approved'),
      );
      expect(
        find.text('Unificación confirmada. 3 prestadores afectados.'),
        findsOneWidget,
      );
    },
  );
}
