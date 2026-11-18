import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/layout/admin_filter_panel.dart';
import '../../../app/layout/admin_data_table.dart';
import '../../../app/layout/admin_page_header.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../data/memberships_remote_data_source.dart';
import '../data/memberships_repository.dart';
import '../models/admin_membership.dart';

class MembershipsPage extends StatefulWidget {
  const MembershipsPage({super.key});
  @override
  State<MembershipsPage> createState() => _MembershipsPageState();
}

class _MembershipsPageState extends State<MembershipsPage> {
  final _tierSearch = TextEditingController();
  late final MembershipsRepository _repository;
  late Future<AdminMembershipData> _data;
  bool _includeArchived = false;
  String? _providerId;
  String? _tierId;

  @override
  void dispose() {
    _tierSearch.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _repository = MembershipsRepository(
      MembershipsRemoteDataSource(context.read<ApiClient>()),
    );
    _data = _load();
  }

  Future<AdminMembershipData> _load() =>
      _repository.load(includeArchived: _includeArchived);
  void _refresh() {
    setState(() {
      _data = _load();
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
    children: [
      AdminPageHeader(
        section: 'Gestión',
        title: 'Membresías',
        description: 'Administra los niveles y asignaciones actuales.',
        icon: Icons.card_membership_outlined,
        trailing: FilledButton.icon(
          onPressed: _editTier,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo nivel'),
        ),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: Text(
              'Asignar nivel a prestador',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            tooltip: 'Actualizar niveles',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      const SizedBox(height: 8),
      FutureBuilder<AdminMembershipData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          if (snapshot.hasError) {
            if (snapshot.error is ApiFailure &&
                (snapshot.error! as ApiFailure).isUnauthorized) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => context.read<AdminSession>().expire(),
              );
            }
            return _MembershipMessage(
              text: snapshot.error is ApiFailure
                  ? (snapshot.error! as ApiFailure).message
                  : 'No se pudieron cargar los niveles.',
              onRetry: _refresh,
            );
          }
          final data = snapshot.data!;
          final visibleTiers = data.tiers
              .where((tier) {
                final query = _tierSearch.text.trim().toLowerCase();
                return query.isEmpty || tier.name.toLowerCase().contains(query);
              })
              .toList(growable: false);
          final activeTiers = data.tiers
              .where((tier) => !tier.isArchived)
              .toList(growable: false);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width < 600
                        ? MediaQuery.sizeOf(context).width - 32
                        : 320,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _providerId,
                      decoration: const InputDecoration(labelText: 'Prestador'),
                      items: [
                        for (final provider in data.providers)
                          DropdownMenuItem<String?>(
                            value: provider.id,
                            child: Text(
                              '${provider.name}${provider.tierName == null ? '' : ' · ${provider.tierName}'}',
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _providerId = value),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _tierId,
                      decoration: const InputDecoration(
                        labelText: 'Nivel activo',
                      ),
                      items: [
                        for (final tier in activeTiers)
                          DropdownMenuItem<String?>(
                            value: tier.id,
                            child: Text('${tier.name} · ARS ${tier.price}'),
                          ),
                      ],
                      onChanged: (value) => setState(() => _tierId = value),
                    ),
                  ),
                  FilledButton(
                    onPressed: _providerId == null || _tierId == null
                        ? null
                        : () => _assign(data),
                    child: const Text('Asignar'),
                  ),
                ],
              ),
              const Divider(height: 36),
              AdminFilterPanel(
                title: 'Niveles de membresía',
                description: 'Busca niveles y elige si incluir los archivados.',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width < 600
                          ? MediaQuery.sizeOf(context).width - 32
                          : 320,
                      child: TextField(
                        controller: _tierSearch,
                        decoration: InputDecoration(
                          labelText: 'Buscar nivel',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _tierSearch.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpiar búsqueda',
                                  onPressed: () {
                                    _tierSearch.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    FilterChip(
                      label: const Text('Incluir archivados'),
                      selected: _includeArchived,
                      onSelected: (value) => setState(() {
                        _includeArchived = value;
                        _data = _load();
                      }),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Niveles disponibles',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Chip(label: Text('${visibleTiers.length} niveles')),
                  ],
                ),
              ),
              if (visibleTiers.isEmpty)
                const _MembershipMessage(
                  text: 'No hay niveles que coincidan con estos filtros.',
                ),
              AdminDataTable(
                columns: const [
                  DataColumn(label: Text('Nivel')),
                  DataColumn(label: Text('Descripción')),
                  DataColumn(label: Text('Precio')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: [
                  for (final tier in visibleTiers)
                    DataRow(
                      cells: [
                        DataCell(Text(tier.name)),
                        DataCell(
                          Text(
                            tier.description?.isNotEmpty == true
                                ? tier.description!
                                : 'Sin descripción',
                          ),
                        ),
                        DataCell(Text('ARS ${tier.price}')),
                        DataCell(
                          AdminStatusBadge(
                            label: tier.isArchived ? 'Archivado' : 'Activo',
                            positive: !tier.isArchived,
                          ),
                        ),
                        DataCell(
                          tier.isArchived
                              ? const Icon(Icons.archive_outlined)
                              : PopupMenuButton<String>(
                                  tooltip: 'Acciones del nivel',
                                  onSelected: (action) => action == 'edit'
                                      ? _editTier(tier)
                                      : _archive(tier),
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Editar'),
                                    ),
                                    PopupMenuItem(
                                      value: 'archive',
                                      child: Text('Archivar'),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    ],
  );

  Future<void> _editTier([AdminMembershipTier? tier]) async {
    final input = await showDialog<_TierInput>(
      context: context,
      builder: (context) => _TierEditDialog(tier: tier),
    );
    if (input == null || !mounted) return;
    try {
      final csrf = context.read<AdminSession>().csrfToken;
      if (tier == null) {
        await _repository.create(
          name: input.name,
          description: input.description,
          price: input.price,
          csrfToken: csrf,
        );
      } else {
        await _repository.update(
          tier.id,
          name: input.name,
          description: input.description,
          price: input.price,
          csrfToken: csrf,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tier == null ? 'Nivel creado.' : 'Nivel actualizado.'),
        ),
      );
      _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _archive(AdminMembershipTier tier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar nivel'),
        content: Text(
          'Se conservarán las asignaciones actuales a “${tier.name}”. No se podrán hacer nuevas asignaciones a este nivel. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.archive(
        tier.id,
        context.read<AdminSession>().csrfToken,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nivel archivado.')));
      _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _assign(AdminMembershipData data) async {
    final providers = data.providers
        .where((item) => item.id == _providerId)
        .toList();
    final tiers = data.tiers
        .where((item) => item.id == _tierId && !item.isArchived)
        .toList();
    final provider = providers.isEmpty ? null : providers.first;
    final tier = tiers.isEmpty ? null : tiers.first;
    if (provider == null || tier == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar asignación'),
        content: Text(
          '¿Asignar “${tier.name}” a ${provider.name}? La asignación se guardará en la cuenta del prestador.',
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
      await _repository.assign(
        provider.id,
        tier.id,
        context.read<AdminSession>().csrfToken,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nivel asignado.')));
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
              : 'No se pudo completar la operación.',
        ),
      ),
    );
  }
}

class _TierInput {
  const _TierInput(this.name, this.description, this.price);
  final String name;
  final String? description;
  final int price;
}

class _TierEditDialog extends StatefulWidget {
  const _TierEditDialog({this.tier});
  final AdminMembershipTier? tier;
  @override
  State<_TierEditDialog> createState() => _TierEditDialogState();
}

class _TierEditDialogState extends State<_TierEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.tier?.name ?? '');
  late final _description = TextEditingController(
    text: widget.tier?.description ?? '',
  );
  late final _price = TextEditingController(
    text: widget.tier?.price.toString() ?? '0',
  );
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.tier == null ? 'Nuevo nivel' : 'Editar nivel'),
    content: Form(
      key: _formKey,
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Campo obligatorio'
                  : null,
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLength: 255,
            ),
            TextFormField(
              controller: _price,
              decoration: const InputDecoration(
                labelText: 'Precio entero (ARS)',
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  int.tryParse(value ?? '') == null || int.parse(value!) < 0
                  ? 'Ingresá un entero no negativo'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(
              context,
              _TierInput(
                _name.text.trim(),
                _description.text.trim().isEmpty
                    ? null
                    : _description.text.trim(),
                int.parse(_price.text),
              ),
            );
          }
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}

class _MembershipMessage extends StatelessWidget {
  const _MembershipMessage({required this.text, this.onRetry});
  final String text;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Text(text),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}
