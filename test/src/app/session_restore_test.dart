import 'package:dashboard_tooapp/src/app/app.dart';
import 'package:dashboard_tooapp/src/core/network/api_client.dart';
import 'package:dashboard_tooapp/src/core/session/session_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('starts the router with an unauthenticated session', (
    tester,
  ) async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 401,
              data: {
                'error': {'code': 'UNAUTHORIZED', 'message': 'Sesión ausente'},
              },
            ),
          ),
        ),
      ),
    );
    final api = ApiClient(baseUrl: 'http://localhost:3000', dio: dio);
    final session = AdminSession(api);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<AdminSession>.value(value: session),
        ],
        child: const AdminApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Administración'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
