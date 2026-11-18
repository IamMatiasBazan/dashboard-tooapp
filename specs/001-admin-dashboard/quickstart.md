# Quickstart: pantalla Usuarios y prestadores

Esta guía valida la pantalla conjunta con fixtures y contratos mock. **No requiere ni permite conexión a una base de datos**. No ejecutar SQL, migraciones, Prisma contra un entorno, ni pruebas PostgreSQL para este incremento.

## Prerrequisitos

- Flutter SDK compatible con el `pubspec.yaml` de `dashboard_tooapp`.
- Node.js compatible con `api-tooapp` (`>=22 <25`) y dependencias del repositorio instaladas.
- No se requiere `DATABASE_URL`, cuenta ADMIN real ni servidor de base de datos.

## Escenarios de aceptación mock

1. Un ADMIN solicita `GET /admin/accounts` y recibe una única página con filas CLIENT y PROVIDER discriminadas.
2. `q`, tipo, localidad y estado se aplican antes del conteo; categoría/disponibilidad filtran prestadores.
3. `page`/`limit` calculan límites globales correctos; los empates de fecha se ordenan por id ascendente.
4. Cuenta CLIENT con filtro exclusivo de PROVIDER obtiene `422`; sesión ausente obtiene `401`; rol distinto de ADMIN obtiene `403`.
5. DTO no contiene datos de escritura, DNI, credenciales, tokens ni coordenadas; pantalla no ofrece botones de edición, estado ni moderación.
6. Dashboard conserva Inicio y los demás módulos; hay una sola entrada Usuarios y prestadores.
7. Flutter presenta carga, error/reintento, conjunto vacío y resultados; filtros y paginación funcionan en ancho compacto y amplio.

## Comandos focalizados para la fase de implementación

Desde `/Users/matybazan/Documents/api-tooapp`:

```bash
npx vitest run tests/unit/admin-accounts.test.ts
npx vitest run tests/unit/admin-accounts-routes.test.ts
```

Desde `/Users/matybazan/Documents/dashboard_tooapp`:

```bash
flutter test --no-pub test/src/features/accounts/accounts_page_test.dart
flutter test --no-pub test/src/features/accounts/accounts_data_source_test.dart
flutter analyze --no-pub
```

Las pruebas API deben inyectar/mokear el repositorio; las pruebas Flutter deben usar un cliente HTTP falso. No correr `test:integration`, no iniciar servicios de base de datos y no consultar datos reales.

## Resultado esperado

Todas las pruebas mock pasan; el endpoint aplica autorización y paginación global; la tabla muestra ambos tipos de cuenta en modo de solo lectura; ningún cambio de esquema o base de datos forma parte de la entrega.


## Ejecución en este incremento (2026-11-18)

- API: `npx vitest run tests/unit/admin-accounts.test.ts tests/unit/admin-accounts-routes.test.ts` — 2 archivos, 4 pruebas aprobadas. `npm run typecheck` — aprobado.
- Dashboard: 11 pruebas enfocadas de `accounts_data_source_test.dart`, `accounts_page_test.dart`, `router_access_test.dart` y `admin_scaffold_accessibility_test.dart` aprobadas; `flutter analyze --no-pub` sin hallazgos.
- Las pruebas usan repositorio/HTTP simulados. No se conectó ni consultó una base de datos; no se ejecutaron SQL ni migraciones.
