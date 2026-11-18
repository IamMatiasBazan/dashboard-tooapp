import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/layout/admin_data_table.dart';
import '../../../app/layout/admin_filter_panel.dart';
import '../../../app/layout/admin_page_header.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../data/admin_accounts_remote_data_source.dart';
import '../data/admin_accounts_repository.dart';
import '../models/admin_account.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});
  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final _search = TextEditingController();
  String? _type;
  String? _active;
  String? _localityId;
  String? _categoryId;
  String? _available;
  int _page = 1;
  late final AdminAccountsRepository _repository;
  late Future<AdminAccountPage> _accounts;
  late Future<List<AdminAccountLocality>> _localities;
  late Future<List<AdminAccountCategory>> _categories;

  @override
  void initState() {
    super.initState();
    _repository = AdminAccountsRepository(
      AdminAccountsRemoteDataSource(context.read<ApiClient>()),
    );
    _accounts = _load();
    _localities = _repository.localities();
    _categories = _repository.categories();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<AdminAccountPage> _load() => _repository.list(
    AdminAccountFilters(
      search: _search.text,
      type: switch (_type) {
        'CLIENT' => AdminAccountType.client,
        'PROVIDER' => AdminAccountType.provider,
        _ => null,
      },
      isAccountActive: _active == null ? null : _active == 'true',
      localityId: _localityId,
      categoryId: _type == 'CLIENT' ? null : _categoryId,
      isAvailable: _type == 'CLIENT' || _available == null
          ? null
          : _available == 'true',
      page: _page,
    ),
  );

  void _refresh() {
    setState(() {
      _accounts = _load();
    });
  }

  void _filtersChanged() => setState(() {
    _page = 1;
    _accounts = _load();
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
    children: [
      const AdminPageHeader(
        section: 'Personas',
        title: 'Usuarios y prestadores',
        description: 'Consulta las cuentas registradas en TooApp desde una lista unificada.',
        icon: Icons.people_outline,
      ),
      const SizedBox(height: 24),
      AdminFilterPanel(
        title: 'Buscar y filtrar cuentas',
        description:
            'Los filtros se aplican a usuarios y prestadores en conjunto.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Nombre, correo o teléfono',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _search.clear();
                          _filtersChanged();
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _filtersChanged(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _dropdown(
                  'Todos los tipos',
                  _type,
                  const [('CLIENT', 'Usuarios'), ('PROVIDER', 'Prestadores')],
                  (value) {
                    _type = value;
                    if (value == 'CLIENT') {
                      _categoryId = null;
                      _available = null;
                    }
                    _filtersChanged();
                  },
                ),
                _dropdown(
                  'Todos los estados',
                  _active,
                  const [('true', 'Activos'), ('false', 'Desactivados')],
                  (value) {
                    _active = value;
                    _filtersChanged();
                  },
                ),
                FutureBuilder<List<AdminAccountLocality>>(
                  future: _localities,
                  builder: (context, snapshot) => _dropdown(
                    'Todas las localidades',
                    _localityId,
                    (snapshot.data ?? const [])
                        .map((item) => (item.id, item.name))
                        .toList(),
                    (value) {
                      _localityId = value;
                      _filtersChanged();
                    },
                  ),
                ),
                if (_type != 'CLIENT')
                  FutureBuilder<List<AdminAccountCategory>>(
                    future: _categories,
                    builder: (context, snapshot) => _dropdown(
                      'Todas las categorías',
                      _categoryId,
                      (snapshot.data ?? const [])
                          .map((item) => (item.id, item.name))
                          .toList(),
                      (value) {
                        _categoryId = value;
                        _filtersChanged();
                      },
                    ),
                  ),
                if (_type != 'CLIENT')
                  _dropdown(
                    'Toda disponibilidad',
                    _available,
                    const [
                      ('true', 'Disponibles'),
                      ('false', 'No disponibles'),
                    ],
                    (value) {
                      _available = value;
                      _filtersChanged();
                    },
                  ),
                IconButton.filledTonal(
                  tooltip: 'Actualizar cuentas',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
                if (_hasFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Limpiar filtros'),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Cuentas registradas',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      FutureBuilder<AdminAccountPage>(
        future: _accounts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            if (snapshot.error is ApiFailure &&
                (snapshot.error! as ApiFailure).isUnauthorized) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => context.read<AdminSession>().expire(),
              );
            }
            return _Message(
              message: snapshot.error is ApiFailure
                  ? (snapshot.error! as ApiFailure).message
                  : 'No se pudieron cargar las cuentas.',
              onRetry: _refresh,
            );
          }
          final data = snapshot.data!;
          if (data.items.isEmpty) {
            return const _Message(
              message: 'No hay cuentas que coincidan con estos filtros.',
            );
          }
          return Column(
            children: [
              AdminDataTable(
                columns: const [
                  DataColumn(label: Text('Cuenta')),
                  DataColumn(label: Text('Correo')),
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Localidad / rubro')),
                  DataColumn(label: Text('Disponibilidad')),
                  DataColumn(label: Text('Registro')),
                ],
                rows: [
                  for (final item in data.items)
                    DataRow(
                      cells: [
                        DataCell(Text(item.fullName)),
                        DataCell(Text(item.email ?? 'Sin correo')),
                        DataCell(
                          Text(
                            item.type == AdminAccountType.client
                                ? 'Cliente'
                                : 'Prestador',
                          ),
                        ),
                        DataCell(
                          AdminStatusBadge(
                            label: item.isAccountActive
                                ? 'Activa'
                                : 'Desactivada',
                            positive: item.isAccountActive,
                          ),
                        ),
                        DataCell(
                          Text(
                            item.type == AdminAccountType.provider
                                ? (item.primaryCategoryName ?? 'Sin rubro')
                                : (item.locality?.name ?? 'Sin localidad'),
                          ),
                        ),
                        DataCell(
                          Text(
                            item.type == AdminAccountType.provider
                                ? (item.isAvailable == true
                                      ? 'Disponible'
                                      : 'No disponible')
                                : '—',
                          ),
                        ),
                        DataCell(
                          Text(
                            item.createdAt == null
                                ? '—'
                                : MaterialLocalizations.of(
                                    context,
                                  ).formatShortDate(item.createdAt!.toLocal()),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Página anterior',
                    onPressed: _page <= 1
                        ? null
                        : () => setState(() {
                            _page--;
                            _accounts = _load();
                          }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Página $_page · ${data.total} cuentas'),
                  IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: _page >= data.totalPages
                        ? null
                        : () => setState(() {
                            _page++;
                            _accounts = _load();
                          }),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ],
  );

  bool get _hasFilters =>
      _type != null ||
      _active != null ||
      _localityId != null ||
      _categoryId != null ||
      _available != null ||
      _search.text.isNotEmpty;
  void _clearFilters() {
    _search.clear();
    _type = null;
    _active = null;
    _localityId = null;
    _categoryId = null;
    _available = null;
    _filtersChanged();
  }

  Widget _dropdown(
    String label,
    String? value,
    List<(String, String)> options,
    ValueChanged<String?> onChanged,
  ) => DropdownButton<String?>(
    value: value,
    hint: Text(label),
    items: [
      DropdownMenuItem<String?>(value: null, child: Text(label)),
      for (final option in options)
        DropdownMenuItem<String?>(value: option.$1, child: Text(option.$2)),
    ],
    onChanged: onChanged,
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ],
    ),
  );
}
