# Research: pantalla conjunta Usuarios y prestadores

**Feature**: `001-admin-dashboard`  
**Fecha**: 2026-11-18

## Decision: endpoint combinado de lectura con paginación global

Implementar `GET /admin/accounts` dentro de `src/modules/admin-read/` y protegerlo con el guard existente `authenticate` + `requireRole('ADMIN')`. Las listas actuales `/admin/users` y `/admin/providers` tienen parámetros de página separados; mezclarlas en Flutter produciría páginas globales incorrectas. El endpoint nuevo combina filas CLIENT y PROVIDER, aplica filtros antes del conteo y devuelve una única página ordenada globalmente.

**Rationale**: el usuario aprobó una sola pantalla y búsqueda/paginación globales. Las entidades ya existen; se reutilizan las consultas de `User` y `ProviderProfile`, sin cambio de esquema ni migración. La autorización sigue en servidor.

**Alternatives considered**:
- Combinar páginas en el cliente: descartado porque páginas independientes no garantizan orden ni límites globales.
- Crear una nueva entidad/tabla de cuenta: descartado; duplicaría el modelo `User` y requeriría cambios de esquema innecesarios.
- Añadir escritura/edición desde la lista: descartado por la decisión explícita de solo lectura.

**Implementation note**: obtener candidatos suficientes de cada rama de rol, ordenar con una única clave estable (`createdAt DESC, User.id ASC`) y recortar la página global; calcular `total` con los filtros de ambas ramas. No concatenar resultados de las páginas actuales. El límite de página se conserva en 100. No hay objetivo de latencia aprobado; registrar el costo de páginas profundas para una revisión posterior si el volumen real lo requiere.

## Decision: contrato paginado `admin-read`

Usar `page` (1 por defecto), `limit` (20 por defecto, máximo 100), `q` (máximo 100), `accountType`, `isAccountActive`, `localityId`, `categoryId` y `isAvailable`, según aplicabilidad por tipo. La respuesta es `{data,total,page,limit}`, como las listas paginadas actuales de `admin-read`.

## Decision: módulo Flutter de lectura

Crear `features/accounts/` y una ruta/entrada `Usuarios y prestadores`. Mantener los demás módulos. La pantalla tiene una tabla, filtros, paginación global, carga/error/vacío/reintento y no contiene acciones de edición, estado o moderación.

## Decision: verificación sin base de datos

La estrategia usa pruebas de unidad de servicio/repositorio mockeado y pruebas de widget/data source Flutter con respuestas de fixture. No se conecta a PostgreSQL, no se ejecutan consultas/SQL, y no se crean ni aplican migraciones.
