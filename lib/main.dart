import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app/app.dart';
import 'src/core/network/api_client.dart';
import 'src/core/session/session_controller.dart';

void main() {
  final api = createApiClient();
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(create: (_) => AdminSession(api)),
      ],
      child: const AdminApp(),
    ),
  );
}
