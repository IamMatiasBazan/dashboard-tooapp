import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/layout/admin_filter_panel.dart';
import '../../../app/layout/admin_data_table.dart';
import '../../../app/layout/admin_page_header.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../data/reviews_remote_data_source.dart';
import '../data/reviews_repository.dart';
import '../models/admin_review.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});
  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final _providerId = TextEditingController();
  final _authorId = TextEditingController();
  late final ReviewsRepository _repository;
  late Future<AdminReviewPage> _reviews;
  String? _visibility;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _repository = ReviewsRepository(
      ReviewsRemoteDataSource(context.read<ApiClient>()),
    );
    _reviews = _load();
  }

  @override
  void dispose() {
    _providerId.dispose();
    _authorId.dispose();
    super.dispose();
  }

  Future<AdminReviewPage> _load() => _repository.list(
    AdminReviewFilters(
      visibility: _visibility,
      providerId: _providerId.text,
      authorId: _authorId.text,
      page: _page,
    ),
  );

  void _refresh() {
    setState(() {
      _reviews = _load();
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
    children: [
      const AdminPageHeader(
        section: 'Personas',
        title: 'Reseñas',
        description:
            'Modera la visibilidad y consulta las opiniones recibidas.',
        icon: Icons.rate_review_outlined,
      ),
      const SizedBox(height: 24),
      AdminFilterPanel(
        title: 'Filtrar reseñas',
        description: 'Acotá por visibilidad o identificador de perfil.',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String?>(
              value: _visibility,
              hint: const Text('Cualquier visibilidad'),
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Cualquier visibilidad'),
                ),
                DropdownMenuItem<String?>(
                  value: 'VISIBLE',
                  child: Text('Visibles'),
                ),
                DropdownMenuItem<String?>(
                  value: 'HIDDEN',
                  child: Text('Ocultas'),
                ),
              ],
              onChanged: (value) => setState(() {
                _visibility = value;
                _page = 1;
                _reviews = _load();
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
                controller: _authorId,
                decoration: const InputDecoration(
                  labelText: 'Autor · ID',
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
              tooltip: 'Actualizar reseñas',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
            if (_visibility != null ||
                _providerId.text.isNotEmpty ||
                _authorId.text.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  _visibility = null;
                  _providerId.clear();
                  _authorId.clear();
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
        'Reseñas recibidas',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      FutureBuilder<AdminReviewPage>(
        future: _reviews,
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
            return _ReviewMessage(
              text: snapshot.error is ApiFailure
                  ? (snapshot.error! as ApiFailure).message
                  : 'No se pudieron cargar las reseñas.',
              onRetry: _refresh,
            );
          }
          final data = snapshot.data!;
          if (data.items.isEmpty) {
            return const _ReviewMessage(
              text: 'No hay reseñas que coincidan con estos filtros.',
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
                        'Reseñas encontradas',
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
                  DataColumn(label: Text('Autor')),
                  DataColumn(label: Text('Evaluado')),
                  DataColumn(label: Text('Puntaje')),
                  DataColumn(label: Text('Visibilidad')),
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: [
                  for (final review in data.items)
                    DataRow(
                      onSelectChanged: (_) => _details(review),
                      cells: [
                        DataCell(Text(review.author.fullName)),
                        DataCell(Text(review.target.fullName)),
                        DataCell(
                          Text(
                            review.rating == null
                                ? 'Sin puntaje'
                                : '${review.rating}/5',
                          ),
                        ),
                        DataCell(
                          AdminStatusBadge(
                            label: review.visibility == 'VISIBLE'
                                ? 'Visible'
                                : 'Oculta',
                            positive: review.visibility == 'VISIBLE',
                          ),
                        ),
                        DataCell(
                          Text(
                            review.createdAt == null
                                ? 'Sin fecha'
                                : MaterialLocalizations.of(context)
                                      .formatMediumDate(
                                        review.createdAt!.toLocal(),
                                      ),
                          ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            tooltip: 'Moderar reseña',
                            onSelected: (_) => _moderate(review),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  review.visibility == 'VISIBLE'
                                      ? 'Ocultar'
                                      : 'Restaurar',
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
                            _reviews = _load();
                          }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Página $_page · ${data.total} reseñas'),
                  IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: _page >= data.totalPages
                        ? null
                        : () => setState(() {
                            _page++;
                            _reviews = _load();
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

  Future<void> _details(AdminReview item) async {
    try {
      final review = await _repository.get(item.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _ReviewDetailsDialog(review: review),
      );
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _moderate(AdminReview review) async {
    final target = review.visibility == 'VISIBLE' ? 'HIDDEN' : 'VISIBLE';
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _ModerationReasonDialog(target: target),
    );
    if (reason == null || !mounted) return;
    try {
      await _repository.setVisibility(
        review.id,
        target,
        reason,
        context.read<AdminSession>().csrfToken,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            target == 'HIDDEN' ? 'Reseña ocultada.' : 'Reseña restaurada.',
          ),
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

class _ReviewDetailsDialog extends StatelessWidget {
  const _ReviewDetailsDialog({required this.review});
  final AdminReview review;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Reseña de ${review.author.fullName}'),
    content: SizedBox(
      width: 580,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Destinatario: ${review.target.fullName}'),
            Text(
              'Visibilidad: ${review.visibility == 'VISIBLE' ? 'Visible' : 'Oculta'}',
            ),
            Text('Puntaje: ${review.rating?.toString() ?? 'Sin puntaje'}'),
            if (review.contactStatus != null)
              Text('Contacto: ${review.contactStatus}'),
            const SizedBox(height: 12),
            Text(
              review.comment?.isNotEmpty == true
                  ? review.comment!
                  : 'Sin comentario.',
            ),
            const Divider(height: 28),
            Text(
              'Historial de moderación',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (review.auditEvents.isEmpty)
              const Text('Todavía no hay cambios de moderación.'),
            for (final event in review.auditEvents)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_auditAction(event.action)),
                subtitle: Text(
                  '${event.reason ?? 'Sin motivo'} · actor ${event.actorId}',
                ),
                trailing: event.createdAt == null
                    ? null
                    : Text(
                        MaterialLocalizations.of(context)
                            .formatMediumDate(event.createdAt!.toLocal()),
                      ),
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
}

class _ModerationReasonDialog extends StatefulWidget {
  const _ModerationReasonDialog({required this.target});
  final String target;
  @override
  State<_ModerationReasonDialog> createState() =>
      _ModerationReasonDialogState();
}

class _ModerationReasonDialogState extends State<_ModerationReasonDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.target == 'HIDDEN' ? 'Ocultar reseña' : 'Restaurar reseña',
    ),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        maxLength: 500,
        decoration: const InputDecoration(labelText: 'Motivo obligatorio'),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Escribí un motivo.' : null,
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
            Navigator.pop(context, _controller.text.trim());
          }
        },
        child: const Text('Confirmar'),
      ),
    ],
  );
}

String _auditAction(String action) => switch (action) {
  'REVIEW_HIDDEN' => 'Reseña ocultada',
  'REVIEW_RESTORED' => 'Reseña restaurada',
  _ => action,
};

class _ReviewMessage extends StatelessWidget {
  const _ReviewMessage({required this.text, this.onRetry});
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
