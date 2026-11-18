import '../models/admin_home_summary.dart';
import 'home_remote_data_source.dart';

class HomeRepository {
  const HomeRepository(this._remote);

  final HomeRemoteDataSource _remote;

  Future<AdminHomeSummary> summary(int periodDays) =>
      _remote.summary(periodDays);
}
