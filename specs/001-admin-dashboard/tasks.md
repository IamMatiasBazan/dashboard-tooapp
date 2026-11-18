# Tasks: TÖÖ Admin Dashboard y API administrativa

**Input**: `specs/001-admin-dashboard/spec.md` y `specs/001-admin-dashboard/plan.md`.

**Feature activa**: `001-admin-dashboard` (confirmada por `.specify/scripts/bash/setup-tasks.sh --json`).

**Repositorios**: Dashboard `/Users/matybazan/Documents/dashboard_tooapp`; API `/Users/matybazan/Documents/api-tooapp`. La app móvil es solo referencia y no recibe tareas.

**Artefactos opcionales**: No existen `research.md`, `data-model.md`, `quickstart.md` ni `contracts/`; el plan contiene el diseño disponible de arquitectura, persistencia y contratos.

**Estado re-auditado 2026-11-17**: Las marcas históricas [X] no se toman como evidencia de estado actual. Se dejaron incompletas las tareas de backend que la auditoría confirmó ausentes (auditoría, moderación de portafolio/contactos/reseñas, disponibilidad admin y mutaciones de membresías) y las tareas de verificación no ejecutadas. El dashboard sí contiene estructura Flutter y pantallas para varios módulos; el router/nav actual solo publica Inicio, Reportes, Categorías y Usuarios.

**Formato**: Cada tarea sigue `- [ ] T### [P?] [US#?] descripción con rutas concretas`. `[P]` indica tareas que pueden ejecutarse en paralelo una vez satisfechas sus dependencias.

## Alcance fijado para esta versión

`FR-030` limita la localidad a un dato relacionado de solo lectura; no se crea un módulo ni CRUD administrativo de localidades. Pagos y suscripciones históricas quedan fuera de v1, sin modelo, endpoint o pantalla. Los servicios se representan mediante perfil/categorías, sin entidad `Service`. Estos límites están alineados con las decisiones G1–G9 y el plan.

## Fase 1: Preparación compartida

**Objetivo**: Confirmar convenciones y preparar trazabilidad entre los repositorios.

- [X] T001 [P] Crear la matriz de trazabilidad requisito/acción → contrato, controller, DTO, validación, permiso, prueba y control de dashboard en `/Users/matybazan/Documents/api-tooapp/docs/admin-traceability.md`.
- [X] T002 [P] Resolver versiones compatibles de `provider`, `dio` y `go_router` contra el SDK declarado y registrar dependencias en `/Users/matybazan/Documents/dashboard_tooapp/pubspec.yaml` y `pubspec.lock`.
- [X] T003 [P] Verificar la discrepancia de versiones de Prisma Client/CLI en `/Users/matybazan/Documents/api-tooapp/package.json` y su lockfile; ajustar solo los rangos incompatibles demostrados por la resolución del proyecto.

## Fase 2: Fundamentos compartidos

**Objetivo**: Asegurar autorización de servidor, sesión web y estructura común antes de habilitar módulos administrativos.

- [X] T004 Implementar y aplicar middleware que exija cuenta activa y rol exacto `ADMIN` para cada ruta administrativa del API en `/Users/matybazan/Documents/api-tooapp/src/middlewares/` y los routers admin; denegar `SUPPORT`, `CLIENT` y `PROVIDER`.
- [X] T005 Mantener login/refresh/logout web con JWT Bearer del contrato existente y CORS de origen permitido sin `withCredentials`/cookies; preservar Bearer móvil y sin endpoint de creación/elevación de `ADMIN`.
- [X] T006 Implementar manejo compartido de respuestas `{data}`/errores, solicitudes web con credenciales, expiración de sesión y redirección segura en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/core/network/` y `/Users/matybazan/Documents/dashboard_tooapp/lib/src/core/session/`.
- [X] T007 Añadir pruebas HTTP de autorización para rutas administrativas: `ADMIN` permitido; `SUPPORT` y otros roles denegados; sesión ausente, malformada, expirada o revocada rechazada, en `/Users/matybazan/Documents/api-tooapp/tests/http/`.
- [X] T008 Añadir persistencia append-only y servicio compartido de auditoría administrativa con actor desde la sesión y timestamp del servidor en `/Users/matybazan/Documents/api-tooapp/prisma/schema.prisma`, migración Prisma y `/Users/matybazan/Documents/api-tooapp/src/modules/`; conservar referencias y no almacenar snapshots de PII.

## Fase 3: User Story 1 — Resolver reportes (P1)

**Objetivo**: Consultar, filtrar y resolver reportes mostrando solo resultados confirmados por el API.

**Prueba independiente**: `ADMIN` pagina y filtra reportes por tipo/estado y resuelve uno con confirmación; los demás roles reciben denegación y un error o resultado incierto nunca aparece como éxito.

- [X] T009 [P] [US1] Extender el esquema de consulta de reportes para `type`, `isResolved`, `page` y `limit` (default 20, máximo 100) en `/Users/matybazan/Documents/api-tooapp/src/modules/reports/reports.schema.ts`.
- [X] T010 [US1] Implementar paginación, metadata y selección allowlist de reportes/autor en `/Users/matybazan/Documents/api-tooapp/src/modules/reports/reports.repository.ts`, `reports.service.ts` y `reports.controller.ts`, sin agregar búsqueda textual, reapertura ni borrado.
- [X] T011 [P] [US1] Añadir pruebas HTTP y PostgreSQL para filtros, límites, paginación, autorización, resolución confirmada, conflicto y exclusión de campos sensibles en `/Users/matybazan/Documents/api-tooapp/tests/http/` y `/Users/matybazan/Documents/api-tooapp/tests/integration/`.
- [X] T012 [P] [US1] Crear modelos tipados de reporte, autor, filtros y paginación según el DTO del API en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/reports/models/`.
- [X] T013 [US1] Implementar data source y repository tipados para listado, detalle devuelto por el listado y resolución en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/reports/data/`.
- [X] T014 [US1] Implementar listado, filtros, detalle de autor, estados de carga/vacío/sin coincidencias/error y confirmación de resolución en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/reports/presentation/`.
- [X] T015 [US1] Añadir pruebas de estado/widget para filtros, paginación, confirmación, éxito confirmado, `401`/`403`/`409`, error y lista vacía en `/Users/matybazan/Documents/dashboard_tooapp/test/src/features/reports/`.

## Fase 4: User Story 2 — Consultar y administrar categorías (P1)

**Objetivo**: Consultar categorías, unificar una categoría pendiente en una aprobada y completar las acciones aprobadas de creación, edición y estado.

**Prueba independiente**: `ADMIN` filtra/busca/pagina, crea en `PENDING`, edita nombre/icono, transiciona estados válidos y unifica solo un origen `PENDING` con destino `APPROVED`; errores, estados inválidos y conflictos nunca se muestran como éxito.

- [X] T016 [P] [US2] Ampliar validadores de categorías para búsqueda por nombre, filtros existentes, `page`/`limit`, creación, edición allowlist y estados permitidos en `/Users/matybazan/Documents/api-tooapp/src/modules/categories/categories.schema.ts`.
- [X] T017 [US2] Implementar consulta paginada, creación `PENDING`, edición de nombre/icono, transiciones aprobadas y desactivación solo de categoría `APPROVED` en service/repository/controller de `/Users/matybazan/Documents/api-tooapp/src/modules/categories/`.
- [X] T018 [US2] Reforzar la unificación existente con validación de origen/destino, control de concurrencia y auditoría del resultado dentro de la transacción en `/Users/matybazan/Documents/api-tooapp/src/modules/categories/`.
- [X] T019 [P] [US2] Añadir pruebas HTTP y PostgreSQL de filtros/búsqueda/paginación, alta, edición, transiciones, permisos, unificación, relaciones, rollback y conflictos en `/Users/matybazan/Documents/api-tooapp/tests/http/` y `/Users/matybazan/Documents/api-tooapp/tests/integration/`.
- [X] T020 [P] [US2] Crear modelos tipados de categoría, conteos, filtros, estados y paginación conforme a los DTOs del API en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/categories/models/`.
- [X] T021 [US2] Implementar data source y repository tipados para consulta y mutaciones autorizadas de categorías en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/categories/data/`.
- [X] T022 [US2] Implementar listado, filtros, búsqueda, formulario de alta/edición, cambios de estado y selección/confirmación de unificación en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/categories/presentation/`.
- [X] T023 [US2] Añadir pruebas widget/estado para formularios, transiciones válidas/inválidas, resumen de unificación, cancelación, conflicto, estados vacíos y errores en `/Users/matybazan/Documents/dashboard_tooapp/test/src/features/categories/`.

## Fase 5: User Story 3 — Acceder según rol autorizado (P1)

**Objetivo**: Permitir acceso web al personal autorizado sin crear cuentas `ADMIN` desde la consola ni alterar autenticación móvil.

**Prueba independiente**: una cuenta activa `ADMIN` inicia sesión; credenciales inválidas, cuenta inactiva, sesión vencida/revocada y roles no autorizados no acceden a datos administrativos.

- [X] T024 [US3] Conservar login/refresh/logout JWT Bearer vigente y revocación existente para web, sin añadir cookies/CSRF ni registro de `ADMIN`, en `/Users/matybazan/Documents/api-tooapp/src/modules/auth/`.
- [X] T025 [US3] Implementar verificación de sesión y guards de rutas para proteger `/Users/matybazan/Documents/dashboard_tooapp/lib/src/app/router/` y `/Users/matybazan/Documents/dashboard_tooapp/lib/src/core/session/`.
- [X] T026 [US3] Implementar formulario de ingreso, estados de carga/error, expiración y cierre de sesión en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/access/{models,data,presentation}/`.
- [ ] T027 [P] [US3] Añadir pruebas HTTP del contrato JWT Bearer, CORS, refresh/logout, cuenta inactiva y compatibilidad con autenticación móvil en `/Users/matybazan/Documents/api-tooapp/tests/http/`.
- [ ] T028 [P] [US3] Añadir pruebas de rutas protegidas, rol no autorizado, sesión expirada, logout y limpieza de contenido protegido en `/Users/matybazan/Documents/dashboard_tooapp/test/src/features/access/` y `/Users/matybazan/Documents/dashboard_tooapp/test/src/app/router/`.

## Fase 6: User Story 4 — Navegar y operar en desktop y móvil (P2)

**Objetivo**: Presentar un drawer vertical en pantallas amplias y navegación lateral accesible en pantallas compactas, sin exponer módulos incompletos.

**Prueba independiente**: recorrer Inicio, Reportes y Categorías en ancho amplio/compacto con teclado y lector de pantalla; la sección activa es perceptible y los flujos principales siguen disponibles.

- [X] T029 [P] [US4] Implementar `AdminScaffold`, drawer vertical persistente, drawer lateral compacto, foco/semántica de sección activa y adaptación por ancho en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/app/layout/`.
- [X] T030 [US4] Implementar rutas protegidas y navegación a Inicio, Reportes y Categorías en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/app/router/` y `/Users/matybazan/Documents/dashboard_tooapp/lib/src/app/app.dart`.
- [X] T031 [US4] Centralizar tokens visuales web aprobados y aplicarlos a la composición compartida en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/core/theme/`.
- [X] T032 [US4] Implementar Inicio orientativo con enlaces solo a módulos operativos y sin métricas no entregadas por el API en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/home/presentation/`.
- [X] T033 [P] [US4] Añadir pruebas de layout amplio/compacto, navegación por teclado, foco, Semantics, texto ampliado y ausencia de entradas para módulos incompletos en `/Users/matybazan/Documents/dashboard_tooapp/test/src/app/`.

## Fase 7: User Story 5 — Completar módulos administrativos aprobados (P2)

**Objetivo**: Entregar los módulos acordados de punta a punta; cada módulo requiere contrato/API protegido y su correspondiente experiencia Flutter antes de aparecer en navegación.

**Prueba independiente**: para cada acción aprobada existe ruta/API autorizada, validación, controller, service, persistencia/DTO, prueba pertinente y flujo Flutter que solo comunica respuestas confirmadas.

### Usuarios

- [X] T034 [P] [US5] Implementar schemas y DTO allowlist para listado/detalle, búsqueda por nombre/email/teléfono, filtros aprobados y paginación de usuarios en `/Users/matybazan/Documents/api-tooapp/src/modules/users/`.
- [X] T035 [US5] Implementar servicio/controller/repository admin para consultar usuarios, editar nombre/apellido/teléfono/localidad y desactivar/reactivar cuenta; impedir creación, mutación de rol y exposición de DNI/credenciales en `/Users/matybazan/Documents/api-tooapp/src/modules/users/`.
- [X] T036 [US5] Registrar auditoría de cambios administrativos de usuario y revocar refresh tokens al desactivar una cuenta en `/Users/matybazan/Documents/api-tooapp/src/modules/users/` y `/Users/matybazan/Documents/api-tooapp/src/modules/auth/`.
- [X] T037 [P] [US5] Añadir pruebas de filtros, allowlist PII, entradas inválidas, roles, edición, desactivación/reactivación y revocación de sesión en `/Users/matybazan/Documents/api-tooapp/tests/http/` y `/Users/matybazan/Documents/api-tooapp/tests/integration/`.
- [X] T038 [US5] Implementar modelos, data source, estado y presentación de listado/detalle/edición/desactivación de usuarios en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/users/{models,data,presentation}/`.

### Prestadores y portafolio

- [X] T039 [P] [US5] Implementar schemas/DTOs y consultas admin paginadas de prestadores por nombre/categoría/localidad en `/Users/matybazan/Documents/api-tooapp/src/modules/providers/`, excluyendo DNI, credenciales y coordenadas precisas.
- [X] T040 [US5] Implementar detalle y edición allowlist de campos profesionales existentes, junto con desactivación/reactivación reversible de cuenta, sin confundir `isAccountActive` con `isAvailable`, en `/Users/matybazan/Documents/api-tooapp/src/modules/providers/`.
- [X] T041 [US5] Implementar consulta y moderación reversible de imágenes de portafolio (ocultar/restaurar), preservando el original y registrando actor/fecha/acción en `/Users/matybazan/Documents/api-tooapp/prisma/schema.prisma`, migración y `/Users/matybazan/Documents/api-tooapp/src/modules/providers/`.
- [ ] T042 [P] [US5] Añadir pruebas HTTP/integración de búsquedas, allowlists, estado de cuenta, ocultar/restaurar portafolio, auditoría y concurrencia en `/Users/matybazan/Documents/api-tooapp/tests/http/` y `/Users/matybazan/Documents/api-tooapp/tests/integration/`.
- [X] T043 [US5] Implementar modelos, data source, listado/ficha de prestador y moderación de portafolio en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/providers/{models,data,presentation}/`.

### Contactos

- [X] T044 [P] [US5] Implementar schemas/DTOs y listado/detalle paginados con filtros por estado/prestador/categoría/cliente, omitiendo `problemDescription` de listados, en `/Users/matybazan/Documents/api-tooapp/src/modules/contacts/`.
- [X] T045 [US5] Implementar transiciones `PENDING→SCHEDULED/CANCELLED` y `SCHEDULED→COMPLETED/CANCELLED`, requerir `scheduledFor` al programar y registrar actor/fecha/transición en `/Users/matybazan/Documents/api-tooapp/src/modules/contacts/`.
- [ ] T046 [P] [US5] Añadir pruebas de permisos, filtros, datos omitidos, transiciones inválidas/terminales, conflictos y auditoría en `/Users/matybazan/Documents/api-tooapp/tests/http/` y `/Users/matybazan/Documents/api-tooapp/tests/integration/`.
- [X] T047 [US5] Implementar modelos, bandeja de contactos, filtros, estados y confirmación de transición en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/contacts/{models,data,presentation}/`.

### Reseñas y auditoría

- [X] T048 [US5] Añadir estado de visibilidad de reseña y vincular los eventos de moderación al registro append-only compartido creado en T008, mediante `/Users/matybazan/Documents/api-tooapp/prisma/schema.prisma` y migración Prisma.
- [X] T049 [US5] Implementar listado/detalle admin y ocultar/restaurar con motivo recortado de 1–500 caracteres en `/Users/matybazan/Documents/api-tooapp/src/modules/reviews/`; actualizar visibilidad y evento de auditoría atómicamente, sin editar/borrar reseña.
- [ ] T050 [P] [US5] Añadir pruebas de autorización, motivo, retención mientras exista reseña, auditoría append-only, atomicidad/rollback y DTO del detalle en `/Users/matybazan/Documents/api-tooapp/tests/http/` y `/Users/matybazan/Documents/api-tooapp/tests/integration/`.
- [X] T051 [US5] Implementar modelos, listado/detalle, historial de auditoría y acciones confirmadas de ocultar/restaurar en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/reviews/{models,data,presentation}/`.

### Disponibilidad y ubicación de solo lectura

- [X] T052 [P] [US5] Implementar DTO y consulta `GET /admin/providers/:providerProfileId/availability` con localidad y resumen de disponibilidad, omitiendo geometrías/coordenadas, en `/Users/matybazan/Documents/api-tooapp/src/modules/providers/`.
- [ ] T053 [P] [US5] Añadir pruebas de autorización y minimización de campos que confirmen ausencia de coordenadas y mutaciones administrativas en `/Users/matybazan/Documents/api-tooapp/tests/http/` y `/Users/matybazan/Documents/api-tooapp/tests/integration/`.
- [X] T054 [US5] Implementar modelo/data/presentación de localidad y resumen de disponibilidad como solo lectura en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/availability/{models,data,presentation}/`.

### Membresías

- [X] T055 [US5] Añadir estado de archivo y `updatedAt` a `MembershipTier` con migración que preserve relaciones actuales en `/Users/matybazan/Documents/api-tooapp/prisma/schema.prisma` y `/Users/matybazan/Documents/api-tooapp/prisma/migrations/`.
- [X] T056 [US5] Implementar listado/alta/edición/archivo de tiers con precio entero en ARS y asignación a prestador con confirmación en `/Users/matybazan/Documents/api-tooapp/src/modules/membership/`; registrar cambios de asignación con auditoría y no crear Subscription.
- [ ] T057 [P] [US5] Añadir pruebas de autorización, validación de precio, asignación, archivo con referencias conservadas, auditoría y conflicto concurrente en `/Users/matybazan/Documents/api-tooapp/tests/http/` y `/Users/matybazan/Documents/api-tooapp/tests/integration/`.
- [X] T058 [US5] Implementar modelos/data/presentación de niveles, archivo y asignación de membresía en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/memberships/{models,data,presentation}/`.

## Fase 8: Integración, accesibilidad y cierre

**Objetivo**: Verificar la trazabilidad y la cobertura transversal antes de habilitar cada sección.

- [X] T059 [P] Añadir pruebas de regresión de autenticación y endpoints usados por la app móvil en `/Users/matybazan/Documents/api-tooapp/tests/http/`, sin tareas ni cambios en el repositorio móvil.
- [ ] T060 Ejecutar pruebas de integración dashboard–API para historias completadas y registrar los resultados/contratos en `/Users/matybazan/Documents/api-tooapp/docs/admin-traceability.md`.
- [ ] T061 [P] Verificar accesibilidad y adaptación compacta/amplia de los flujos implementados en `/Users/matybazan/Documents/dashboard_tooapp/test/src/app/` y módulos de funcionalidades.
- [ ] T062 Verificar que cada entrada del drawer corresponda a una ruta/API, autorización, DTO, pruebas y pantalla completa en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/app/layout/admin_drawer.dart`; no incluir pagos, localidades como módulo ni servicios independientes.
- [ ] T063 Ejecutar análisis, formato y pruebas del dashboard, y typecheck/lint/formato/pruebas/build del API según scripts declarados en ambos repositorios; registrar comandos/resultados en `/Users/matybazan/Documents/api-tooapp/docs/admin-traceability.md`.

## Dependencias y orden de ejecución

### Dependencias entre fases

- Preparación (T001–T003) precede a los cambios de arquitectura y migración.
- Fundamentos (T004–T008) bloquean la habilitación de módulos administrativos; T004–T007 deben preceder a todas las rutas y pantallas protegidas.
- US1 y US2 pueden avanzar en paralelo después de T004–T007; cada UI depende del contrato y DTO de su API.
- US3 implementa el flujo web y depende de los fundamentos de autorización y red/sesión.
- US4 depende de US3 para proteger navegación. Inicio consume el resumen Admin protegido definido en FR-008.
- US5 depende de los fundamentos compartidos y cada módulo es un incremento vertical; persistencia/migraciones preceden a lógica, contratos/tests preceden a activar la interfaz correspondiente.
- T062–T063 dependen de los incrementos que se habiliten. No hay tareas de localidades, pagos ni entidad `Service` independiente porque están fuera del alcance aprobado.

### Oportunidades de paralelismo

- T001–T003 pueden ejecutarse en paralelo.
- Tras los fundamentos, las API y pantallas de reportes y categorías pueden trabajarse en paralelo en sus respectivos módulos.
- En US5, usuarios, prestadores, contactos, reseñas, disponibilidad y membresías pueden desarrollarse como módulos separados; compartir la auditoría exige coordinar T008 y sus consumidores.
- Las pruebas de cada módulo pueden prepararse en paralelo con implementación cuando se mantengan en archivos distintos; la integración dashboard–API espera al contrato estable.
- Accesibilidad transversal puede verificarse por pantalla una vez completados sus flujos.

## Estrategia de implementación

### MVP sugerido

Completar fundamentos de sesión/autorización, US1 (reportes), US2 (categorías), US3 (acceso) y US4 (drawer, Inicio y adaptación). Estos módulos permiten una entrega inicial útil; habilitar cada área de US5 solo después de completar su recorrido API–dashboard.

### Incrementos

Entregar cada área como contrato → persistencia/migración si corresponde → validación/service/repository/controller/ruta y autorización → pruebas API → modelos/data/estado/presentación Flutter → verificación responsive/accesible. No habilitar en el drawer una función cuyo resultado de API no esté confirmado.

## Notas

- No se incluyen tareas de pagos, suscripciones históricas, entidad `Service` independiente ni app móvil: quedaron fuera de las decisiones aprobadas.
- La decisión G1–G9 aprueba Provider, Dio y go_router para esta feature, conforme al plan; T002 solo resuelve versiones compatibles con el SDK y el lockfile. La constitución indica que dichas dependencias no estaban aprobadas cuando se redactó; la decisión explícita de esta feature satisface su requisito de aprobación técnica.
- No ejecutar migraciones, pruebas ni comandos de implementación durante la generación de esta lista.

## Fase 9: Reconciliación de diseño e integración

**Objetivo**: Aplicar el patrón visual de la referencia solo a la composición, conservar identidad TooApp y habilitar rutas únicamente cuando exista pantalla operativa respaldada por API.

- [X] T064 [P] [US4] Completar `design-reference.md` a partir de los patrones Kite observados en Dashboard y Products: navegación agrupada, barra superior contextual, toolbar de búsqueda/filtros, tablas y paginación; conservar los tokens TooApp y no copiar métricas ni datos de comercio.
- [X] T065 [US4] Modernizar shell Inicio, navegación agrupada y encabezado de contenido con diseño responsive y paleta TÖÖ; enrutar todas las pantallas administrativas existentes y no mostrar opciones sin flujo API real, en `lib/src/app/layout/`, `lib/src/app/router/admin_router.dart` y `lib/src/features/home/presentation/`.
- [X] T066 [US5] Incorporar en el drawer y Inicio solo los módulos que tengan GET y acciones administrativas confirmadas; revisar destino y navegación de usuarios, prestadores, categorías, reportes, contactos, reseñas, disponibilidad y membresías en `lib/src/app/`.
- [X] T067 [US5] Implementar y documentar las operaciones backend pendientes de contactos, reseñas, portafolio y membresías respetando transiciones aprobadas, allowlists, auditoría y migraciones revisadas; no ejecutar migraciones sobre bases compartidas en `/Users/matybazan/Documents/api-tooapp/`.
- [X] T068 [P] Revisar cada llamada Flutter/API contra rutas y DTO existentes, eliminar supuestos de `/admin/auth/*`/cookies, y registrar operación real y brechas en `docs/admin-traceability.md` de ambos repositorios.

## Fase 10: Búsqueda y filtros de pantallas administrativas

**Objetivo**: Alinear búsqueda y filtros con la composición de referencia, los tokens TooApp y los contratos actuales, con interacción adaptable y estados comprensibles.

**Criterio independiente**: En cada pantalla, el administrador puede encontrar o acotar registros usando solo capacidades existentes, identificar y limpiar filtros activos, y acceder a los controles tanto en ancho amplio como compacto. No se envían parámetros no soportados.

- [X] T069 [P] [US4] Rediseñar búsqueda, filtros activos y limpieza de filtros para usuarios, prestadores y disponibilidad, con comportamiento responsive y respetando los parámetros vigentes, en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/users/presentation/users_page.dart`, `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/providers/presentation/providers_page.dart` y `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/availability/presentation/availability_page.dart`.
- [X] T070 [P] [US4] Rediseñar filtros por estado/actividad de categorías y tipo/resolución de reportes; no añadir búsqueda remota ni paginación no soportadas; distinguir vacío de sin coincidencias, en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/categories/presentation/categories_page.dart` y `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/reports/presentation/reports_page.dart`.
- [X] T071 [P] [US5] Rediseñar búsqueda y filtros vigentes de contactos y reseñas, conservando los contratos de consulta y la presentación de filtros activos, en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/contacts/presentation/contacts_page.dart` y `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/reviews/presentation/reviews_page.dart`.
- [X] T072 [P] [US5] Rediseñar búsqueda/filtro de niveles de membresía y estado de archivo, con limpieza visible y comportamiento adaptable, en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/memberships/presentation/memberships_page.dart`.
- [X] T073 [US4] Revisar la barra superior: no ofrece búsqueda global; mantener la navegación a módulos reales y la búsqueda contextual dentro de cada módulo, en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/app/layout/`.
- [ ] T074 [US4] Revisar manualmente adaptación amplia/compacta, teclado, foco, nombres accesibles y estados de filtros en las ocho pantallas administrativas afectadas; registrar brechas en `/Users/matybazan/Documents/dashboard_tooapp/specs/001-admin-dashboard/tasks.md`.
- [X] T075 [P] [US4] Hacer perceptible el rediseño mediante encabezado y panel de filtros reutilizables, jerarquía de resultados y superficies/bordes consistentes, aplicados a las ocho pantallas sin métricas inventadas, en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/app/layout/`, `/Users/matybazan/Documents/dashboard_tooapp/lib/src/core/theme/admin_theme.dart` y las presentaciones de módulos.


## Fase 11: Resumen administrativo de Inicio

**Objetivo**: Sustituir las tarjetas de navegación de Inicio por totales, pendientes e indicadores recientes de fuente verificable.

- [X] T076 [US4] Agregar `GET /admin/dashboard/summary` con período 7/30, conteos definidos en FR-008, estado de verificación de prestadores, relación opcional Report–Review y migración revisable en `/Users/matybazan/Documents/api-tooapp/`.
- [X] T077 [US4] Conectar Inicio al endpoint mediante modelo, data source y repository; presentar resumen, pendientes, selector 7/30, carga y error/reintento en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/home/`.
- [X] T078 [US4] Sincronizar FR-008, matriz, plan y contrato HTTP con las reglas de conteo y el DTO del resumen en los dos repositorios.


## Phase 12: Convergence

- [X] T079 Alinear el mapper/modelo Flutter del listado administrativo con el DTO real de `GET /admin/providers`, tratando como opcional `user.phone` porque no viene en `providerListSelect`, y agregar una prueba unitaria con fixture de respuesta sin acceso a base de datos per FR-025, T043 (partial).


## Phase 13: Convergence

- [X] T080 Reparar la edición administrativa de Prestadores: cargar el detalle por `providerProfileId` antes de abrir el formulario y enviar `PATCH /admin/providers/:providerProfileId` con el ID del perfil; cubrir la precarga de campos y la petición con una prueba Flutter usando fixtures, sin acceso a base de datos; omitir la localidad del formulario y excluir `localityId` del cuerpo enviado según FR-025, T040 y T043 (partial).
- [ ] T081 Completar la desactivación administrativa de cuentas de prestador registrando auditoría y revocando sus refresh tokens al cambiar a inactivo; verificar el flujo con pruebas unitarias/mock sin acceso a base de datos per T036, T040 (partial).
- [X] T082 [US4] Actualizar `design-reference.md`, `spec.md` y `plan.md` con los patrones observados de Kite, la paleta TooApp, Material Icons instalados y los límites de datos/acciones que impone el contrato actual del API.
- [X] T083 [US4] Aplicar shell, encabezados, paneles de filtros, tema Material 3 y tabla compartida a usuarios, prestadores, contactos, reseñas, categorías, membresías y disponibilidad; conservar filtros, acciones, paginación y estados existentes sin cambios de API ni base de datos.

## Follow-up implementation

- [X] T084 [US4] Corregir el contraste del navbar TooApp y cubrir el fondo del drawer, texto e iconos activos/inactivos y sección seleccionada con una prueba widget, sin cambios de API ni base de datos en `/Users/matybazan/Documents/dashboard_tooapp/`.
- [X] T085 [US4] Alinear los tokens visuales del dashboard con `too_app_mobile` (azul `#0875CE`, verde `#007A59`, fondo `#F6F6F7`), asegurar el contraste del navbar sobre superficie clara y desactivar el banner DEBUG de Flutter; sin cambios al API ni base de datos.

## Phase 14: Convergence

- [ ] T086 Reconciliar las referencias obsoletas de paleta (`#165D54`/`#F5F7F6`) y la decisión de validación visual pendiente en `spec.md` y `plan.md` con los tokens aprobados de `too_app_mobile` per FR-011 (contradicts).
- [ ] T087 Aplicar `AdminTheme.success` (`#007A59`) a las insignias de estados positivos, mantener el azul como color primario y cubrir la semántica de color con una prueba widget per FR-011 (partial).

## Phase 15: User Story 4 — Directorio conjunto de Usuarios y prestadores (P2)

**Goal**: Reemplazar las pantallas separadas de Usuarios y Prestadores por una lista conjunta de solo lectura, con búsqueda y paginación globales. Mantener Inicio y los demás módulos administrativos.

**Independent Test**: Con repositorios y HTTP simulados, un ADMIN ve filas CLIENT y PROVIDER correctamente discriminadas, busca y pagina sobre el total combinado, y no encuentra acciones de edición, cambio de estado o moderación. Las demás rutas permanecen disponibles; la consulta deniega roles no autorizados. No se usa una base de datos real.

### Tests para US4

- [X] T088 [P] [US4] Cubrir unión de CLIENT/PROVIDER, filtros, conteo, orden `createdAt DESC` + `id ASC`, límites globales entre páginas y errores de filtro incompatible con repositorio mock en `/Users/matybazan/Documents/api-tooapp/tests/unit/admin-accounts.test.ts`.
- [X] T089 [P] [US4] Cubrir guard ADMIN, query estricta y respuesta paginada del endpoint con dependencias mockeadas y sin DB en `/Users/matybazan/Documents/api-tooapp/tests/unit/admin-accounts-routes.test.ts`.
- [X] T090 [P] [US4] Cubrir modelo/parseo de `AccountListItem`, DTO discriminado y estados de error de consulta mediante fixtures HTTP en `/Users/matybazan/Documents/dashboard_tooapp/test/src/features/accounts/accounts_data_source_test.dart`.
- [X] T091 [P] [US4] Cubrir tabla combinada, filtros, paginación global, estados carga/vacío/error y ausencia de mutaciones en `/Users/matybazan/Documents/dashboard_tooapp/test/src/features/accounts/accounts_page_test.dart`.

### Implementación US4

- [X] T092 [US4] Implementar `GET /admin/accounts` con schema Zod estricto, guard `authenticate` + `requireRole('ADMIN')`, filtros por tipo/estado/localidad y filtros de prestador, búsqueda aprobada, orden global estable, conteo y paginación `page`/`limit` sobre modelos existentes; responder `{data,total,page,limit}` sin cambios de esquema y sin que el agente ejecute consultas/SQL o migraciones; la ruta usa Prisma en runtime en `/Users/matybazan/Documents/api-tooapp/src/modules/admin-read/admin-read.schema.ts`, `admin-read.routes.ts`, `admin-read.controller.ts`, `admin-read.service.ts` y `admin-read.repository.ts`.
- [X] T093 [US4] Crear modelo tipado, data source y repository Flutter de solo lectura para `GET /admin/accounts`, incluyendo errores y envelope `{data,total,page,limit}`, en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/accounts/models/admin_account.dart` y `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/accounts/data/`.
- [X] T094 [US4] Implementar una sola página `Usuarios y prestadores` con tabla discriminada, filtros soportados, paginación global y estados de carga/vacío/error/reintento; no incluir edición, activación/desactivación ni moderación de portafolio en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/features/accounts/presentation/accounts_page.dart`.
- [X] T095 [US4] Reemplazar las entradas y rutas separadas `/users` y `/providers` por `/accounts`, mantener Inicio y las demás secciones y asegurar que no queden accesibles desde el router acciones de esas listas en `/Users/matybazan/Documents/dashboard_tooapp/lib/src/app/router/admin_router.dart` y `/Users/matybazan/Documents/dashboard_tooapp/lib/src/app/layout/admin_scaffold.dart`.
- [X] T096 [US4] Actualizar la matriz API-dashboard y guía de validación con `GET /admin/accounts`, filtros, respuesta paginada, límites de solo lectura y la prohibición de pruebas/conexiones a DB en `/Users/matybazan/Documents/api-tooapp/docs/admin-traceability.md` y `/Users/matybazan/Documents/dashboard_tooapp/specs/001-admin-dashboard/quickstart.md`.

**Dependencias**: T088–T089 pueden prepararse en paralelo con T090–T091 usando el contrato OpenAPI. T092 depende de T088–T089; T093 depende del contrato y puede avanzar en paralelo con T092. T094–T095 dependen del modelo/data source. T096 depende del contrato final. No ejecutar pruebas de integración PostgreSQL ni comandos de base de datos.

**MVP del incremento**: T088–T095 entregan y validan el directorio de lectura completo. T096 completa la trazabilidad.

## Phase 16: Polish & Cross-Cutting Validation

- [X] T097 Ejecutar únicamente pruebas unitarias/HTTP mock de `admin-accounts` y pruebas Flutter de `features/accounts`, además de `flutter analyze --no-pub`; registrar resultados sin ejecutar integración PostgreSQL, SQL, migraciones ni consultas a base de datos en `/Users/matybazan/Documents/api-tooapp/docs/admin-traceability.md`.
