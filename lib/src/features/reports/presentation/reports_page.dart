import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/layout/admin_page_header.dart';
import '../../../app/layout/admin_filter_panel.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/network/api_client.dart';
import '../data/reports_remote_data_source.dart';
import '../data/reports_repository.dart';
import '../models/report.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String? _type;
  String? _resolved;
  int _page = 1;
  late ReportsRepository _repository;
  late Future<ReportPage> _reports;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository = ReportsRepository(
      ReportsRemoteDataSource(context.read<ApiClient>()),
    );
    _reports = _load();
  }

  Future<ReportPage> _load() => _repository.list(
    ReportFilters(
      type: _type,
      isResolved: _resolved == null ? null : _resolved == 'true',
      page: _page,
    ),
  );

  void _refresh() {
    setState(() {
      _reports = _load();
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
    children: [
      const AdminPageHeader(
        section: 'Operaciones',
        title: 'Reportes',
        description: 'Revisa los reportes y resuelve los casos pendientes.',
        icon: Icons.flag_outlined,
      ),
      const SizedBox(height: 24),
      AdminFilterPanel(
        title: 'Filtrar reportes',
        description: 'Selecciona un tipo y el estado de resolución.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                DropdownButton<String?>(
                  value: _type,
                  hint: const Text('Todos los tipos'),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Todos los tipos'),
                    ),
                    DropdownMenuItem(
                      value: 'SUGGESTION',
                      child: Text('Sugerencia'),
                    ),
                    DropdownMenuItem(value: 'CLAIM', child: Text('Reclamo')),
                    DropdownMenuItem(
                      value: 'USER_REPORT',
                      child: Text('Reporte de usuario'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _type = value;
                    _page = 1;
                    _reports = _load();
                  }),
                ),
                DropdownButton<String?>(
                  value: _resolved,
                  hint: const Text('Todos los estados'),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Todos los estados'),
                    ),
                    DropdownMenuItem(value: 'false', child: Text('Pendientes')),
                    DropdownMenuItem(value: 'true', child: Text('Resueltos')),
                  ],
                  onChanged: (value) => setState(() {
                    _resolved = value;
                    _page = 1;
                    _reports = _load();
                  }),
                ),
                IconButton.filledTonal(
                  tooltip: 'Actualizar reportes',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
                if (_type != null || _resolved != null)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _type = null;
                      _resolved = null;
                      _page = 1;
                      _reports = _load();
                    }),
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Limpiar filtros'),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Bandeja de reportes',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      FutureBuilder<ReportPage>(
        future: _reports,
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
                  : 'No se pudieron cargar los reportes.',
              onRetry: _refresh,
            );
          }
          final reportPage = snapshot.data;
          final reports = reportPage?.items ?? const <Report>[];
          if (reports.isEmpty) {
            return const _Message(
              message: 'No hay reportes que coincidan con estos filtros.',
            );
          }
          return Column(
            children: [
              for (final report in reports)
                _ReportCard(report: report, onResolved: _refresh),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Página anterior',
                    onPressed: _page <= 1
                        ? null
                        : () => setState(() {
                            _page--;
                            _reports = _load();
                          }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Página $_page'),
                  IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: _page >= (reportPage?.totalPages ?? 0)
                        ? null
                        : () => setState(() {
                            _page++;
                            _reports = _load();
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onResolved});
  final Report report;
  final VoidCallback onResolved;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _reportType(report.type),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Chip(label: Text(report.isResolved ? 'Resuelto' : 'Pendiente')),
              if (report.createdAt != null)
                Text(
                  MaterialLocalizations.of(context)
                      .formatMediumDate(report.createdAt!.toLocal()),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(report.content),
          const SizedBox(height: 14),
          Text(
            'Reportado por ${report.author.displayName}${report.author.email == null ? '' : ' · ${report.author.email}'}',
          ),
          if (!report.isResolved)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _resolve(context),
                icon: const Icon(Icons.check),
                label: const Text('Resolver'),
              ),
            ),
        ],
      ),
    ),
  );

  Future<void> _resolve(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolver reporte'),
        content: const Text(
          'Se marcará este reporte como resuelto. ¿Querés continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resolver'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final session = context.read<AdminSession>();
      await ReportsRepository(
        ReportsRemoteDataSource(context.read<ApiClient>()),
      ).resolve(report.id, session.csrfToken);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El reporte quedó resuelto.')),
      );
      onResolved();
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

  String _reportType(String type) => switch (type) {
    'SUGGESTION' => 'Sugerencia',
    'CLAIM' => 'Reclamo',
    _ => 'Reporte de usuario',
  };
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.onRetry});
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
