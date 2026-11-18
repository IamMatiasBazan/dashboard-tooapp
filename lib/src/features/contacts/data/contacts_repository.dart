import '../models/admin_contact.dart';
import 'contacts_remote_data_source.dart';

class ContactsRepository {
  const ContactsRepository(this._remote);
  final ContactsRemoteDataSource _remote;

  Future<AdminContactPage> list(AdminContactFilters filters) =>
      _remote.list(filters);
  Future<AdminContact> get(String id) => _remote.get(id);
  Future<AdminContact> updateStatus(
    String id,
    String status,
    String? csrfToken, {
    DateTime? scheduledFor,
  }) => _remote.updateStatus(id, status, csrfToken, scheduledFor: scheduledFor);
}
