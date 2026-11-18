import 'dart:async';

import 'package:dashboard_tooapp/src/core/network/api_client.dart';
import 'package:dio/dio.dart';

typedef FakeApiResponder = FutureOr<Response<Object?>> Function(
  RequestOptions request,
);

ApiClient fakeApiClient(FakeApiResponder responder) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) async {
        try {
          final response = await responder(request);
          if ((response.statusCode ?? 200) < 200 ||
              (response.statusCode ?? 200) >= 300) {
            handler.reject(
              DioException(requestOptions: request, response: response),
            );
          } else {
            handler.resolve(response);
          }
        } catch (error) {
          handler.reject(DioException(requestOptions: request, error: error));
        }
      },
    ),
  );
  return ApiClient(baseUrl: 'https://admin-api.test', dio: dio);
}

Response<Object?> fakeJsonResponse(
  RequestOptions request,
  Object? data, {
  int statusCode = 200,
}) => Response<Object?>(
  requestOptions: request,
  statusCode: statusCode,
  data: data,
);

Map<String, Object?> apiEnvelope(Object? data) => {'data': data};

Map<String, Object?> apiError(String code, String message) => {
  'error': {'code': code, 'message': message},
};
