import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/session/session_controller.dart';
import '../../core/theme/admin_theme.dart';

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  static const _groups = <_NavigationGroup>[
    _NavigationGroup('Principal', [
      _NavigationItem('Inicio', '/', Icons.home_outlined),
    ]),
    _NavigationGroup('Operaciones', [
      _NavigationItem('Reportes', '/reports', Icons.flag_outlined),
      _NavigationItem('Contactos', '/contacts', Icons.chat_bubble_outline),
    ]),
    _NavigationGroup('Personas', [
      _NavigationItem('Usuarios y prestadores', '/accounts', Icons.people_outline),
      _NavigationItem('Reseñas', '/reviews', Icons.rate_review_outlined),
    ]),
    _NavigationGroup('Gestión', [
      _NavigationItem('Categorías', '/categories', Icons.category_outlined),
      _NavigationItem(
        'Disponibilidad',
        '/availability',
        Icons.calendar_month_outlined,
      ),
      _NavigationItem(
        'Membresías',
        '/memberships',
        Icons.card_membership_outlined,
      ),
    ]),
  ];

  static List<_NavigationItem> get _items =>
      _groups.expand((group) => group.items).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    final items = _items;
    final selectedIndex = items.indexWhere((item) => item.path == location);
    final selected = selectedIndex < 0 ? items.first : items[selectedIndex];
    final session = context.watch<AdminSession>();

    if (compact) {
      return Scaffold(
        backgroundColor: AdminTheme.canvas,
        appBar: AppBar(
          title: Text(selected.label, maxLines: 1),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: session.logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        drawer: SizedBox(
          width: MediaQuery.sizeOf(context).width.clamp(280.0, 360.0),
          child: _navigationDrawer(
            context,
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
            compact: true,
            session: session,
          ),
        ),
        body: SafeArea(child: child),
      );
    }

    return Scaffold(
      backgroundColor: AdminTheme.canvas,
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 264,
              child: _navigationDrawer(
                context,
                selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                compact: false,
                session: session,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DesktopTopBar(
                    current: selected,
                    displayName: session.displayName,
                    onLogout: session.logout,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navigationDrawer(
    BuildContext context, {
    required int selectedIndex,
    required bool compact,
    required AdminSession session,
  }) => Drawer(
    backgroundColor: AdminTheme.surface,
    elevation: 0,
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 20, 20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TÖÖ',
                  style: TextStyle(
                    color: AdminTheme.brandDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Administración',
                  style: TextStyle(
                    color: Color(0xFF171719),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final group in _groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                group.label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AdminTheme.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          for (final item in group.items)
            Semantics(
              selected: _items.indexOf(item) == selectedIndex,
              button: true,
              child: ListTileTheme(
                iconColor: AdminTheme.textMuted,
                textColor: const Color(0xFF171719),
                selectedColor: Colors.white,
                child: ListTile(
                  selected: _items.indexOf(item) == selectedIndex,
                  selectedTileColor: AdminTheme.brandActive,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                  leading: Icon(item.icon),
                  title: Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    if (compact) Navigator.of(context).pop();
                    context.go(item.path);
                  },
                ),
              ),
            ),
        ],
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Divider(color: AdminTheme.border),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: ListTileTheme(
            iconColor: AdminTheme.textMuted,
            textColor: const Color(0xFF171719),
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: session.logout,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.current,
    required this.displayName,
    required this.onLogout,
  });

  final _NavigationItem current;
  final String? displayName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 28),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: AdminTheme.border)),
    ),
    child: Row(
      children: [
        Semantics(
          label: 'Ruta actual',
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Inicio'),
              ),
              if (current.path != '/') ...[
                const Icon(Icons.chevron_right, size: 18),
                const SizedBox(width: 4),
                Text(
                  current.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        if (displayName != null && displayName!.isNotEmpty) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              displayName!.substring(0, 1).toUpperCase(),
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: 10),
          Text(displayName!, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(width: 12),
        ],
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
  );
}

class _NavigationGroup {
  const _NavigationGroup(this.label, this.items);

  final String label;
  final List<_NavigationItem> items;
}

class _NavigationItem {
  const _NavigationItem(this.label, this.path, this.icon);

  final String label;
  final String path;
  final IconData icon;
}
