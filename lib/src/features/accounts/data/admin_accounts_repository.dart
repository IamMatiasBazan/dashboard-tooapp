import 'admin_accounts_remote_data_source.dart';
import '../models/admin_account.dart';

class AdminAccountsRepository {
  const AdminAccountsRepository(this._source);
  final AdminAccountsRemoteDataSource _source;
  Future<AdminAccountPage> list(AdminAccountFilters filters) =>
      _source.list(filters);
  Future<List<AdminAccountLocality>> localities() => _source.localities();
  Future<List<AdminAccountCategory>> categories() => _source.categories();
}
