# Implementation Plan: TÖÖ Admin Dashboard y API administrativa

**Branch**: `001-admin-dashboard` | **Date**: 2026-11-17 | **Spec**: [spec.md](spec.md)
**Status**: Approved; resumen de Inicio ampliado el 2026-11-18

**Input**: Especificación administrativa del dashboard y sus contratos de API asociados.

> Este plan vive en el repositorio del dashboard. El API se planifica como componente coordinado en `/Users/matybazan/Documents/api-tooapp`; la app móvil se mantiene como referencia de producto y no forma parte de los cambios.

## Summary

Construir una consola web Flutter responsive y completar el API Express/Prisma con operaciones administrativas reales para cada opción aprobada. La primera entrega autoriza solo al rol `ADMIN`; las cuentas se aprovisionan por un operador autorizado fuera de la consola. La gestión usa consulta, creación/edición cuando aplique y transiciones de estado con historial conservado. Pagos quedan fuera de v1; reseñas pueden ocultarse/restaurarse con motivo y auditoría. La localidad es un dato relacionado de solo lectura, sin módulo administrativo propio. No se habilita una opción del dashboard hasta que su ruta protegida, validación, controller, lógica, persistencia y modelo/DTO estén implementados y probados.

La auditoría de `api-tooapp` del 2026-11-17 confirma que ya existen rutas protegidas Bearer para usuarios, prestadores, categorías, reportes, contactos, reseñas, portafolio y niveles de membresía; varias son solo de lectura. El plan diferencia esas operaciones existentes de las pendientes. Los cambios backend siguen el patrón `routes → middleware/validate → controller → service → repository → Prisma`, y Flutter se organiza por `features/<funcionalidad>/{data,models,presentation}`. Ninguna operación propuesta se considera disponible hasta verificar su implementación.

Las decisiones funcionales G1–G9 fueron aprobadas y se aplican en este plan. El alcance se limita a contratos respaldados por las entidades actuales y por las reglas aprobadas. No se registra ni crea una cuenta `ADMIN` mediante la API. Los pagos y las suscripciones históricas quedan fuera de la primera versión; no se inventan sus fuentes o modelos.

## Technical Context

**Language/Version**: Dashboard: Flutter/Dart con constraint declarado `sdk: ^3.13.5`; no se fijó una versión exacta del SDK en el repositorio. API: TypeScript, Node.js `>=22 <25`.

**Primary Dependencies**: Dashboard: Flutter SDK, `flutter_lints: ^6.0.0`, `provider`, `dio` y `go_router`, con versiones compatibles resueltas desde el repositorio al implementar. API: Express `^5.1.0`, Prisma Client `^6.19.3`, Prisma CLI declarado `^6.8.2`, Zod `^4.6.7`, JWT y bcrypt. Verificar la discrepancia de rangos Prisma contra el lockfile antes de cambios de esquema; no actualizar versiones sin evidencia.

**Storage**: PostgreSQL mediante Prisma en el API, con PostGIS y columnas geométricas `Unsupported` en Prisma Client. El dashboard no tiene persistencia propia. Se reutilizan modelos de perfil/categoría para servicios; `ProviderProfile` agrega estado de verificación administrativa y `Report` puede vincularse opcionalmente con `Review`. No se crea entidad de pagos, suscripciones históricas ni `Service` independiente.

**Testing**: Dashboard: `flutter_test` está declarado, pero no se encontraron pruebas del dashboard. API: Vitest con scripts unitarios, HTTP/contrato e integración; Supertest y fixtures PostgreSQL existentes. Las pruebas requeridas se enumeran abajo; no se ejecutaron en esta etapa.

**Target Platform**: Flutter Web en navegadores desktop y móvil. API Express en Node.js dentro del rango declarado. No se modifica ni se recompila la app móvil como parte de esta iniciativa.

**Project Type**: Aplicación web Flutter más API REST TypeScript en repositorios separados, coordinados por el contrato administrativo.

**Performance Goals**: La especificación no define SLA ni límites de latencia. Los listados administrativos usan `page` (mínimo 1) y `limit` (default 20, máximo 100), con filtros y búsquedas aprobados por módulo. No se inventan objetivos de latencia.

**Constraints**: Solo `ADMIN`; ninguna API registra o crea cuentas `ADMIN`; aprovisionamiento fuera de la consola. Pagos fuera de la primera versión por falta de fuente identificada. No hay modelo de suscripción histórica. Reseñas ocultables/restaurables con motivo y auditoría; no se editan ni borran permanentemente. No hay borrado permanente genérico. Drawer persistente amplio y lateral adaptable compacto. No mostrar controles para funciones fuera de alcance.

**Scale/Scope**: Áreas de v1: acceso, Inicio, usuarios, prestadores/perfiles, categorías, contactos, reseñas, disponibilidad/ubicaciones, reportes, membresías y moderación de portafolio. Los servicios se representan con perfil/categorías; pagos, suscripciones históricas y mantenimiento administrativo de localidades se excluyen. La localidad solo aparece como campo relacionado de lectura.

## Constitution Check

| Principio | Resultado de planificación | Evidencia/condición |
|---|---|---|
| Cobertura administrativa trazable | PASS | El plan aplica las decisiones aprobadas y asocia cada área a su trabajo de API y dashboard. |
| Fidelidad al API | PASS | Se separa contrato actual de contrato propuesto y se anotan dominios no presentes en Prisma. |
| Mínimo privilegio | PASS | El rol permitido es `ADMIN`; `SUPPORT` queda excluido. El servidor debe autorizar cada operación. |
| Navegación real | PASS | Solo aparecen módulos habilitados de punta a punta; drawer vertical amplio y variante lateral compacta. |
| Capas y modelos tipados | PASS | Dashboard por funcionalidad; API con validación, controller, service, repository y DTO tipados. |
| Desktop, móvil y accesibilidad | PASS | Los mismos flujos estarán disponibles en ambos targets, con teclado, foco, Semantics y texto ampliado. |
| Identidad y tokens | PASS | Tokens visuales aprobados se centralizan antes de implementar módulos. |
| Resultado confirmado y acciones responsables | PASS | No éxito local; confirmación para unificación, moderación y cambios significativos. |
| Consultas y resiliencia | PASS | Se fija page/limit; no se define SLA sin requisito de producto. |
| Verificación proporcional al riesgo | PASS | Pruebas de permiso, contratos, transacciones, auditoría y errores se definen por riesgo. |

**Gate**: Las decisiones funcionales G1–G9 están aprobadas y `FR-030` limita localidades a lectura relacionada, sin módulo de mantenimiento. Provider, Dio y go_router cuentan con aprobación explícita para esta feature; sus versiones compatibles se resuelven contra el SDK en setup. No quedan decisiones de producto que bloqueen los contratos v1.

## Architecture and Data Flow

1. El navegador carga el dashboard Flutter Web; composición, router/layout y sesión viven en `lib/src/app/` y `lib/src/core/`.
2. Una cuenta aprovisionada fuera de la consola inicia sesión. La autorización efectiva se valida en el API en cada operación, no solo en el drawer o el router del cliente.
3. Cada feature del dashboard consume su contrato a través de data sources/repositories tipados y publica estados de carga, vacío, error y éxito al estado/presentación.
4. Las rutas administrativas del API usan autenticación y `requireRole('ADMIN')`, validación Zod, controller fino, service con reglas, repository Prisma y DTO de respuesta con la envoltura actual `{ data: ... }`.
5. Las modificaciones persisten en una transacción cuando afectan entidades relacionadas; el resultado de interfaz se actualiza solo tras respuesta confirmada.
6. Los cambios de moderación y demás mutaciones administrativas acordadas escriben auditoría mínima. No se guardan snapshots de PII sin una decisión de retención y justificación.

### Autenticación web y sesiones

El API ofrece `POST /auth/login`, `POST /auth/refresh` y `POST /auth/logout` con JWT Bearer. Flutter Web usa el mismo contrato: conserva el refresh token en almacenamiento de sesión del navegador, manda access token como `Authorization: Bearer`, y no usa cookies con `withCredentials`. El CORS debe permitir el origen exacto configurado para dashboard; nunca combinar `Access-Control-Allow-Origin: *` con credenciales. No se inventan rutas `/admin/auth/*`, cookies ni CSRF que el API no soporta. Cada ruta administrativa valida en servidor la cuenta activa y rol exacto `ADMIN`; las cuentas ADMIN se aprovisionan fuera de la consola.

### Reauditoría de capacidades API (2026-11-17)

Fuente: lectura de routers, schemas, servicios y repositorios actuales de `/Users/matybazan/Documents/api-tooapp`; los nombres siguientes son métodos ya presentes, no contratos inferidos. Todas las rutas `/admin/*` observadas exigen Bearer y `requireRole('ADMIN')`.

Las respuestas del API no comparten un único envoltorio: operaciones singulares y mutaciones que usan `ok()` responden `{data: DTO}`; listados paginados del módulo `admin-read` responden `{data: DTO[], total, page, limit}` directamente. Los adaptadores Flutter deben seguir el formato real de cada endpoint y no asumir `{items,pagination}`.

| Área | Ya disponible | Trabajo pendiente para alcance aprobado |
|---|---|---|
| Usuarios | GET lista/detalle; PATCH perfil; PATCH estado de cuenta | Confirmar allowlist y paginación/filtros que faltan en Flutter. No POST/DELETE ni cambio de rol. |
| Prestadores | GET lista/detalle/reseñas; PATCH campos allowlist del perfil | Revisar DTO/controles Flutter y estado de cuenta mediante User. |
| Categorías | GET, POST, PATCH, PATCH active, POST unify | Comparar reglas aprobadas, filtros/paginación y estados actuales; no DELETE genérico. |
| Reportes | GET filtros actuales; PATCH resolve | Agregar paginación si falta, integrar UI. |
| Contactos | GET lista/detalle | Implementar transiciones administrativas aprobadas con actor/fecha/auditoría. |
| Reseñas | GET paginado, CLIENT_TO_PROVIDER | Implementar ocultar/restaurar con motivo y auditoría append-only. |
| Portafolio | GET | Implementar ocultar/restaurar con auditoría. |
| Membresías | GET lista/detalle | Implementar crear/editar/archivar tier y asignación aprobada, conservando referencias. |
| Disponibilidad/localidad | Disponibilidad admin no confirmada; `/localities` público | Solo lectura según FR-030; no exponer geometría ni crear CRUD de localidades. |

Los verbos HTTP se ajustan al contrato actual (GET/POST/PATCH); “PUT/DELETE” en la solicitud describe la necesidad de administrar datos, no exige métodos sin soporte ni borrado permanente. La especificación prohíbe hard delete genérico.

## Baseline API Support and Initially Proposed Contracts

> Contexto histórico del plan del 2026-10-30. La sección **Reauditoría de capacidades API (2026-11-17)** anterior es la fuente vigente del estado actual; esta matriz registra el diseño original y no debe usarse para afirmar qué rutas faltan o existen hoy.

Los paths de esta sección son **rutas actuales** solo cuando se identifican como tales. Las demás son **contratos propuestos** que se implementarán según las decisiones aprobadas de este documento. El API actual monta rutas en raíz (por ejemplo `/admin/reports`), no bajo un prefijo `/api`. Las respuestas exitosas existentes usan `{ data: ... }`; los errores HTTP usan códigos estructurados. `validate` aplica esquemas Zod. La convención aprobada para listas administrativas es `page` y `limit` (default 20, máximo 100), incluida su extensión a reportes y categorías.

| Área / estado actual | Contratos actuales confirmados | Contratos propuestos para cubrir la especificación | Persistencia, controller/service y autorización | Decisión o dependencia |
|---|---|---|---|---|
| Acceso: parcial (propuesta inicial, luego reemplazada) | `POST /auth/login`, `/auth/refresh`, `/auth/logout`; `UserRole` incluye `ADMIN` y `SUPPORT`; registro público acepta solo `CLIENT`/`PROVIDER`. | La propuesta inicial de cookies fue descartada en la aclaración del 2026-11-17; no existe endpoint de alta de ADMIN. | Middleware administrativo valida cuenta activa y `requireRole('ADMIN')`; usar JWT Bearer con la app web. | Procedimiento externo de aprovisionamiento ADMIN; nunca exponer alta o elevación a ADMIN por API. |
| Inicio: resumen administrativo implementado | No hay resumen global confirmado previo; `/provider/me/home` sigue siendo propio del prestador. | `GET /admin/dashboard/summary?periodDays=7|30` devuelve totales, pendientes y altas recientes según FR-008. | Ruta Bearer protegida por `ADMIN`; conteos transaccionales desde User, ProviderProfile, Category, ProviderSecondaryCategory, ContactIntent, Review y Report. | Período móvil 7/30 días; perfiles antiguos se inicializan como `PENDING`; métricas no crean entidades Service ni chat. |
| Reportes: parcial | **Actual** `GET /admin/reports?type=&isResolved=`; `PATCH /admin/reports/:id/resolve`. Listado ordenado descendente, sin paginación. | Conservar filtros `type`/`isResolved`; la UI pagina localmente el conjunto recibido. No enviar `page`, `limit` ni búsqueda al API. No añadir reapertura, eliminación, notas o asignación. | Reutilizar `Report` y controller/service/repository; `ADMIN` obligatorio. | La UI conserva filtros por tipo y resolución; sin metadata de paginación remota. |
| Categorías: parcial | **Actual** `GET /admin/categories?status=&active=`; `POST /admin/categories/unify`. | Conservar filtros remotos `status`/`active`; búsqueda por nombre y paginación, si se presentan, son locales al conjunto recibido. No enviar `search`, `page` ni `limit`. Mantener creación `PENDING`, edición de nombre/icono y estado. Transiciones: `PENDING→APPROVED/REJECTED`; `REJECTED` terminal. Desactivar solo categorías `APPROVED`. | Reutilizar `Category`; validación Zod estricta, transiciones en service, transacción para unificación, protección `ADMIN`; no DELETE genérico. | Unificar solo `PENDING` en `APPROVED`, IDs distintos; devolver conflicto en estado obsoleto. |
| Usuarios: sin administración global | `User` existe; no hay router admin/listado global. | `GET /admin/users?search=&role=&isAccountActive=&localityId=&page=&limit=`, `GET /admin/users/:userId`, `PATCH /admin/users/:userId`, `PATCH /admin/users/:userId/status`. Campos visibles: id, nombre, apellido, email, teléfono, rol, localidad y estado. Editables: nombre, apellido, teléfono, localidad y estado. | Reutilizar `User`; excluir DNI, contraseña/hash y tokens; no crear usuarios desde consola ni cambiar roles; desactivar revoca refresh tokens. | Búsqueda solo nombre/email/teléfono; no alta de cuentas ni cambio de rol. |
| Prestadores/perfiles: lectura pública y edición propia, con resumen de verificación | Existen búsqueda/perfil público y `/provider/me/*`; la consulta administrativa está implementada. | `GET /admin/providers` y operaciones existentes; Inicio cuenta perfiles con `verificationStatus=PENDING`. | Reutilizar `ProviderProfile`/`User`; agregar `verificationStatus` separado de `isMatriculado`, `isAccountActive` e `isAvailable`; DTO excluye DNI, credenciales sensibles y coordenadas precisas. | El resumen no altera campos de perfil ni disponibilidad. |
| Servicios/portafolio: sin entidad Service; imágenes existentes | Las categorías principal/secundarias representan los servicios del perfil. `ProviderPortfolioImage` contiene imágenes y hoy es gestionada por el prestador. | No crear entidad `Service`. Administrar relaciones de categorías en los módulos de categorías/prestadores. Añadir estado de archivo/visibilidad a imágenes y rutas admin de listar/ocultar/restaurar. | Migración para estado de imagen; preservar el archivo original; registrar actor/fecha/acción de moderación. | No existe un catálogo independiente de servicios en esta versión. |
| Contactos: flujo propio de CLIENT, sin bandeja admin | `POST /contact-intents`, `GET /contact-intents/:contactIntentId`, `PATCH /contact-intents/:id/status` bajo `CLIENT`; estados `PENDING/SCHEDULED/COMPLETED/CANCELLED`. | `GET /admin/contact-intents?status=&providerId=&categoryId=&clientId=&page=&limit=`, detalle y PATCH de estado con `scheduledFor` requerido para `SCHEDULED`. Omitir problemDescription de listados admin. | `ContactIntent` existente con client/provider/category, problemDescription, status, scheduledFor, timestamps. Añadir schemas/types/controller/service/repository admin; transición comprobada en service, nunca actualizar por Prisma directo desde controller. Sin delete. | Transiciones aprobadas; registrar actor, timestamp y transición. |
| Reseñas: crear y consultar, sin moderación | `GET /providers/:providerUserId/reviews`, `POST /reviews`, `GET /provider/me/reviews`; `Review` no tiene visibilidad o moderación. | Propuestas: `GET /admin/reviews?visibility=&providerId=&authorId=`; `PATCH /admin/reviews/:reviewId/visibility` body `{visibility:'VISIBLE'|'HIDDEN',reason}`; devolver reseña sin editar `comment` y estado confirmado. | Añadir enum/campo de visibilidad con default visible y `AdminAuditEvent` o `ReviewModerationEvent` append-only con `reviewId,actorId,action,reason,createdAt`. Una transacción actualiza visibilidad y crea evento. Actor debe ser `ADMIN`. | Motivo recortado obligatorio, 1–500 caracteres; auditoría append-only retenida mientras exista la reseña, legible en su detalle por ADMIN. |
| Disponibilidad y ubicaciones: operaciones propias, sin administración global | `/provider/me/availability`, `/provider/me/pulse` GET/POST/PATCH/DELETE son propios. `ProviderProfile` tiene `isAvailable`, `shiftEndsAt`, `lastPulseAt`, base/current location, fuente y radio; los puntos son `Unsupported(geometry)`. | `GET /admin/providers/:providerProfileId/availability` de solo lectura, con DTO de localidad y resumen de disponibilidad. | Reusar `ProviderProfile`; mantener fuera del DTO admin las columnas geométricas. No inventar horarios semanales: no hay modelo de agenda en el esquema. | Exponer localidad y resumen de disponibilidad únicamente. No coordenadas ni cambios admin de disponibilidad. |
| Membresías: niveles y asignación actual, sin administración o suscripción histórica | `GET /membership/tiers` y `/provider/me/membership` solo PROVIDER. `MembershipTier` con name, description, price; `ProviderProfile.membershipTierId`. No existe modelo Subscription ni payment. | `GET /admin/membership-tiers`; `POST /admin/membership-tiers`; `PATCH /admin/membership-tiers/:tierId` para nombre, descripción y precio; archivar tier y `PATCH /admin/providers/:providerProfileId/membership` para asignar tier. | Añadir estado de archivo y `updatedAt` a `MembershipTier`; preservar referencias existentes al archivar y auditar asignaciones. No crear Subscription. | Precio entero en ARS; asignación confirmada con auditoría. Sin suscripciones ni historial de renovación. |
| Pagos: excluidos de v1 | No hay `Payment`, integración ni fuente de registros identificada en el esquema inspeccionado. | Ninguna ruta ni módulo administrativo de pagos en esta versión. | No crear modelo, adapter, DTO o persistencia de pagos. | Reabrir alcance solo después de identificar una fuente de verdad y actualizar la especificación. |
| Localidades: dato relacionado de solo lectura | `GET /localities` entrega localidades habilitadas; `Locality` tiene id, name unique, slug unique, isEnabled y timestamps. | No se propone una ruta administrativa ni un módulo independiente. Exponer solo la localidad necesaria en los DTOs de usuarios/prestadores y en el resumen de ubicación aprobado. | Reutilizar la relación existente; no agregar mutaciones ni migraciones de localidad. Omitir coordenadas y geometrías de los DTOs administrativos. | Búsqueda, alta, edición, habilitación, deshabilitación y eliminación de localidades están fuera de v1 según `FR-030`. |

### Convención común para rutas nuevas

- Métodos y rutas de la tabla son propuestas, no contratos existentes. Mantener la convención actual sin `/api` a menos que una decisión de versionado establezca lo contrario.
- Para listados, el query solo contiene filtros aceptados para esa entidad. `page/limit` sigue la convención aprobada (`page>=1`, `limit` 1–100, default 20); reportes y categorías deben incorporarlos y devolver metadata de paginación.
- Contrato vigente: respuestas singulares/mutaciones `{data: DTO}`; listados paginados `{data: DTO[], total, page, limit}`. La propuesta antigua `{data:{items,pagination}}` no describe el API actual. Error: middleware central existente con status y código (`400`, `401`, `403`, `404`, `409`, `422`); preservar mensajes útiles y no filtrar stack/SQL.
- IDs se validan como UUID cuando la entidad existente usa `@db.Uuid`. Bodies son allowlists Zod estrictas para impedir mass assignment; no aceptar `role=ADMIN`, `passwordHash`, counters ni campos no editables.
- Mutaciones de estado revalidan la transición en service y usan `409 CONFLICT` ante estado obsoleto; la UI vuelve a consultar antes de repetir una acción cuyo resultado sea incierto.

## Data and Persistence Design

| Entidad actual/propuesta | Estado y diseño de datos | Relaciones / validaciones |
|---|---|---|
| `User` | Actual. Selección admin debe excluir `passwordHash`; la ficha muestra solo campos autorizados. `isAccountActive` sirve para desactivación reversible. | Tiene email/phone/DNI únicos, rol y localidad opcional. No permitir cambios a ADMIN; excluir DNI; desactivación revoca refresh tokens. |
| `ProviderProfile` | Actual. Reutilizar campos del perfil existentes; distinguir cuenta activa de disponibilidad del prestador. | Relación 1:1 `User`; categoría, tier, portfolio, contacts; coordenadas como geometría no soportada por Prisma Client. |
| `Category` | Actual. Campos de lista ya seleccionados; mutaciones admin requerirán reglas de estado. | Unificación actual se realiza dentro de transacción y remapea primary/secondary categories y contactos antes de borrar el origen. Preservar este flujo especial y auditar source/target/count. |
| `Report` | Actual. `isResolved` Boolean, tipo y contenido. Resolución actual idempotente solo en sentido de fijar true; propuesta debe evitar doble actualización contradictoria. | FK a User; listado incluye email/teléfono del autor. Revisar si ambos son realmente necesarios para cada tarea y evitar exponer datos demás. |
| `ContactIntent` | Actual. Estados enumerados y `scheduledFor`; sin modelo de nota/resolución admin. | FK client/provider/category. FK cascades de usuario/prestador y restrict en categoría requieren desactivación/archivo, no hard delete. |
| `Review` | Actual sin moderación. Propuesta: `visibility` visible/hidden default visible y registro append-only de cada cambio. | `ReviewModerationEvent` guarda reseña, actor ADMIN, acción, razón, fecha. No almacenar snapshot del comentario en log; no cambiar rating/comment. Actualización y evento en una transacción. |
| `AdminAuditEvent` | Registro común append-only para moderaciones y cambios administrativos aprobados: id, actorId, resourceType, resourceId, action, reason opcional, createdAt y correlationId opcional. Eventos append-only; valores anteriores/nuevos no se almacenan por defecto. | FK actor a User; la lectura de eventos de reseña se limita a ADMIN en el detalle correspondiente; no se incluye un listado global de auditoría. |
| `MembershipTier` | Actual con name, description, integer price, createdAt. Se propone estado de archivo y `updatedAt` para administración. | Restricción unique name; asignaciones existentes en `ProviderProfile` deben persistir al archivar tier. El precio se presenta como entero en ARS. |
| `Locality` | Actual con name, slug, isEnabled y timestamps. En esta feature solo se consulta como dato relacionado. | Reutilizar la relación existente en DTOs permitidos. No se implementa CRUD ni se cambia el estado de habilitación desde la consola. |
| Servicios y pagos | No existen modelos equivalentes en Prisma. Suscripciones y pagos tampoco tienen tablas en la especificación del API actual. | Servicios se modelan con categoría/perfil; pagos y suscripciones históricas se excluyen de v1 y no generan migraciones. |

### Migraciones y transacciones

- Toda modificación del esquema se expresa en una migración Prisma revisada; no se ejecutan migraciones durante esta fase de planificación.
- Moderación de reseñas escribe visibilidad y evento de auditoría en una transacción; razón no vacía y actor autenticado son validaciones obligatorias.
- Unificación de categorías conserva la transacción existente. Añadir control de concurrencia por estado y registrar resultado de la misma transacción; repetir una unificación ya completada debe devolver conflicto/no encontrado de forma explícita, nunca éxito ambiguo.
- Contactos siguen las transiciones aprobadas; cuentas se desactivan reversiblemente, tiers y portafolio se archivan/ocultan sin romper relaciones. La localidad permanece como dato relacionado de solo lectura.
- Los cambios financieros no son parte del alcance de escritura. Pagos no tienen contrato ni consulta en v1 al no existir fuente de verdad identificada.

## Dashboard Design

### Organización propuesta

El checkout actual ya contiene estructura Flutter por feature, router y pantallas, pero `AdminScaffold` solo publica cuatro destinos. El incremento de diseño renueva shell/home y enruta las pantallas existentes cuya lectura API está disponible:

```text
lib/
└── src/
    ├── app/
    │   ├── app.dart
    │   ├── router/
    │   └── layout/
    │       ├── admin_scaffold.dart
    │       ├── admin_drawer.dart
    │       └── responsive_admin_layout.dart
    ├── core/
    │   ├── config/
    │   ├── network/
    │   ├── session/
    │   ├── theme/
    │   ├── widgets/
    │   └── utils/
    └── features/
        ├── access/{data,models,presentation}/
        ├── home/presentation/
        ├── users/{data,models,presentation}/
        ├── providers/{data,models,presentation}/
        ├── categories/{data,models,presentation}/
        ├── contacts/{data,models,presentation}/
        ├── reviews/{data,models,presentation}/
        ├── availability/{data,models,presentation}/
        ├── reports/{data,models,presentation}/
        └── memberships/{data,models,presentation}/
```

Only modules with complete API/UI flows appear in the drawer. Payments and locality maintenance are excluded from v1; locality appears only as a read-only related field. Service offerings are managed through categories/providers, and portfolio moderation is part of providers. Do not create `features/payments/`, `features/localities/` or an independent `features/services/`. `home` can orient to active modules without an endpoint. Use the approved `provider`, `dio` and `go_router` packages with versions resolved against the checked Flutter SDK. Use browser-compatible networking; `dart:io` is not supported for browser requests.

### Layout and interaction

- `AdminScaffold` hosts top-level responsive shell, content region and session state. `AdminDrawer` is persistent vertically at wide widths and opens as an accessible side drawer at compact widths; no area is removed when layout changes.
- Use `LayoutBuilder`/available width and avoid setting breakpoint numbers until visual review. Active route exposes current section semantics.
- Data modules use typed `data` repository + API DTO/model mapping, presentation state, and screens/widgets. Screens do not issue HTTP requests or parse untyped JSON.
- Forms have allowlisted editable fields only. Status changes have clear current and target state; archive/deactivate is distinct from delete. Review moderation requires reason. Category unification identifies source, target and impact and is confirmed before submit.
- Every screen handles loading, empty, no matches, success and error. `401` triggers session reauthentication; `403` renders access denied; `409` refreshes the record and explains concurrent change; network/5xx errors cannot show success.
- Accessibility includes focus order/visibility, keyboard activation, names and state through Flutter Semantics, sufficient contrast and enlarged text without clipped actions.
- Design tokens remain centralized in `lib/src/core/theme/admin_theme.dart`. Kite contributes composition only: grouped sidebar, contextual topbar, local list toolbar and compact tables. Preserve TooApp brand `#165D54` and canvas `#F5F7F6`; do not copy reference metrics, labels, commerce data or colors. Use the installed Flutter Material 3 widgets and Material Icons; do not add an icon package or API behavior without contract support.

### Dependency decisions

The feature clarification explicitly approves `provider` for state management, `dio` for HTTP and `go_router` for routing. Resolve compatible versions against the dashboard's declared Flutter/Dart SDK and lockfile; do not invent version pins or copy mobile dependency versions without compatibility checks. No additional secure-session or UI component package is approved by this decision. Existing mobile dependencies do not transfer automatically to the independent dashboard.

## API Implementation Pattern

For each new admin feature, preserve the API's module convention: `*.routes.ts`, `*.schema.ts` with Zod, `*.controller.ts`, `*.service.ts`, `*.repository.ts`, `*.types.ts`, export router in `src/routes.ts`, use shared `authenticate`, `requireRole('ADMIN')`, `validate`, response helpers and `errorMiddleware`. Keep controllers limited to request/response mapping; domain transitions belong in services; repository owns Prisma reads/writes; DTOs explicitly select fields.

The cross-repository administration traceability matrix will be maintained at `/Users/matybazan/Documents/api-tooapp/docs/admin-traceability.md`; its implementation task creates the `docs/` directory if it does not yet exist. This path is the canonical location for mapping each approved operation to its contract, authorization, persistence, tests and dashboard control.

Existing test layout is `tests/unit`, `tests/http`, `tests/integration`, with Vitest/Supertest/PostgreSQL support. Add tests to these established paths for each admin operation. Current API root routes are mounted without a common `/api` prefix; avoid changing existing mobile routes. Add admin routes without altering mobile behavior.

## Security, Error Handling, and Concurrency

- Every new route: authenticate + require exact `ADMIN`; explicitly test `SUPPORT`, `CLIENT`, `PROVIDER`, missing, malformed, expired token. Hiding a control is not security.
- Login provisioning stays out-of-band. Public register role enum remains limited to `CLIENT/PROVIDER`; no admin create/update endpoint may set role `ADMIN`.
- Audit fields use authenticated `req.auth.id`, never trust actor IDs from request bodies. Reasons and state transitions validated server-side.
- Explicitly select DTO columns. Never return `passwordHash`, refresh tokens, secrets, raw SQL errors or full GPS points by default. Report author email/phone are currently returned; reconsider necessity by approved purpose.
- API CORS en desarrollo refleja solo el origen loopback que solicita la app cuando `CORS_ORIGIN="*"`; despliegue configura orígenes exactos. Flutter usa JWT Bearer sin cookies ni `withCredentials`.
- Use existing standardized `401/403/404/409/422` handling. Duplicate unique name/email/phone conflicts map to `409`; input issues to `422`; do not turn missing/conflict errors into 200.
- For state writes, service checks current state and expected transition inside transaction; use conditional update/version or equivalent to prevent concurrent lost updates. If the condition no longer matches, return `409` and require UI refresh.
- Limit rate and payload size for login, broad searches, report content and audit endpoints. Existing API does not show a rate-limit middleware; choose/develop it after expected usage and deployment topology are decided.
- Payments are excluded from v1; no payment endpoint, adapter, credentials or dashboard module is planned.

## Test and Validation Strategy

No tests are run or written during plan generation. During implementation, use existing commands and add cases to the existing suites:

### Dashboard

- Widget/state tests for route guard and `ADMIN` navigation; compact/large shell and drawer selection; every screen's loading/empty/no-results/error/success state.
- Form tests for field validation, status/action confirmation, cancel behavior and no success on failed/uncertain request.
- API data-source contract tests for envelope parsing, errors, expired session, `401`, `403`, `409` and retry behavior.
- Responsive/accessibility tests for keyboard path, semantics labels, focus, text scaling and major admin flows at representative compact/wide constraints; exact breakpoints to be approved during design.
- Run formatting/analyzer and Flutter tests once implementation exists; package versions must first be approved and resolved.

### API

- Unit tests for each service: valid and invalid state transitions, unique conflicts, no hard delete, audit records, transaction rollback and `404` behavior.
- HTTP contract tests for every route: `ADMIN` success, `SUPPORT`/other role `403`, no/malformed/expired credentials `401`, invalid UUID/body/query `422`, absent record `404`, conflict `409`, and response DTO excludes secrets.
- PostgreSQL integration tests for joins/select allowlists, category unification and provider/contact remapping, review visibility + audit atomicity, account disable/session behavior, tier assignment/archive relation preservation, portfolio visibility and read-only availability.
- Regression contract tests for existing mobile endpoints/auth flows to confirm no breaking response or role changes.
- Run `npm run typecheck`, `npm run lint`, `npm run format:check`, `npm run test:unit`, `npm run test:contract`, `npm run test:integration`, and `npm run build` as appropriate after implementation; no tests executed now.
- Review Prisma migration SQL, `prisma generate`, schema diff, indexes/uniqueness and rollback procedure before applying to any environment.

## Risks and Dependencies

| Risk/dependency | Impact | Mitigation |
|---|---|---|
| Payments have no identified source | Payment administration cannot be represented truthfully | Payments are excluded from v1; any future inclusion requires identifying the authoritative source and updating scope. |
| No independent Service entity exists | A standalone service catalog would not match the current data model | Represent offerings through provider profile/category relations; do not create a Service table. |
| Dashboard deployment origin is environment-specific | Incorrect CORS configuration could block web sessions or weaken access controls | Configure exact allowed origin(s) per deployment environment; preserve mobile contracts. |
| `SUPPORT` is a database role but excluded by spec | Generic guard helpers may later broaden access accidentally | Admin route tests require `ADMIN` and explicitly deny `SUPPORT`. |
| Category unification physically deletes source category | Conflicts with no generic hard-delete rule; relation loss risk | Keep only as special confirmed transaction, show impact, audit; test rollback and concurrent status. |
| Geometry uses unsupported Prisma type | Admin DTOs may expose sensitive coordinates if profile queries return geometry implicitly | Keep locality/availability DTOs read-only and omit geometry and precise coordinates; no PostGIS admin writes are in v1. |
| Mobile app and API repositories are separate from dashboard | Contract drift and changes deployed at different times | Maintain route-to-feature traceability; land/verify backend contract before enabling dashboard control. |
| List volume has no SLA | Very large result sets could affect usability | Use approved page/limit defaults; revisit only with measured usage. |
| Membership lifecycle must preserve current assignments | Archiving or reassignment could disrupt provider profiles | Use logical archive, preserve existing references, confirm assignment changes and write audit events. |
| Flutter package versions must match SDK | Dependency resolution may fail | Resolve versions against current SDK during setup; do not copy mobile lockfile versions blindly. |

## Approved Decisions for Contracts

| Decision | Approved rule | Contract implication |
|---|---|---|
| Browser access and admin provisioning | Web uses the current JWT Bearer login/refresh/logout contract and allows the dashboard origin; development wildcard reflects loopback origins only. ADMIN accounts are provisioned out of band; no API or dashboard endpoint may create or elevate ADMIN. | Validate active account and exact ADMIN role on every admin request; preserve mobile Bearer contracts. No cookie/CSRF contract is added.
| Users/providers | No account creation in the console. User list/detail exposes id, name, email, phone, role, locality and active state; editable user fields are first/last name, phone and locality, plus reversible deactivation. Exclude DNI, credentials, hashes and tokens. Provider management uses non-sensitive profile fields and account status; account status is distinct from availability. | Strict Zod allowlists; no role mutation; deactivate revokes refresh tokens. Search users by name/email/phone; providers by name/category/locality.
| Categories | Create as PENDING; edit name/icon; PENDING may transition to APPROVED or REJECTED; REJECTED is terminal. Only APPROVED categories can be disabled. | Validate transitions in service; stale transitions return 409; no hard delete except existing transactional unification.
| Contacts | PENDING→SCHEDULED/CANCELLED; SCHEDULED→COMPLETED/CANCELLED; terminal states cannot reopen. Admin list omits free-text problem description. Log actor, timestamp and transition. | Queries filter by state/provider/category/client; schedule date required for SCHEDULED.
| Services/portfolio | No independent Service model; service offerings are represented by provider profile and category relations. Portfolio images can be hidden/restored while preserving original files, with moderation audit. | No Service table; add reversible image visibility/archive state only.
| Reviews/audit | Hide/restore requires a trimmed reason of 1–500 characters. Append-only audit stores actor, action, timestamp and reason; visible in review detail to ADMIN; retained for the review lifetime. | Update visibility and write event atomically; never edit/delete review content.
| Location/availability | Show locality and read-only availability summary. No precise coordinates or admin availability changes. | Do not expose geometry or add weekly schedule/PostGIS admin writes.
| Memberships | Manage tier name, description and integer price in ARS; archive tiers without breaking current assignments; assign a tier to a provider with confirmation and audit. No subscription or renewal-history model in v1. | Reuse MembershipTier and ProviderProfile relation; add active/archive state as needed; no Subscription table.
| Payments | Excluded from v1 because no source/provider is identified in API or app. | No payment model, adapter, route, dashboard module or synthetic data. Revisit only after a source of truth is identified.
| Lists and dashboard dependencies | Admin lists use page>=1, limit default 20, maximum 100. Approved searches: users name/email/phone; providers name/category/locality; categories name; contacts state/provider/category/client. Use Provider, Dio and go_router; centralize approved web theme tokens. | Add page/limit to report/category admin lists and return pagination metadata. Resolve compatible package versions against dashboard SDK at setup.

Package version resolution and environment-specific origin configuration are implementation setup checks, not business gates. `FR-030` is aligned with the approved read-only location scope; no locality CRUD or payments module is planned in v1.

## Recommended Technical Order

1. Resolve repository setup checks: Prisma client/CLI lockfile compatibility, Flutter SDK and package versions, and deployment CORS origin values.
2. Implement shared session/security, CORS, network/error handling, ADMIN guard and audit persistence according to approved decisions.
3. Extend API persistence/migrations for review visibility/audit and any approved domain models; verify schema and migrations before module controllers.
4. Implement API modules in vertical slices: reports/categories; users/providers; contacts/reviews; memberships; portfolio moderation and read-only availability. Do not create locality CRUD, a payments module, or independent Service/Subscription models in v1. Keep all administrative endpoints behind exact `ADMIN` authorization.
5. Add unit, HTTP contract and PostgreSQL integration coverage per module, plus regression coverage for existing mobile contracts; freeze API contracts before dashboard integration.
6. Build dashboard app/core/session/layout and approved router/network/state packages; add access and shared error handling; then implement features matching API-ready modules.
7. Review responsive/accessibility behavior, verify every control-to-endpoint mapping, and enable drawer entries only for complete API/UI flows. No deployment or migration execution is part of this plan.

## Project Structure

### Documentation (this feature)

```text
specs/001-admin-dashboard/
├── spec.md
└── plan.md
```

Only `plan.md` is produced in this stage. The plan embeds contract and data-design notes to honor the instruction not to create `research.md`, `data-model.md`, `contracts/`, `quickstart.md` or `tasks.md` separately.

### Source Code (repositories; proposed destinations)

```text
dashboard_tooapp/
└── lib/src/{app,core,features}/...

api-tooapp/
├── prisma/schema.prisma
├── prisma/migrations/<approved-change>/migration.sql
├── src/modules/<feature>/
│   ├── <feature>.routes.ts
│   ├── <feature>.schema.ts
│   ├── <feature>.controller.ts
│   ├── <feature>.service.ts
│   ├── <feature>.repository.ts
│   └── <feature>.types.ts
└── tests/{unit,http,integration}/...
```

**Structure Decision**: The dashboard follows the project constitution's feature-first Flutter layout, adapted to the currently minimal repo. The API follows its existing Express module files and Prisma persistence. No source files or API migrations are changed by this plan.

## Complexity Tracking

| Additional complexity | Why it is needed | Simpler alternative rejected because |
|---|---|---|
| Coordinated implementation across two repositories | A dashboard option is only complete when its protected API contract and UI both work. | Implementing only the dashboard would create simulated or failing admin controls; changing the mobile repo is out of scope. |
| Shared audit and admin session concerns | Review moderation, admin privileges and browser token handling cross feature boundaries. | Per-screen client checks cannot protect API data or provide an auditable result. |

## Incremento de diseño de búsqueda y filtros

La referencia disponible es una vista de dashboard del rol User, por lo que aporta únicamente composición y jerarquía visual, no evidencia sobre una consola Admin. Las pantallas de TooApp mantendrán los tokens de marca existentes. Cada módulo conserva búsqueda contextual según su contrato vigente; la búsqueda superior, si está disponible, solo encuentra módulos y acciones de navegación.

Los filtros actuales deben presentarse de forma consistente debajo del encabezado, mostrar los activos y permitir limpiar uno o todos. El layout amplio mantiene controles visibles en línea; el compacto ofrece un panel adaptable. No se agregan parámetros, búsqueda remota, filtros ni paginación que el API no confirme. Categorías usan estado/actividad y reportes tipo/resolución; usuarios, prestadores, contactos y reseñas usan solo sus filtros documentados. Estados de carga, error, lista vacía y sin coincidencias permanecen distinguibles.

Para que el cambio sea perceptible y consistente, las pantallas comparten un encabezado de módulo con icono, sección, título y descripción, seguido por un panel de filtros de superficie blanca con borde y agrupación propia. Los resultados comienzan en una sección separada. Los conteos se muestran solo cuando provienen de la respuesta; no se agregan métricas ficticias.


## Addendum 2026-11-18: resumen administrativo de Inicio

### Contrato y período

`GET /admin/dashboard/summary?periodDays=7|30` requiere Bearer `ADMIN` y devuelve un único resumen confirmado por la base. `periodDays` acepta 7 o 30, default 7; el intervalo móvil UTC es `[generatedAt - días, generatedAt)`. Las altas recientes cuentan `User` con rol `CLIENT` o `PROVIDER` y `ProviderProfile.createdAt`, respectivamente.

### Reglas de conteo

- Usuarios registrados: cuentas `CLIENT` y `PROVIDER`; no incluye cuentas `ADMIN`/`SUPPORT`.
- Prestadores activos: `ProviderProfile` cuya cuenta asociada tiene `User.isAccountActive=true`, sin depender de disponibilidad horaria.
- Servicios publicados: suma de asociaciones primarias y secundarias con categorías `APPROVED` e `isActive=true`; no se crea entidad `Service`.
- Prestadores por verificar: estado administrativo explícito `ProviderProfile.verificationStatus=PENDING`; `isMatriculado` no es sustituto. La migración aplica `PENDING` también a perfiles existentes.
- Reseñas reportadas: reseñas distintas que tienen al menos un `Report.reviewId` vinculado no resuelto.
- Novedades de contacto: `ContactIntent.status=PENDING`, presentadas como solicitudes de contacto, no como mensajes de chat.

Flutter reemplaza las tarjetas de navegación de Inicio por indicadores no clicables, selector 7/30 días, estado de carga y error con reintento. La navegación permanece en el drawer.
