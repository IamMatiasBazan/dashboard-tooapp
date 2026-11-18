import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/layout/admin_page_header.dart';
import '../../../app/layout/admin_filter_panel.dart';
import '../../../app/layout/admin_data_table.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../providers/models/admin_provider.dart';
import '../data/availability_remote_data_source.dart';
import '../data/availability_repository.dart';
import '../models/admin_provider_availability.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});
  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  final _search = TextEditingController();
  late final AvailabilityRepository _repository;
  late Future<AdminProviderPage> _providers;

  @override
  void initState() {
    super.initState();
    _repository = AvailabilityRepository(
      AvailabilityRemoteDataSource(context.read<ApiClient>()),
    );
    _providers = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<AdminProviderPage> _load() => _repository.listProviders(_search.text);
  void _refresh() {
    setState(() {
      _providers = _load();
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
    children: [
      const AdminPageHeader(
        section: 'Gestión',
        title: 'Disponibilidad y localidad',
        description:
            'Consulta disponibilidad y localidad en modo de solo lectura.',
        icon: Icons.calendar_month_outlined,
      ),
      const SizedBox(height: 24),
      AdminFilterPanel(
        title: 'Buscar prestador',
        description: 'Busca un perfil para consultar su disponibilidad.',
        child: TextField(
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
                      _refresh();
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _refresh(),
        ),
      ),
      const SizedBox(height: 20),
      Text('Prestadores', style: Theme.of(context).textTheme.titleLarge),
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
            return _AvailabilityMessage(
              text: snapshot.error is ApiFailure
                  ? (snapshot.error! as ApiFailure).message
                  : 'No se pudieron cargar los prestadores.',
              onRetry: _refresh,
            );
          }
          final providers = snapshot.data!.items;
          if (providers.isEmpty) {
            return const _AvailabilityMessage(
              text: 'No hay prestadores que coincidan con la búsqueda.',
            );
          }
          return Column(
            children: [
              AdminDataTable(
                columns: const [
                  DataColumn(label: Text('Prestador')),
                  DataColumn(label: Text('Categoría')),
                  DataColumn(label: Text('Localidad')),
                  DataColumn(label: Text('Disponibilidad')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: [
                  for (final provider in providers)
                    DataRow(
                      onSelectChanged: (_) => _showAvailability(provider),
                      cells: [
                        DataCell(Text(provider.fullName)),
                        DataCell(Text(provider.primaryCategory.name)),
                        DataCell(
                          Text(provider.locality?.name ?? 'Sin localidad'),
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
                          IconButton(
                            tooltip:
                                'Ver disponibilidad de ${provider.fullName}',
                            onPressed: () => _showAvailability(provider),
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (snapshot.data!.total > providers.length)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Mostrando ${providers.length} de ${snapshot.data!.total}. Refina la búsqueda para encontrar otros prestadores.',
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );

  Future<void> _showAvailability(AdminProvider provider) async {
    try {
      final availability = await _repository.get(provider.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) =>
            _AvailabilityDialog(provider: provider, availability: availability),
      );
    } catch (error) {
      if (!mounted) return;
      if (error is ApiFailure && error.isUnauthorized) {
        context.read<AdminSession>().expire();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiFailure
                ? error.message
                : 'No se pudo cargar la disponibilidad.',
          ),
        ),
      );
    }
  }
}

class _AvailabilityDialog extends StatelessWidget {
  const _AvailabilityDialog({
    required this.provider,
    required this.availability,
  });
  final AdminProvider provider;
  final AdminProviderAvailability availability;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(provider.fullName),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Localidad: ${availability.locality?.name ?? 'Sin localidad'}'),
        Text(
          'Disponibilidad: ${availability.isAvailable ? 'Disponible ahora' : 'No disponible'}',
        ),
        Text('Origen: ${_locationSource(availability.locationSource)}'),
        if (availability.shiftEndsAt != null)
          Text(
            'Hasta: ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(availability.shiftEndsAt!.toLocal()))}',
          ),
        if (availability.lastPulseAt != null)
          Text(
            'Última actualización: ${MaterialLocalizations.of(context).formatMediumDate(availability.lastPulseAt!.toLocal())}',
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ],
  );
}

String _locationSource(String? source) => switch (source) {
  'BASE' => 'Localidad base',
  'CURRENT' => 'Ubicación actual',
  _ => 'Sin ubicación activa',
};

class _AvailabilityMessage extends StatelessWidget {
  const _AvailabilityMessage({required this.text, this.onRetry});
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
