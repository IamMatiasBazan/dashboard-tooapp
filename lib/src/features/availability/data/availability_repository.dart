import '../../providers/models/admin_provider.dart';
import '../models/admin_provider_availability.dart';
import 'availability_remote_data_source.dart';

class AvailabilityRepository {
  const AvailabilityRepository(this._remote);
  final AvailabilityRemoteDataSource _remote;

  Future<AdminProviderPage> listProviders(String search) =>
      _remote.listProviders(search);
  Future<AdminProviderAvailability> get(String providerProfileId) =>
      _remote.get(providerProfileId);
}
