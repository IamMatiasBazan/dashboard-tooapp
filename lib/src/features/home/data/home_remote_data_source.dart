import '../../../core/network/api_client.dart';
import '../models/admin_home_summary.dart';

class HomeRemoteDataSource {
  const HomeRemoteDataSource(this._api);

  final ApiClient _api;

  Future<AdminHomeSummary> summary(int periodDays) async {
    final response = await _api.getData(
      '/admin/dashboard/summary',
      query: {'periodDays': periodDays},
    );
    return AdminHomeSummary.fromJson(response);
  }
}
