import 'package:dashboard_tooapp/src/core/network/api_client.dart';
import 'package:dashboard_tooapp/src/features/accounts/data/admin_accounts_remote_data_source.dart';
import 'package:dashboard_tooapp/src/features/accounts/models/admin_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import '../../../support/fake_api.dart';

const _clientId = '00000000-0000-4000-8000-000000000001';
const _providerId = '00000000-0000-4000-8000-000000000002';

Map<String, Object?> _client() => {
  'id': _clientId,
  'accountType': 'CLIENT',
  'firstName': 'Ada',
  'lastName': 'Lovelace',
  'email': 'ada@example.test',
  'isAccountActive': true,
  'createdAt': '2026-11-01T00:00:00.000Z',
  'locality': {'id': 'locality-1', 'name': 'Moreno'},
  'providerProfile': null,
};

Map<String, Object?> _provider() => {
  'id': _providerId,
  'accountType': 'PROVIDER',
  'firstName': 'Grace',
  'lastName': 'Hopper',
  'email': 'grace@example.test',
  'isAccountActive': true,
  'createdAt': '2026-11-02T00:00:00.000Z',
  'locality': null,
  'providerProfile': {
    'id': 'profile-1',
    'primaryCategory': {'id': 'category-1', 'name': 'Electricidad'},
    'isAvailable': false,
  },
};

void main() {
  test(
    'parses discriminated client and provider rows and global pagination',
    () async {
      final source = AdminAccountsRemoteDataSource(
        fakeApiClient(
          (request) => fakeJsonResponse(request, {
            'data': [_client(), _provider()],
            'total': 25,
            'page': 2,
            'limit': 2,
          }),
        ),
      );

      final page = await source.list(
        const AdminAccountFilters(page: 2, limit: 2),
      );

      expect(page.items.map((item) => item.type), [
        AdminAccountType.client,
        AdminAccountType.provider,
      ]);
      expect(page.items.last.primaryCategoryName, 'Electricidad');
      expect(page.total, 25);
      expect(page.totalPages, 13);
    },
  );

  test('serializes only combined endpoint filters', () async {
    RequestOptions? captured;
    final source = AdminAccountsRemoteDataSource(
      fakeApiClient((request) {
        captured = request;
        return fakeJsonResponse(request, {
          'data': <Object?>[],
          'total': 0,
          'page': 1,
          'limit': 20,
        });
      }),
    );

    await source.list(
      const AdminAccountFilters(
        search: ' Ada ',
        type: AdminAccountType.provider,
        isAccountActive: false,
        localityId: 'locality-1',
        categoryId: 'category-1',
        isAvailable: true,
      ),
    );

    expect(captured!.uri.path, '/admin/accounts');
    expect(captured!.queryParameters, {
      'q': 'Ada',
      'accountType': 'PROVIDER',
      'isAccountActive': 'false',
      'localityId': 'locality-1',
      'categoryId': 'category-1',
      'isAvailable': 'true',
      'page': 1,
      'limit': 20,
    });
  });

  test('rejects an unexpected paginated response shape', () async {
    final source = AdminAccountsRemoteDataSource(
      fakeApiClient((request) => fakeJsonResponse(request, {'items': []})),
    );

    await expectLater(
      source.list(const AdminAccountFilters()),
      throwsA(isA<ApiFailure>()),
    );
  });
}
