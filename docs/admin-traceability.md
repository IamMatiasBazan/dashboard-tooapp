# TÖÖ Admin Dashboard: trazabilidad API

Contrato revisado el 2026-11-17 contra `/Users/matybazan/Documents/api-tooapp`. La API monta rutas en raíz. El cliente envía JWT Bearer; llamadas web no usan cookies ni CSRF. Las rutas admin requieren rol `ADMIN` en servidor.

## Formatos de respuesta

- Detalle y mutaciones envueltos como `{ data: DTO }`.
- Listados paginados como `{ data: DTO[], total, page, limit }`.
- Listas simples como `{ data: DTO[] }`.
- Errores esperados se transforman a `ApiFailure`; `401` expira la sesión, `403` indica falta de acceso y `409` requiere actualización.

## Módulos expuestos

| Ruta Flutter | Lectura API | Escrituras API | Restricciones |
|---|---|---|---|
| `/` | No requiere resumen ni métricas | Ninguna | Solo enlaces a módulos funcionales. |
| `/reports` | `GET /admin/reports` | `PATCH /admin/reports/:id/resolve` | Sin asignación, notas, reapertura ni borrado. |
| `/categories` | `GET /admin/categories` | `POST`, `PATCH`, `PATCH /:id/active`, `POST /unify` | Mantener transiciones aprobadas; no mostrar aprobación/rechazo si la API no lo permite. |
| `/users` | `GET /admin/users`, `GET /admin/users/:userId` | `PATCH /admin/users/:userId`, `PATCH /account-status` | Sin alta, cambio de rol, DNI, hashes ni tokens. |
| `/providers` | `GET /admin/providers`, detalle, filtros de categorías/localidades, `GET /admin/portfolio` | `PATCH /admin/providers/:providerProfileId`, cuenta vía User, `PATCH /admin/portfolio/:imageId/visibility` | Portfolio usa `{isHidden, reason}`; preservar imagen original. |
| `/contacts` | `GET /admin/contact-intents`, detalle | `PATCH /admin/contact-intents/:contactIntentId/status` | Filtros `status`, `providerProfileId`, `categoryId`, `clientId`; transitions aprobadas; no descripción libre en listado. |
| `/reviews` | `GET /admin/reviews`, detalle y auditoría | `PATCH /admin/reviews/:reviewId/visibility` | Motivo obligatorio de 1–500 caracteres; ocultar/restaurar sin editar/borrar. |
| `/availability` | `GET /admin/providers/:providerProfileId/availability` | Ninguna | Localidad/resumen solamente; sin geometrías ni edición. |
| `/memberships` | `GET /admin/membership-tiers`, detalle; lista admin de prestadores | `POST /admin/membership-tiers`, `PATCH /admin/membership-tiers/:tierId`, `PATCH /:tierId/archive`, `PATCH /admin/providers/:providerProfileId/membership` | Filtro `isArchived=false`; omitir filtro para incluir ambos; asignación usa `{tierId}`. |

Paginated admin-read responses use server `page/limit` and `data/total`; simple reads return `{data: list}`. Client-side pagination is used only where the endpoint does not return paginated metadata. No dashboard control depends on a local mock.

La lista de rutas y restricciones sigue el alcance aprobado en `specs/001-admin-dashboard/spec.md`. El estado de migración/API se registra en el [API traceability document](../../api-tooapp/docs/admin-traceability.md).
