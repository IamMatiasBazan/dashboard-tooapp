import 'package:flutter/material.dart';

import '../../core/theme/admin_theme.dart';

/// A shared, horizontally scrollable results grid for administrative lists.
class AdminDataTable extends StatefulWidget {
  const AdminDataTable({required this.columns, required this.rows, super.key});

  final List<DataColumn> columns;
  final List<DataRow> rows;

  @override
  State<AdminDataTable> createState() => _AdminDataTableState();
}

class _AdminDataTableState extends State<AdminDataTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AdminTheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AdminTheme.border),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            horizontalMargin: 20,
            columnSpacing: 28,
            headingRowColor: const WidgetStatePropertyAll(
              AdminTheme.tableHeader,
            ),
            headingTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AdminTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
            dataTextStyle: Theme.of(context).textTheme.bodyMedium,
            dividerThickness: 1,
            columns: widget.columns,
            rows: widget.rows,
          ),
        ),
      ),
    ),
  );
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    required this.label,
    this.positive = false,
    super.key,
  });

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AdminTheme.brand : AdminTheme.textMuted;
    final background = positive ? AdminTheme.brandSoft : AdminTheme.tableHeader;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
