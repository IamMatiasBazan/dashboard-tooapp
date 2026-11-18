import 'package:dashboard_tooapp/src/app/layout/admin_scaffold.dart';
import 'package:dashboard_tooapp/src/core/session/session_controller.dart';

import '../../support/fake_api.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _implementedSections = [
  'Inicio',
  'Reportes',
  'Contactos',
  'Usuarios',
  'Prestadores',
  'Reseñas',
  'Categorías',
  'Disponibilidad',
  'Membresías',
];
const _excludedSections = ['Localidades', 'Pagos', 'Servicios'];

Future<void> _pumpScaffold(
  WidgetTester tester, {
  required Size size,
  required String location,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = AdminSession(
    fakeApiClient((request) async {
      throw StateError('Logout should not be invoked by this layout test.');
    }),
  );
  await tester.pumpWidget(
    ChangeNotifierProvider<AdminSession>.value(
      value: session,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: AdminScaffold(
          location: location,
          child: Semantics(
            label: 'Contenido principal',
            child: Text('Contenido principal'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('navigation colors contrast with the drawer in both states', (
    tester,
  ) async {
    await _pumpScaffold(
      tester,
      size: const Size(1280, 800),
      location: '/reports',
    );

    final drawer = tester.widget<Drawer>(find.byType(Drawer));
    expect(drawer.backgroundColor, Colors.white);

    final reportTile = tester.widget<ListTile>(
      find
          .ancestor(
            of: find.text('Reportes').first,
            matching: find.byType(ListTile),
          )
          .first,
    );
    final homeTile = tester.widget<ListTile>(
      find
          .ancestor(
            of: find.text('Inicio').first,
            matching: find.byType(ListTile),
          )
          .first,
    );
    expect(reportTile.selected, isTrue);
    expect(reportTile.selectedTileColor, const Color(0xFF0875CE));
    expect(homeTile.selected, isFalse);

    final reportTheme = tester.widget<ListTileTheme>(
      find
          .ancestor(
            of: find.text('Reportes').first,
            matching: find.byType(ListTileTheme),
          )
          .first,
    );
    expect(reportTheme.iconColor, const Color(0xFF626269));
    expect(reportTheme.textColor, const Color(0xFF171719));
    expect(reportTheme.selectedColor, Colors.white);
    expect(
      tester.widget<Text>(find.text('Administración')).style?.color,
      const Color(0xFF171719),
    );
  });

  testWidgets('wide layout keeps labelled navigation and visible focus', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpScaffold(
      tester,
      size: const Size(1280, 800),
      location: '/reports',
    );

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('Contenido principal'), findsOneWidget);
    for (final label in _implementedSections) {
      expect(find.text(label), findsWidgets);
    }
    for (final label in _excludedSections) {
      expect(find.text(label), findsNothing);
    }
    expect(tester.getSemantics(find.text('Reportes').first), isNotNull);
    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('compact layout preserves the same sections at enlarged text', (
    tester,
  ) async {
    await _pumpScaffold(
      tester,
      size: const Size(390, 844),
      location: '/reports',
      textScale: 2,
    );

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('Contenido principal'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Drawer), findsOneWidget);
    final drawerScroll = find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(Scrollable),
    );
    for (final label in _implementedSections) {
      final drawerLabel = find.descendant(
        of: find.byType(Drawer),
        matching: find.text(label),
      );
      await tester.scrollUntilVisible(
        drawerLabel,
        180,
        scrollable: drawerScroll.first,
      );
      expect(drawerLabel, findsOneWidget);
    }
    for (final label in _excludedSections) {
      expect(find.text(label), findsNothing);
    }
  });
}
