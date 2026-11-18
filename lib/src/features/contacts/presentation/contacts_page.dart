import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/layout/admin_filter_panel.dart';
import '../../../app/layout/admin_data_table.dart';
import '../../../app/layout/admin_page_header.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../data/contacts_remote_data_source.dart';
import '../data/contacts_repository.dart';
import '../models/admin_contact.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _providerId = TextEditingController();
  final _categoryId = TextEditingController();
  final _clientId = TextEditingController();
  late final ContactsRepository _repository;
  late Future<AdminContactPage> _contacts;
  String? _status;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _repository = ContactsRepository(
      ContactsRemoteDataSource(context.read<ApiClient>()),
    );
    _contacts = _load();
  }

  @override
  void dispose() {
    _providerId.dispose();
    _categoryId.dispose();
    _clientId.dispose();
    super.dispose();
  }

  Future<AdminContactPage> _load() => _repository.list(
    AdminContactFilters(
      status: _status,
      providerId: _providerId.text.trim().isEmpty
          ? null
          : _providerId.text.trim(),
      categoryId: _categoryId.text.trim().isEmpty
          ? null
          : _categoryId.text.trim(),
      clientId: _clientId.text.trim().isEmpty ? null : _clientId.text.trim(),
      page: _page,
    ),
  );

  void _refresh() {
    setState(() {
      _contacts = _load();
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
    children: [
      const AdminPageHeader(
        section: 'Operaciones',
        title: 'Contactos',
        description: 'Consulta solicitudes y actualiza su seguimiento.',
        icon: Icons.chat_bubble_outline,
      ),
      const SizedBox(height: 24),
      AdminFilterPanel(
        title: 'Filtrar solicitudes',
        description:
            'Acotá la bandeja por estado, prestador, categoría o cliente.',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String?>(
              value: _status,
              hint: const Text('Todos los estados'),
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todos los estados'),
                ),
                DropdownMenuItem<String?>(
                  value: 'PENDING',
                  child: Text('Pendiente'),
                ),
                DropdownMenuItem<String?>(
                  value: 'SCHEDULED',
                  child: Text('Agendado'),
                ),
                DropdownMenuItem<String?>(
                  value: 'COMPLETED',
                  child: Text('Completado'),
                ),
                DropdownMenuItem<String?>(
                  value: 'CANCELLED',
                  child: Text('Cancelado'),
                ),
              ],
              onChanged: (value) => setState(() {
                _status = value;
                _page = 1;
                _contacts = _load();
              }),
            ),
            SizedBox(
              width: MediaQuery.sizeOf(context).width < 600
                  ? MediaQuery.sizeOf(context).width - 88
                  : 210,
              child: TextField(
                controller: _providerId,
                decoration: const InputDecoration(
                  labelText: 'Prestador · ID',
                  hintText: 'Identificador del perfil',
                  prefixIcon: Icon(Icons.person_search_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(
              width: MediaQuery.sizeOf(context).width < 600
                  ? MediaQuery.sizeOf(context).width - 88
                  : 210,
              child: TextField(
                controller: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Categoría · ID',
                  hintText: 'Identificador de la categoría',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(
              width: MediaQuery.sizeOf(context).width < 600
                  ? MediaQuery.sizeOf(context).width - 88
                  : 210,
              child: TextField(
                controller: _clientId,
                decoration: const InputDecoration(
                  labelText: 'Cliente · ID',
                  hintText: 'Identificador de la cuenta',
                  prefixIcon: Icon(Icons.account_circle_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                _page = 1;
                _refresh();
              },
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Aplicar'),
            ),
            IconButton(
              tooltip: 'Actualizar contactos',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
            if (_status != null ||
                _providerId.text.isNotEmpty ||
                _categoryId.text.isNotEmpty ||
                _clientId.text.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  _status = null;
                  _providerId.clear();
                  _categoryId.clear();
                  _clientId.clear();
                  _page = 1;
                  _refresh();
                },
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpiar filtros'),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Bandeja de contactos',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      FutureBuilder<AdminContactPage>(
        future: _contacts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            if (snapshot.error is ApiFailure &&
                (snapshot.error! as ApiFailure).isUnauthorized) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => context.read<AdminSession>().expire(),
              );
            }
            return _ContactMessage(
              text: snapshot.error is ApiFailure
                  ? (snapshot.error! as ApiFailure).message
                  : 'No se pudieron cargar los contactos.',
              onRetry: _refresh,
            );
          }
          final data = snapshot.data!;
          if (data.items.isEmpty) {
            return const _ContactMessage(
              text: 'No hay contactos que coincidan con estos filtros.',
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Solicitudes encontradas',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Chip(label: Text('${data.total} resultados')),
                  ],
                ),
              ),
              AdminDataTable(
                columns: const [
                  DataColumn(label: Text('Cliente')),
                  DataColumn(label: Text('Prestador')),
                  DataColumn(label: Text('Categoría')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Agenda')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: [
                  for (final contact in data.items)
                    DataRow(
                      onSelectChanged: (_) => _details(contact),
                      cells: [
                        DataCell(Text(contact.client.fullName)),
                        DataCell(Text(contact.provider.fullName)),
                        DataCell(Text(contact.category.name)),
                        DataCell(
                          AdminStatusBadge(
                            label: _statusLabel(contact.status),
                            positive:
                                contact.status == 'SCHEDULED' ||
                                contact.status == 'COMPLETED',
                          ),
                        ),
                        DataCell(
                          Text(
                            contact.scheduledFor == null
                                ? 'Sin agenda'
                                : MaterialLocalizations.of(context)
                                      .formatMediumDate(
                                        contact.scheduledFor!.toLocal(),
                                      ),
                          ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            tooltip: 'Cambiar estado del contacto',
                            onSelected: (status) =>
                                _changeStatus(contact, status),
                            itemBuilder: (context) => [
                              if (contact.status == 'PENDING')
                                const PopupMenuItem(
                                  value: 'SCHEDULED',
                                  child: Text('Agendar'),
                                ),
                              if (contact.status == 'PENDING' ||
                                  contact.status == 'SCHEDULED')
                                const PopupMenuItem(
                                  value: 'CANCELLED',
                                  child: Text('Cancelar'),
                                ),
                              if (contact.status == 'SCHEDULED')
                                const PopupMenuItem(
                                  value: 'COMPLETED',
                                  child: Text('Marcar completado'),
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
                            _contacts = _load();
                          }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Página $_page · ${data.total} contactos'),
                  IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: _page >= data.totalPages
                        ? null
                        : () => setState(() {
                            _page++;
                            _contacts = _load();
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

  Future<void> _details(AdminContact contact) async {
    try {
      final detail = await _repository.get(contact.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Detalle del contacto'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Cliente: ${detail.client.fullName}'),
                  Text('Prestador: ${detail.provider.fullName}'),
                  Text('Categoría: ${detail.category.name}'),
                  Text('Estado: ${_statusLabel(detail.status)}'),
                  if (detail.scheduledFor != null)
                    Text(
                      'Agendado para: ${MaterialLocalizations.of(context).formatMediumDate(detail.scheduledFor!.toLocal())}',
                    ),
                  const SizedBox(height: 12),
                  Text(
                    detail.problemDescription?.isNotEmpty == true
                        ? detail.problemDescription!
                        : 'Sin descripción del problema.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _changeStatus(AdminContact contact, String status) async {
    DateTime? scheduledFor;
    if (status == 'SCHEDULED') {
      final now = DateTime.now();
      scheduledFor = await showDatePicker(
        context: context,
        initialDate: now.add(const Duration(days: 1)),
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(now.year + 5),
        helpText: 'Elegí el día del contacto',
      );
      if (scheduledFor == null || !mounted) return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_statusAction(status)} contacto'),
        content: Text(
          status == 'SCHEDULED'
              ? '¿Agendar para ${MaterialLocalizations.of(context).formatMediumDate(scheduledFor!.toLocal())}?'
              : '¿${_statusAction(status)} el contacto entre ${contact.client.fullName} y ${contact.provider.fullName}?',
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
      await _repository.updateStatus(
        contact.id,
        status,
        context.read<AdminSession>().csrfToken,
        scheduledFor: scheduledFor,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contacto ${_statusLabel(status).toLowerCase()}.'),
        ),
      );
      _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    if (error is ApiFailure && error.isUnauthorized) {
      context.read<AdminSession>().expire();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is ApiFailure
              ? error.message
              : 'No se pudo completar la solicitud.',
        ),
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
  'PENDING' => 'Pendiente',
  'SCHEDULED' => 'Agendado',
  'COMPLETED' => 'Completado',
  _ => 'Cancelado',
};

String _statusAction(String status) => switch (status) {
  'SCHEDULED' => 'Agendar',
  'COMPLETED' => 'Marcar completado',
  _ => 'Cancelar',
};

class _ContactMessage extends StatelessWidget {
  const _ContactMessage({required this.text, this.onRetry});
  final String text;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        Text(text),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}
