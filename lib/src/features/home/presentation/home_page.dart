import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/admin_theme.dart';
import '../data/home_remote_data_source.dart';
import '../data/home_repository.dart';
import '../models/admin_home_summary.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _periodDays = 7;
  HomeRepository? _repository;
  Future<AdminHomeSummary>? _summary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repository != null) return;
    _repository = HomeRepository(
      HomeRemoteDataSource(context.read<ApiClient>()),
    );
    _summary = _repository!.summary(_periodDays);
  }

  void _selectPeriod(int days) {
    if (_periodDays == days) return;
    setState(() {
      _periodDays = days;
      _summary = _repository!.summary(days);
    });
  }

  void _retry() {
    setState(() => _summary = _repository!.summary(_periodDays));
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AdminSession>().displayName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 600 ? 20.0 : 32.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(padding, 28, padding, 36),
          children: [
            Text(
              'Inicio',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              name == null || name.isEmpty
                  ? 'Resumen de actividad de TooApp.'
                  : 'Hola, $name. Este es el resumen de actividad de TooApp.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            FutureBuilder<AdminHomeSummary>(
              future: _summary,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingSummary();
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return _SummaryError(
                    onRetry: _retry,
                    error: snapshot.error,
                  );
                }
                return _SummarySections(
                  summary: snapshot.requireData,
                  periodDays: _periodDays,
                  onPeriodChanged: _selectPeriod,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _SummarySections extends StatelessWidget {
  const _SummarySections({
    required this.summary,
    required this.periodDays,
    required this.onPeriodChanged,
  });

  final AdminHomeSummary summary;
  final int periodDays;
  final ValueChanged<int> onPeriodChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _MetricSection(
        title: 'Resumen del sistema',
        metrics: [
          _Metric(
            title: 'Usuarios registrados',
            value: summary.registeredUsers,
            detail: 'Cuentas de clientes y prestadores.',
            icon: Icons.people_outline,
          ),
          _Metric(
            title: 'Prestadores activos',
            value: summary.activeProviders,
            detail: 'Cuenta habilitada, sin depender de disponibilidad.',
            icon: Icons.handyman_outlined,
          ),
          _Metric(
            title: 'Servicios publicados',
            value: summary.publishedServices,
            detail: 'Categorías aprobadas y activas asociadas a perfiles.',
            icon: Icons.category_outlined,
          ),
        ],
      ),
      const SizedBox(height: 28),
      _MetricSection(
        title: 'Pendientes de revisión',
        metrics: [
          _Metric(
            title: 'Prestadores por verificar',
            value: summary.providersToVerify,
            detail: 'Perfiles con verificación administrativa pendiente.',
            icon: Icons.verified_user_outlined,
          ),
          _Metric(
            title: 'Reseñas reportadas',
            value: summary.reportedReviews,
            detail: 'Reseñas con al menos un reporte sin resolver.',
            icon: Icons.flag_outlined,
          ),
          _Metric(
            title: 'Solicitudes de contacto pendientes',
            value: summary.contactRequests,
            detail: 'Solicitudes nuevas en estado pendiente.',
            icon: Icons.mark_unread_chat_alt_outlined,
          ),
        ],
      ),
      const SizedBox(height: 28),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Nuevos registros',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 días')),
              ButtonSegment(value: 30, label: Text('30 días')),
            ],
            selected: {periodDays},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) onPeriodChanged(selection.first);
            },
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'Período móvil hasta ${_dateLabel(summary.periodEndsAt)}.',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 14),
      _MetricGrid(
        metrics: [
          _Metric(
            title: 'Nuevos usuarios',
            value: summary.newUsers,
            detail: 'Cuentas registradas en los últimos $periodDays días.',
            icon: Icons.person_add_alt_1_outlined,
          ),
          _Metric(
            title: 'Nuevos prestadores',
            value: summary.newProviders,
            detail: 'Perfiles creados en los últimos $periodDays días.',
            icon: Icons.add_business_outlined,
          ),
        ],
      ),
    ],
  );
}

class _MetricSection extends StatelessWidget {
  const _MetricSection({required this.title, required this.metrics});

  final String title;
  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 14),
      _MetricGrid(metrics: metrics),
    ],
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 16.0;
      final columns = constraints.maxWidth >= 1120
          ? 3
          : constraints.maxWidth >= 700
          ? 2
          : 1;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final metric in metrics)
            SizedBox(
              width: width,
              child: _MetricCard(metric: metric),
            ),
        ],
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '${metric.title}: ${metric.value}. ${metric.detail}',
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(metric.icon, color: AdminTheme.brand, size: 24),
            const SizedBox(height: 16),
            Text(
              metric.value.toString(),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              metric.title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              metric.detail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SummaryError extends StatelessWidget {
  const _SummaryError({required this.onRetry, required this.error});

  final VoidCallback onRetry;
  final Object? error;

  String get message {
    final currentError = error;
    if (currentError is ApiFailure) {
      final status = currentError.statusCode;
      return status == null
          ? currentError.message
          : 'El API respondió HTTP $status: ${currentError.message}';
    }
    return 'No se pudo completar la solicitud. Revisá la consola para ver el detalle.';
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_outlined),
          const SizedBox(height: 12),
          Text(
            'No se pudo cargar el resumen.',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(message),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

class _LoadingSummary extends StatelessWidget {
  const _LoadingSummary();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 240,
    child: Center(child: CircularProgressIndicator()),
  );
}

class _Metric {
  const _Metric({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String title;
  final int value;
  final String detail;
  final IconData icon;
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
