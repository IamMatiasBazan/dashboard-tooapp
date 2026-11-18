import '../../../core/network/api_client.dart';
import '../models/report.dart';

class ReportsRemoteDataSource {
  const ReportsRemoteDataSource(this._api);
  final ApiClient _api;

  Future<ReportPage> list(ReportFilters filters) async {
    final rawItems = await _api.getList('/admin/reports', query: filters.toQuery());
    final pageStart = (filters.page - 1) * filters.limit;
    final pageItems = rawItems.skip(pageStart).take(filters.limit).toList(growable: false);
    return ReportPage(
      items: pageItems.map(Report.fromJson).toList(growable: false),
      page: filters.page,
      limit: filters.limit,
      total: rawItems.length,
      totalPages: (rawItems.length / filters.limit).ceil(),
    );
  }

  Future<void> resolve(String reportId, String? csrfToken) async {
    await _api.patchPath(
      '/admin/reports/$reportId/resolve',
      csrfToken: csrfToken,
    );
  }
}
