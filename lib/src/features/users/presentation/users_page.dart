import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/layout/admin_page_header.dart';
import '../../../app/layout/admin_filter_panel.dart';
import '../../../app/layout/admin_data_table.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../data/users_remote_data_source.dart';
import '../data/users_repository.dart';
import '../models/admin_user.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _search = TextEditingController();
  String? _active;
  int _page = 1;
  late final UsersRepository _repository;
  late Future<AdminUserPage> _users;

  @override
  void initState() {
    super.initState();
    _repository = UsersRepository(
      UsersRemoteDataSource(context.read<ApiClient>()),
    );
    _users = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<AdminUserPage> _load() => _repository.list(
    AdminUserFilters(
      search: _search.text,
      active: _active == null ? null : _active == 'true',
      page: _page,
    ),
  );

  void _refresh() {
    setState(() {
      _users = _load();
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
    children: [
      const AdminPageHeader(
        section: 'Personas',
        title: 'Usuarios',
        description: 'Busca cuentas y administra los campos permitidos.',
        icon: Icons.people_outline,
      ),
      const SizedBox(height: 24),
      AdminFilterPanel(
        title: 'Buscar y filtrar usuarios',
        description: 'Acota la lista por texto o estado de cuenta.',
        child: Column(
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
                          _page = 1;
                          _refresh();
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                _page = 1;
                _refresh();
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                DropdownButton<String?>(
                  value: _active,
                  hint: const Text('Todos los estados'),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Todos los estados'),
                    ),
                    DropdownMenuItem(value: 'true', child: Text('Activos')),
                    DropdownMenuItem(
                      value: 'false',
                      child: Text('Desactivados'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _active = value;
                    _page = 1;
                    _users = _load();
                  }),
                ),
                IconButton.filledTonal(
                  tooltip: 'Actualizar usuarios',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
                if (_active != null || _search.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      _search.clear();
                      _active = null;
                      _page = 1;
                      _refresh();
                    },
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
        'Listado de usuarios',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      FutureBuilder<AdminUserPage>(
        future: _users,
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
            return _UserMessage(
              message: snapshot.error is ApiFailure
                  ? (snapshot.error! as ApiFailure).message
                  : 'No se pudieron cargar los usuarios.',
              onRetry: _refresh,
            );
          }
          final data = snapshot.data!;
          if (data.items.isEmpty) {
            return const _UserMessage(
              message: 'No hay usuarios que coincidan con estos filtros.',
            );
          }
          return Column(
            children: [
              AdminDataTable(
                columns: const [
                  DataColumn(label: Text('Usuario')),
                  DataColumn(label: Text('Contacto')),
                  DataColumn(label: Text('Rol')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: [
                  for (final user in data.items)
                    DataRow(
                      onSelectChanged: (_) => _details(user),
                      cells: [
                        DataCell(Text(user.fullName)),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email ?? 'Sin email'),
                              Text(
                                user.phone ?? 'Teléfono no incluido',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(_roleLabel(user.role))),
                        DataCell(
                          AdminStatusBadge(
                            label: user.isAccountActive
                                ? 'Activa'
                                : 'Desactivada',
                            positive: user.isAccountActive,
                          ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            tooltip: 'Acciones de usuario',
                            onSelected: (action) {
                              if (action == 'edit') _edit(user);
                              if (action == 'active') _toggleActive(user);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'active',
                                child: Text(
                                  user.isAccountActive
                                      ? 'Desactivar cuenta'
                                      : 'Reactivar cuenta',
                                ),
                              ),
                            ],
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
                            _users = _load();
                          }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Página $_page · ${data.total} usuarios'),
                  IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: _page >= data.totalPages
                        ? null
                        : () => setState(() {
                            _page++;
                            _users = _load();
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

  Future<void> _details(AdminUser user) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(user.fullName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rol: ${_roleLabel(user.role)}'),
          Text('Email: ${user.email ?? 'Sin email'}'),
          Text('Teléfono: ${user.phone ?? 'Teléfono no incluido en la lista'}'),
          Text('Localidad: ${user.locality?.name ?? 'Sin localidad'}'),
          Text('Cuenta: ${user.isAccountActive ? 'Activa' : 'Desactivada'}'),
          if (user.createdAt != null)
            Text(
              'Alta: ${MaterialLocalizations.of(context).formatMediumDate(user.createdAt!.toLocal())}',
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );

  Future<void> _edit(AdminUser user) async {
    try {
      final localities = await _repository.localities();
      if (!mounted) return;
      final changes = await showDialog<Map<String, Object?>>(
        context: context,
        builder: (context) =>
            _UserEditDialog(user: user, localities: localities),
      );
      if (changes == null || !mounted) return;
      await _repository.update(
        user.id,
        changes,
        context.read<AdminSession>().csrfToken,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Usuario actualizado.')));
      _refresh();
    } on ApiFailure catch (error) {
      if (error.isUnauthorized && mounted) {
        context.read<AdminSession>().expire();
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _toggleActive(AdminUser user) async {
    final target = !user.isAccountActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(target ? 'Reactivar cuenta' : 'Desactivar cuenta'),
        content: Text(
          target
              ? '¿Reactivar la cuenta de ${user.fullName}?'
              : 'Se cerrarán las sesiones activas de ${user.fullName}. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.setActive(
        user.id,
        target,
        context.read<AdminSession>().csrfToken,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            target
                ? 'Cuenta reactivada.'
                : 'Cuenta desactivada y sesiones revocadas.',
          ),
        ),
      );
      _refresh();
    } on ApiFailure catch (error) {
      if (error.isUnauthorized && mounted) {
        context.read<AdminSession>().expire();
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _UserEditDialog extends StatefulWidget {
  const _UserEditDialog({required this.user, required this.localities});
  final AdminUser user;
  final List<AdminLocality> localities;
  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName = TextEditingController(
    text: widget.user.firstName,
  );
  late final TextEditingController _lastName = TextEditingController(
    text: widget.user.lastName,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.user.phone,
  );
  String? _localityId;

  @override
  void initState() {
    super.initState();
    _localityId = widget.user.locality?.id;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar usuario'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: _required,
              ),
              TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: _required,
              ),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: _required,
              ),
              DropdownButtonFormField<String?>(
                initialValue: _localityId,
                decoration: const InputDecoration(labelText: 'Localidad'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin localidad'),
                  ),
                  if (widget.user.locality != null &&
                      !widget.localities.any(
                        (locality) => locality.id == widget.user.locality!.id,
                      ))
                    DropdownMenuItem<String?>(
                      value: widget.user.locality!.id,
                      child: Text(widget.user.locality!.name),
                    ),
                  for (final locality in widget.localities)
                    DropdownMenuItem<String?>(
                      value: locality.id,
                      child: Text(locality.name),
                    ),
                ],
                onChanged: (value) => setState(() => _localityId = value),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Guardar')),
    ],
  );

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio'
      : null;
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'phone': _phone.text.trim(),
      'localityId': _localityId,
    });
  }
}

String _roleLabel(String role) => switch (role) {
  'CLIENT' => 'Cliente',
  'PROVIDER' => 'Prestador',
  'ADMIN' => 'Admin',
  _ => 'Soporte',
};

class _UserMessage extends StatelessWidget {
  const _UserMessage({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        Text(message),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}
