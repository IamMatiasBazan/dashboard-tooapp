import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/layout/admin_page_header.dart';
import '../../../app/layout/admin_filter_panel.dart';
import '../../../app/layout/admin_data_table.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../data/providers_remote_data_source.dart';
import '../data/providers_repository.dart';
import '../models/admin_provider.dart';

class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key});
  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  final _search = TextEditingController();
  late final ProvidersRepository _repository;
  late final Future<AdminProviderFiltersData> _filters;
  late Future<AdminProviderPage> _providers;
  String? _categoryId;
  String? _localityId;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _repository = ProvidersRepository(
      ProvidersRemoteDataSource(context.read<ApiClient>()),
    );
    _filters = _repository.filters();
    _providers = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<AdminProviderPage> _load() => _repository.list(
    AdminProviderFilters(
      search: _search.text,
      categoryId: _categoryId,
      localityId: _localityId,
      page: _page,
    ),
  );

  void _refresh() {
    setState(() {
      _providers = _load();
    });
  }

  void _handleError(Object error) {
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

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
    children: [
      const AdminPageHeader(
        section: 'Personas',
        title: 'Prestadores',
        description: 'Explora perfiles y su información profesional.',
        icon: Icons.handyman_outlined,
      ),
      const SizedBox(height: 24),
      AdminFilterPanel(
        title: 'Buscar y filtrar prestadores',
        description: 'Busca perfiles y acota por categoría o localidad.',
        child: Column(
          children: [
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Nombre del prestador',
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
            FutureBuilder<AdminProviderFiltersData>(
              future: _filters,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No se pudieron cargar categorías y localidades.',
                    ),
                  );
                }
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final data = snapshot.data!;
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    DropdownButton<String?>(
                      value: _categoryId,
                      hint: const Text('Todas las categorías'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las categorías'),
                        ),
                        for (final category in data.categories)
                          DropdownMenuItem<String?>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _categoryId = value;
                        _page = 1;
                        _providers = _load();
                      }),
                    ),
                    DropdownButton<String?>(
                      value: _localityId,
                      hint: const Text('Todas las localidades'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las localidades'),
                        ),
                        for (final locality in data.localities)
                          DropdownMenuItem<String?>(
                            value: locality.id,
                            child: Text(locality.name),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _localityId = value;
                        _page = 1;
                        _providers = _load();
                      }),
                    ),
                    IconButton(
                      tooltip: 'Actualizar prestadores',
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                    if (_categoryId != null ||
                        _localityId != null ||
                        _search.text.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          _search.clear();
                          _categoryId = null;
                          _localityId = null;
                          _page = 1;
                          _refresh();
                        },
                        icon: const Icon(Icons.filter_alt_off_outlined),
                        label: const Text('Limpiar filtros'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Directorio de prestadores',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      FutureBuilder<AdminProviderPage>(
        future: _providers,
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
            return _Message(
              text: snapshot.error is ApiFailure
                  ? (snapshot.error! as ApiFailure).message
                  : 'No se pudieron cargar los prestadores.',
              onRetry: _refresh,
            );
          }
          final data = snapshot.data!;
          if (data.items.isEmpty) {
            return const _Message(
              text: 'No hay prestadores que coincidan con estos filtros.',
            );
          }
          return Column(
            children: [
              AdminDataTable(
                columns: const [
                  DataColumn(label: Text('Prestador')),
                  DataColumn(label: Text('Categoría')),
                  DataColumn(label: Text('Localidad')),
                  DataColumn(label: Text('Cuenta')),
                  DataColumn(label: Text('Disponibilidad')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: [
                  for (final provider in data.items)
                    DataRow(
                      onSelectChanged: (_) => _openDetails(provider),
                      cells: [
                        DataCell(Text(provider.fullName)),
                        DataCell(Text(provider.primaryCategory.name)),
                        DataCell(
                          Text(provider.locality?.name ?? 'Sin localidad'),
                        ),
                        DataCell(
                          AdminStatusBadge(
                            label: provider.isAccountActive
                                ? 'Activa'
                                : 'Desactivada',
                            positive: provider.isAccountActive,
                          ),
                        ),
                        DataCell(
                          AdminStatusBadge(
                            label: provider.isAvailable
                                ? 'Disponible'
                                : 'No disponible',
                            positive: provider.isAvailable,
                          ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            tooltip: 'Acciones de prestador',
                            onSelected: (value) => value == 'edit'
                                ? _edit(provider)
                                : _toggleActive(provider),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar ficha'),
                              ),
                              PopupMenuItem(
                                value: 'active',
                                child: Text(
                                  provider.isAccountActive
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
                            _providers = _load();
                          }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Página $_page · ${data.total} prestadores'),
                  IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: _page >= data.totalPages
                        ? null
                        : () => setState(() {
                            _page++;
                            _providers = _load();
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

  Future<void> _openDetails(AdminProvider provider) async {
    try {
      final details = await _repository.get(provider.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) =>
            _ProviderDetailsDialog(provider: details, repository: _repository),
      );
    } catch (error) {
      if (mounted) _handleError(error);
    }
  }

  Future<void> _edit(AdminProvider provider) async {
    try {
      final details = await _repository.get(provider.id);
      final filterData = await _filters;
      if (!mounted) return;
      final changes = await showDialog<Map<String, Object?>>(
        context: context,
        builder: (context) =>
            _ProviderEditDialog(provider: details, filterData: filterData),
      );
      if (changes == null || !mounted) return;
      await _repository.update(
        details.id,
        changes,
        context.read<AdminSession>().csrfToken,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ficha actualizada.')));
      _refresh();
    } catch (error) {
      if (mounted) _handleError(error);
    }
  }

  Future<void> _toggleActive(AdminProvider provider) async {
    final target = !provider.isAccountActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(target ? 'Reactivar cuenta' : 'Desactivar cuenta'),
        content: Text(
          target
              ? '¿Reactivar la cuenta de ${provider.fullName}?'
              : 'Se revocarán las sesiones activas de ${provider.fullName}. La disponibilidad del prestador no se modifica. ¿Continuar?',
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
        provider.id,
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
    } catch (error) {
      if (mounted) _handleError(error);
    }
  }
}

class _ProviderDetailsDialog extends StatefulWidget {
  const _ProviderDetailsDialog({
    required this.provider,
    required this.repository,
  });
  final AdminProvider provider;
  final ProvidersRepository repository;
  @override
  State<_ProviderDetailsDialog> createState() => _ProviderDetailsDialogState();
}

class _ProviderDetailsDialogState extends State<_ProviderDetailsDialog> {
  late Future<List<AdminPortfolioImage>> _images = widget.repository.portfolio(
    widget.provider.id,
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.provider.fullName),
    content: SizedBox(
      width: 620,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Categoría principal: ${widget.provider.primaryCategory.name}',
            ),
            Text(
              'Otras categorías: ${widget.provider.secondaryCategories.map((item) => item.name).join(', ').isEmpty ? 'Ninguna' : widget.provider.secondaryCategories.map((item) => item.name).join(', ')}',
            ),
            Text(
              'Localidad: ${widget.provider.locality?.name ?? 'Sin localidad'}',
            ),
            Text('Teléfono: ${widget.provider.phone}'),
            if (widget.provider.email != null)
              Text('Email: ${widget.provider.email}'),
            Text(
              'Cuenta: ${widget.provider.isAccountActive ? 'Activa' : 'Desactivada'}',
            ),
            Text(
              'Disponibilidad: ${widget.provider.isAvailable ? 'Disponible' : 'No disponible'}',
            ),
            Text('Experiencia: ${widget.provider.experienceYears} años'),
            if (widget.provider.bio?.isNotEmpty == true)
              Text('Perfil: ${widget.provider.bio}'),
            const Divider(),
            Text('Portafolio', style: Theme.of(context).textTheme.titleMedium),
            FutureBuilder<List<AdminPortfolioImage>>(
              future: _images,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Text('No se pudo cargar el portafolio.');
                }
                if (snapshot.data!.isEmpty) {
                  return const Text('No hay imágenes en el portafolio.');
                }
                return Column(
                  children: [
                    for (final image in snapshot.data!)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: SelectableText(image.imageUrl, maxLines: 2),
                        subtitle: Text(
                          image.isVisible ? 'Visible públicamente' : 'Oculta',
                        ),
                        trailing: TextButton(
                          onPressed: () => _changeVisibility(image),
                          child: Text(
                            image.isVisible ? 'Ocultar' : 'Restaurar',
                          ),
                        ),
                      ),
                  ],
                );
              },
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
  );

  Future<void> _changeVisibility(AdminPortfolioImage image) async {
    final target = !image.isVisible;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(target ? 'Restaurar imagen' : 'Ocultar imagen'),
        content: Text(
          target ? 'La imagen volverá a mostrarse en el perfil público.' : 'La imagen dejará de mostrarse públicamente. El archivo original se conservará.',
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
      final reason = await _portfolioReason(context);
      if (reason == null || !mounted) return;
      await widget.repository.setImageVisibility(
        widget.provider.id,
        image.id,
        target,
        reason,
        context.read<AdminSession>().csrfToken,
      );
      if (!mounted) return;
      setState(() {
        _images = widget.repository.portfolio(widget.provider.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(target ? 'Imagen restaurada.' : 'Imagen ocultada.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiFailure
                ? error.message
                : 'No se pudo cambiar la visibilidad de la imagen.',
          ),
        ),
      );
    }
  }
}

class _ProviderEditDialog extends StatefulWidget {
  const _ProviderEditDialog({required this.provider, required this.filterData});
  final AdminProvider provider;
  final AdminProviderFiltersData filterData;
  @override
  State<_ProviderEditDialog> createState() => _ProviderEditDialogState();
}

class _ProviderEditDialogState extends State<_ProviderEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(
    text: widget.provider.firstName,
  );
  late final _lastName = TextEditingController(text: widget.provider.lastName);
  late final _phone = TextEditingController(text: widget.provider.phone);
  late final _bio = TextEditingController(text: widget.provider.bio ?? '');
  late final _experience = TextEditingController(
    text: widget.provider.experienceYears.toString(),
  );
  late final _minimumPrice = TextEditingController(
    text: widget.provider.minPrice?.toString() ?? '',
  );
  late String _categoryId;
  bool _isMatriculado = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.provider.primaryCategory.id;
    _isMatriculado = widget.provider.isMatriculado;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _bio.dispose();
    _experience.dispose();
    _minimumPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar ficha del prestador'),
    content: SizedBox(
      width: 520,
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
              TextFormField(
                controller: _bio,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción profesional',
                ),
              ),
              TextFormField(
                controller: _experience,
                decoration: const InputDecoration(
                  labelText: 'Años de experiencia',
                ),
                keyboardType: TextInputType.number,
                validator: _nonNegativeInteger,
              ),
              TextFormField(
                controller: _minimumPrice,
                decoration: const InputDecoration(
                  labelText: 'Precio mínimo (ARS)',
                ),
                keyboardType: TextInputType.number,
                validator: _optionalNonNegativeInteger,
              ),
              CheckboxListTile(
                value: _isMatriculado,
                contentPadding: EdgeInsets.zero,
                title: const Text('Está matriculado'),
                onChanged: (value) =>
                    setState(() => _isMatriculado = value ?? false),
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
  String? _nonNegativeInteger(String? value) =>
      int.tryParse(value ?? '') == null || int.parse(value!) < 0
      ? 'Ingresá un número entero válido'
      : null;
  String? _optionalNonNegativeInteger(String? value) =>
      value == null ||
          value.trim().isEmpty ||
          (int.tryParse(value) != null && int.parse(value) >= 0)
      ? null
      : 'Ingresá un número entero válido';
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'user': {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'phone': _phone.text.trim(),
      },
      'profile': {
        'primaryCategoryId': _categoryId,
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'experienceYears': int.parse(_experience.text),
        'minPrice': _minimumPrice.text.trim().isEmpty
            ? null
            : int.parse(_minimumPrice.text),
        'isMatriculado': _isMatriculado,
      },
    });
  }
}

Future<String?> _portfolioReason(BuildContext context) async {
  final controller = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Motivo del cambio'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Motivo requerido'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) Navigator.pop(dialogContext, reason);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});
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
