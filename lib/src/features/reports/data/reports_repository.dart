import '../models/report.dart';
import 'reports_remote_data_source.dart';

class ReportsRepository {
  const ReportsRepository(this._remote);
  final ReportsRemoteDataSource _remote;

  Future<ReportPage> list(ReportFilters filters) => _remote.list(filters);
  Future<void> resolve(String reportId, String? csrfToken) =>
      _remote.resolve(reportId, csrfToken);
}
