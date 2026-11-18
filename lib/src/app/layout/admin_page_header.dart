import 'package:flutter/material.dart';

import '../../core/theme/admin_theme.dart';

/// A compact page heading that keeps the current section and primary action clear.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    required this.title,
    required this.description,
    required this.icon,
    this.section,
    this.trailing,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? section;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 640;
      final heading = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AdminTheme.brandSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AdminTheme.brand, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section != null) ...[
                  Text(
                    section!.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AdminTheme.brand,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AdminTheme.textMuted, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      );

      if (compact && trailing != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [heading, const SizedBox(height: 16), trailing!],
        );
      }
      return Row(
        children: [
          Expanded(child: heading),
          if (trailing != null) ...[const SizedBox(width: 18), trailing!],
        ],
      );
    },
  );
}
