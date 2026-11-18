import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/layout/admin_page_header.dart';
import '../../../app/layout/admin_filter_panel.dart';
import '../../../app/layout/admin_data_table.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../data/categories_remote_data_source.dart';
import '../data/categories_repository.dart';
import '../models/category.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});
  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String? _status;
  String? _active;
  String? _source;
  String? _target;
  final _searchController = TextEditingController();
  int _page = 1;
  late CategoriesRepository _repository;
  late Future<_CategoryView> _categories;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository = CategoriesRepository(
      CategoriesRemoteDataSource(context.read<ApiClient>()),
    );
    _categories = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_CategoryView> _load() async {
    final results = await Future.wait([
      _repository.list(
        CategoryFilters(
          status: _status,
          active: _active == null ? null : _active == 'true',
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          page: _page,
        ),
      ),
      _repository.list(const CategoryFilters(status: 'PENDING', limit: 100)),
      _repository.list(const CategoryFilters(status: 'APPROVED', limit: 100)),
    ]);
    return _CategoryView(results[0], results[1].items, results[2].items);
  }

  void _refresh() {
    setState(() {
      _categories = _load();
    });
  }

  Future<void> _editDialog([AdminCategory? category]) async {
    final value = await showDialog<_CategoryFormValue>(
      context: context,
      builder: (_) => _CategoryFormDialog(category: category),
    );
    if (value == null || !mounted) return;
    try {
      final csrf = context.read<AdminSession>().csrfToken;
      if (category == null) {
        await _repository.create(
          name: value.name,
          iconUrl: value.iconUrl,
          csrfToken: csrf,
        );
      } else {
        await _repository.edit(
          category.id,
          name: value.name,
          iconUrl: value.iconUrl,
          csrfToken: csrf,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category == null
                ? 'Categoría creada en estado pendiente.'
                : 'Categoría actualizada.',
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

  Future<void> _changeActive(AdminCategory category, bool active) async {
    final action = active ? 'activar' : 'desactivar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${action[0].toUpperCase()}${action.substring(1)} categoría',
        ),
        content: Text('¿Confirmás $action «${category.name}»?'),
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
      await _repository.setStatus(
        category.id,
        isActive: active,
        csrfToken: context.read<AdminSession>().csrfToken,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Estado actualizado.')));
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

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
    children: [
      AdminPageHeader(
        section: 'Gestión',
        title: 'Categorías',
        description: 'Organiza y revisa el catálogo de categorías.',
        icon: Icons.category_outlined,
        trailing: FilledButton.icon(
          onPressed: () => _editDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Nueva categoría'),
        ),
      ),
      const SizedBox(height: 24),
      AdminFilterPanel(
        title: 'Buscar y filtrar categorías',
        description:
            'Ajusta los resultados por nombre, aprobación y actividad.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: MediaQuery.sizeOf(context).width < 600
                      ? MediaQuery.sizeOf(context).width - 32
                      : 320,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar categoría',
                      hintText: 'Nombre de la categoría',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar búsqueda',
                              onPressed: () {
                                _searchController.clear();
                                _page = 1;
                                _refresh();
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      _page = 1;
                      _refresh();
                    },
                  ),
                ),
                DropdownButton<String?>(
                  value: _status,
                  hint: const Text('Todos los estados'),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Todos los estados'),
                    ),
                    DropdownMenuItem(
                      value: 'PENDING',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(
                      value: 'APPROVED',
                      child: Text('Aprobada'),
                    ),
                    DropdownMenuItem(
                      value: 'REJECTED',
                      child: Text('Rechazada'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _status = value;
                    _page = 1;
                    _categories = _load();
                  }),
                ),
                DropdownButton<String?>(
                  value: _active,
                  hint: const Text('Toda actividad'),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Toda actividad'),
                    ),
                    DropdownMenuItem(value: 'true', child: Text('Activas')),
                    DropdownMenuItem(value: 'false', child: Text('Inactivas')),
                  ],
                  onChanged: (value) => setState(() {
                    _active = value;
                    _page = 1;
                    _categories = _load();
                  }),
                ),
                IconButton.filledTonal(
                  tooltip: 'Actualizar categorías',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
                if (_status != null ||
                    _active != null ||
                    _searchController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      _status = null;
                      _active = null;
                      _searchController.clear();
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
      const SizedBox(height: 20),
      Text('Catálogo', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      FutureBuilder<_CategoryView>(
        future: _categories,
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
            return _CategoryMessage(
              message: snapshot.error is ApiFailure
                  ? (snapshot.error! as ApiFailure).message
                  : 'No se pudieron cargar las categorías.',
              onRetry: _refresh,
            );
          }
          final view = snapshot.data;
          final categoryPage = view?.page;
          final categories = categoryPage?.items ?? const <AdminCategory>[];
          if (categories.isEmpty) {
            return const _CategoryMessage(
              message: 'No hay categorías que coincidan con estos filtros.',
            );
          }
          final pending = view?.pending ?? const <AdminCategory>[];
          final approved = view?.approved ?? const <AdminCategory>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pending.isNotEmpty && approved.isNotEmpty)
                _UnifyCard(
                  pending: pending,
                  approved: approved,
                  source: _source,
                  target: _target,
                  onSource: (value) => setState(() => _source = value),
                  onTarget: (value) => setState(() => _target = value),
                  onComplete: _refresh,
                ),
              AdminDataTable(
                columns: const [
                  DataColumn(label: Text('Categoría')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Actividad')),
                  DataColumn(label: Text('Prestadores')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: [
                  for (final category in categories)
                    DataRow(
                      cells: [
                        DataCell(Text(category.name)),
                        DataCell(AdminStatusBadge(label: category.status)),
                        DataCell(
                          AdminStatusBadge(
                            label: category.isActive ? 'Activa' : 'Inactiva',
                            positive: category.isActive,
                          ),
                        ),
                        DataCell(
                          Text(
                            '${category.primaryCount} principales · ${category.secondaryCount} secundarias',
                          ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            tooltip: 'Acciones de categoría',
                            onSelected: (action) {
                              if (action == 'edit') {
                                _editDialog(category);
                              }
                              if (action == 'active') {
                                _changeActive(category, !category.isActive);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'active',
                                child: Text(
                                  category.isActive ? 'Desactivar' : 'Activar',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Página anterior',
                    onPressed: _page <= 1
                        ? null
                        : () => setState(() {
                            _page--;
                            _categories = _load();
                          }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Página $_page'),
                  IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: _page >= (categoryPage?.totalPages ?? 0)
                        ? null
                        : () => setState(() {
                            _page++;
                            _categories = _load();
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
}

class _UnifyCard extends StatelessWidget {
  const _UnifyCard({
    required this.pending,
    required this.approved,
    required this.source,
    required this.target,
    required this.onSource,
    required this.onTarget,
    required this.onComplete,
  });
  final List<AdminCategory> pending;
  final List<AdminCategory> approved;
  final String? source;
  final String? target;
  final ValueChanged<String?> onSource;
  final ValueChanged<String?> onTarget;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unificar categoría pendiente',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              DropdownButton<String>(
                value: source,
                hint: const Text('Categoría de origen'),
                items: [
                  for (final item in pending)
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
                ],
                onChanged: onSource,
              ),
              DropdownButton<String>(
                value: target,
                hint: const Text('Categoría aprobada destino'),
                items: [
                  for (final item in approved)
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
                ],
                onChanged: onTarget,
              ),
              FilledButton(
                onPressed: source == null || target == null
                    ? null
                    : () => _confirm(context),
                child: const Text('Unificar'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _confirm(BuildContext context) async {
    final from = pending.firstWhere((item) => item.id == source);
    final to = approved.firstWhere((item) => item.id == target);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar unificación'),
        content: Text(
          'Se reasignarán las referencias de «${from.name}» a «${to.name}». La categoría de origen dejará de estar disponible. ¿Continuar?',
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
    if (confirmed != true || !context.mounted) return;
    try {
      final session = context.read<AdminSession>();
      final result = await CategoriesRepository(
        CategoriesRemoteDataSource(context.read<ApiClient>()),
      ).unify(source!, target!, csrfToken: session.csrfToken);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unificación confirmada. ${result['updatedProvidersCount'] ?? 0} prestadores afectados.',
          ),
        ),
      );
      onComplete();
    } on ApiFailure catch (error) {
      if (error.isUnauthorized && context.mounted) {
        context.read<AdminSession>().expire();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _CategoryMessage extends StatelessWidget {
  const _CategoryMessage({required this.message, this.onRetry});
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

class _CategoryView {
  const _CategoryView(this.page, this.pending, this.approved);
  final CategoryPage page;
  final List<AdminCategory> pending;
  final List<AdminCategory> approved;
}

class _CategoryFormValue {
  const _CategoryFormValue(this.name, this.iconUrl);
  final String name;
  final String? iconUrl;
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.category});
  final AdminCategory? category;
  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _icon;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _icon = TextEditingController(text: widget.category?.iconUrl ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.category == null ? 'Nueva categoría' : 'Editar categoría',
    ),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Ingresá al menos 2 caracteres'
                  : null,
            ),
            TextFormField(
              controller: _icon,
              decoration: const InputDecoration(
                labelText: 'URL del ícono (opcional)',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return Uri.tryParse(value)?.hasAbsolutePath == true
                    ? null
                    : 'Ingresá una URL válida';
              },
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
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            _CategoryFormValue(
              _name.text.trim(),
              _icon.text.trim().isEmpty ? null : _icon.text.trim(),
            ),
          );
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}
