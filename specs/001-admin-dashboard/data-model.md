# Data model: lista administrativa de cuentas

Este documento describe el DTO de lectura de `GET /admin/accounts`; no propone un modelo de persistencia nuevo.

## `AccountListItem`

| Campo | Tipo | Regla |
|---|---|---|
| `id` | UUID string | Identificador de `User`; único entre ambas ramas. |
| `accountType` | `CLIENT \| PROVIDER` | Discriminante requerido. |
| `firstName` | string | Nombre permitido por el DTO administrativo vigente. |
| `lastName` | string | Apellido permitido por el DTO administrativo vigente. |
| `email` | string or null | Email si la cuenta lo tiene informado. |
| `isAccountActive` | boolean | Estado de cuenta, solo lectura. |
| `createdAt` | RFC 3339 datetime | Orden de lista y presentación. |
| `locality` | `{id: UUID, name: string} \| null` | Localidad relacionada, solo lectura. |
| `providerProfile` | `ProviderAccountSummary \| null` | Null para CLIENT; objeto para PROVIDER. |

## `ProviderAccountSummary`

| Campo | Tipo | Regla |
|---|---|---|
| `id` | UUID string | Identificador de `ProviderProfile`. |
| `primaryCategory` | `{id: UUID, name: string} \| null` | Categoría principal si existe y el DTO actual la incluye. |
| `isAvailable` | boolean | Disponibilidad actual; no implica que la cuenta esté activa. Solo lectura. |

## Lista y filtros

- Query: `page` >=1 (default 1), `limit` 1..100 (default 20), `q` <=100, `accountType`, `isAccountActive`, `localityId`, `categoryId`, `isAvailable`.
- `categoryId` e `isAvailable` aplican solo a PROVIDER; combinarlos con `accountType=CLIENT` es `422`.
- `q` es búsqueda parcial insensible a mayúsculas en nombre, apellido, email y teléfono; categoría y localidad se filtran por sus IDs.
- Aplicar todos los filtros antes de calcular `total` y recortar página. Orden total estable por `createdAt DESC`, `id ASC`.
- Respuesta: `{data: AccountListItem[], total: integer, page: integer, limit: integer}`.

## Exclusiones

El DTO no devuelve DNI, contraseñas, hashes, refresh/access tokens, geometrías/coordenadas, ni campos de escritura. La pantalla y endpoint no crean, editan, activan/desactivan ni moderan portafolio. Sin tablas, columnas o migraciones nuevas.
