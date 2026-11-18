# Feature Specification: TÖÖ Admin Dashboard

**Feature Branch**: `001-admin-dashboard`  
**Created**: 2026-10-30  
**Status**: Approved
**Input**: Crear e implementar una consola web administrativa para TÖÖ y completar en el API el soporte de las opciones administrativas aprobadas, incluidos contratos, autorización, DTOs y persistencia cuando aplique. Respetar permisos del servidor, usar navegación adaptable y no simular capacidades cuyo backend aún no esté implementado.

## Clarifications

### Session 2026-10-30

- Q: ¿Qué roles podrán usar la administración? → A: Solo `ADMIN`; `SUPPORT` no tendrá acceso administrativo en la primera versión.
- Q: ¿Cómo se darán de alta las cuentas `ADMIN`? → A: Un operador autorizado las aprovisionará fuera de la consola; no habrá alta de `ADMIN` desde el registro público ni desde la consola en la primera versión.
- Q: ¿Qué nivel de gestión querés para los módulos administrativos? → A: Consultar, crear, editar y cambiar estados según corresponda; conservar registros mediante archivo o desactivación en vez de eliminación permanente.
- Q: ¿Qué acciones podrá realizar `ADMIN` sobre pagos? → A: Pagos quedan fuera de la primera versión porque el API no tiene una fuente identificada; no se implementan consulta, detalle, modelos ni endpoints administrativos de pagos. Esta decisión posterior reemplaza la respuesta inicial que proponía consulta.
- Q: ¿Cómo querés que `ADMIN` modere las reseñas? → A: Consultar, ocultar y restaurar reseñas; exigir motivo y guardar auditoría, sin editar su contenido ni borrarlas permanentemente.
- Q: ¿Qué decisiones aprobás para cerrar G1–G9? → A: El API no registra ni crea cuentas `ADMIN`; usuarios y prestadores se consultan juntos en una pantalla de solo lectura según la aclaración del 2026-11-18, sin DNI ni coordenadas precisas; categorías permiten crear en `PENDING`, editar nombre/icono y transicionar `PENDING` a `APPROVED` o `REJECTED` (`REJECTED` terminal), con desactivación solo para aprobadas; contactos permiten `PENDING` a `SCHEDULED`/`CANCELLED` y `SCHEDULED` a `COMPLETED`/`CANCELLED`, sin descripción libre en listados; servicios se representan mediante categorías/perfil, no una entidad `Service`; portafolio se oculta/restaura con auditoría; reseñas requieren motivo de 1–500 caracteres y auditoría append-only visible en su detalle; ubicación muestra localidad y disponibilidad solo lectura; membresías permiten administrar tiers en ARS y asignar tier sin crear suscripciones/historial; pagos quedan fuera de la primera versión porque no existe fuente identificada; listados usan `page`/`limit` (20 por defecto, máximo 100) y los filtros/búsquedas definidos en el contrato; dashboard usa `Provider`, `Dio` y `go_router`, con tokens visuales centralizados.

### Session 2026-11-17

- Q: ¿Cómo se debe usar la referencia Davinci para renovar la administración? → A: Tomar únicamente su composición (navegación lateral agrupada, barra superior, encabezado y organización en tarjetas/paneles). La página observada es el dashboard User; no confirma una consola Admin. Mantener marca y paleta TooApp del tema actual (`#165D54`, `#F5F7F6`) y no copiar textos, datos ni métricas.
- Q: ¿El rediseño cambia el alcance de gestión administrativa aprobado? → A: No; la consola debe cubrir las áreas y acciones definidas en FR-024–FR-030. Las brechas del API son trabajo de backend dentro del alcance original de la feature. Mantener operaciones reversibles y las políticas existentes; no agregar borrado permanente ni módulos de pagos, localidades o servicios independientes.
- Q: ¿Qué autenticación consume el dashboard actual? → A: Usar el contrato vigente de `api-tooapp`: JWT Bearer en `/auth/login`, `/auth/refresh` y `/auth/logout`. No usar rutas de cookies `/admin/auth/*` que no existen en esa API.

### Session 2026-11-18

- Q: ¿Cómo deben obtenerse y paginarse los clientes y prestadores en la pantalla conjunta? → A: Crear `GET /admin/accounts`, un endpoint administrativo protegido de solo lectura que combine ambos tipos en una búsqueda y paginación globales, usando las tablas/modelos existentes y sin cambios de esquema ni modificaciones a la base de datos.

- Q: ¿Cómo deben organizarse usuarios y prestadores en la administración? → A: Mostrar clientes y prestadores juntos en una única pantalla de solo lectura; conservar los demás módulos administrativos. No permitir editar perfiles, cambiar estados ni moderar portafolios desde la pantalla combinada.

- Q: ¿Qué paleta de TooApp debe usar el dashboard tras revisar `too_app_mobile`? → A: Alinear el dashboard con los tokens móviles: azul primario `#0875CE`, verde `#007A59` y fondo `#F6F6F7`, con texto oscuro y superficies claras.

- Q: ¿A qué operaciones de actualización se refiere la consulta sobre PUT? → A: A la edición administrativa del perfil de un prestador y al cambio del estado de su cuenta desde el dashboard. La API usa PATCH en `/admin/providers/:providerProfileId` y `/admin/users/:userId/account-status`; no usa PUT para esos flujos.

- Q: ¿A qué lista de prestadores se refiere el problema de carga? → A: A la lista administrativa del módulo Prestadores en el dashboard, no a los resultados de búsqueda cercana de la app móvil.

- Q: ¿Qué acceso del agente a bases de datos se permite? → A: Ninguno. No debe conectarse ni consultar bases de datos, incluso en modo de solo lectura, ni ejecutar SQL, seeds, resets, db push, migraciones o comandos equivalentes. El esquema y las migraciones solo se inspeccionan o editan como archivos locales; nunca se aplican a una base de datos.

- Q: ¿Cómo se define un prestador activo en el resumen de Inicio? → A: Contar registros `ProviderProfile` cuya cuenta asociada tenga `User.isAccountActive = true`, independientemente de su disponibilidad horaria.
- Q: ¿Qué representa el indicador de servicios publicados con el modelo actual? → A: Contar asociaciones de categoría primaria y secundaria de `ProviderProfile` con categorías `APPROVED` y `isActive = true`; ese conteo se presenta como servicios publicados sin crear una entidad `Service`.
- Q: ¿Qué representa el indicador de mensajes nuevos con el modelo actual? → A: Contar `ContactIntent` en estado `PENDING` como solicitudes de contacto pendientes; la interfaz no debe llamarlas mensajes de chat.
- Q: ¿Cómo se identifican los prestadores por verificar? → A: Añadir un estado explícito de verificación administrativa al `ProviderProfile` y contar solo los perfiles cuyo estado sea `PENDING`; no inferirlo de `isMatriculado`.
- Q: ¿Cómo se identifica una reseña reportada en el indicador de pendientes? → A: Vincular cada reporte con su `Review` y contar reseñas distintas con al menos un reporte no resuelto (`Report.isResolved = false`); `Review.visibility = HIDDEN` no sustituye ese vínculo.

- Q: ¿Qué datos deben aparecer en un formulario de edición? → A: Solo los datos editables; cualquier dato no editable, incluida la localidad en Prestadores, se omite del formulario aunque pueda mostrarse en vistas de consulta.
- Q: ¿Qué referencia visual guía la nueva composición de la administración? → A: Adoptar de Kite el sidebar agrupado, la barra superior contextual, la toolbar local de búsqueda/filtros/acciones, las tablas compactas con estados y paginación; mantener los colores TooApp, Material Icons instalados y no copiar métricas ni controles sin soporte del API.
- Q: ¿Cómo deben distinguirse los colores del navbar? → A: El texto y los iconos deben contrastar con el fondo en estados activo e inactivo; la sección seleccionada debe tener un fondo perceptiblemente distinto.

## User Scenarios & Testing

### User Story 1 - Resolver reportes (Priority: P1)

Como integrante del equipo con rol `ADMIN`, quiero revisar los reportes recibidos, filtrar los pendientes o resueltos y marcar un reporte como resuelto para dar seguimiento a las comunicaciones de la comunidad.

**Why this priority**: Es un flujo administrativo integral con listado, filtros, información de quien reporta y una acción protegida confirmada por el API.

**Independent Test**: Con una sesión `ADMIN` y reportes de distintos tipos y estados, consultar el listado, aplicar filtros, abrir el detalle presentado en el listado y resolver un reporte; verificar que la interfaz refleje el estado confirmado por el servidor.

**Acceptance Scenarios**:

1. **Given** una persona autenticada con rol `ADMIN`, **When** abre Reportes, **Then** ve los reportes ordenados del más reciente al más antiguo, su tipo, contenido, estado, fechas e información disponible del autor.
2. **Given** que hay reportes de tipos y estados diferentes, **When** filtra por tipo o estado de resolución, **Then** ve solo los registros que coinciden con los filtros seleccionados.
3. **Given** un reporte no resuelto, **When** confirma la acción Resolver, **Then** el reporte queda marcado como resuelto únicamente si el servidor confirma la operación.
4. **Given** una persona sin rol `ADMIN` o sin sesión válida, **When** intenta consultar o resolver reportes administrativos, **Then** el servidor deniega la operación y la consola no muestra el resultado como exitoso.

### User Story 2 - Consultar y unificar categorías (Priority: P1)

Como integrante del equipo con rol `ADMIN`, quiero consultar categorías por estado y actividad, y unificar una categoría pendiente con otra aprobada para conservar las referencias de prestadores y contactos bajo una categoría válida.

**Why this priority**: La consulta administrativa y la unificación están respaldadas por contratos existentes y la unificación modifica relaciones de producto, por lo que debe ser explícita y confirmada.

**Independent Test**: Con una sesión `ADMIN`, consultar categorías y aplicar filtros; seleccionar una categoría `PENDING` de origen y una `APPROVED` de destino distintas; confirmar la unificación y verificar resultado comunicado por el servidor.

**Acceptance Scenarios**:

1. **Given** una persona `ADMIN`, **When** abre Categorías, **Then** ve nombre, icono disponible, estado, actividad, fecha de creación y conteos disponibles de prestadores principales y secundarios.
2. **Given** la lista de categorías, **When** aplica filtro por estado o actividad, **Then** la lista refleja los filtros y permite volver a la vista sin filtros.
3. **Given** una categoría pendiente y una aprobada distintas, **When** el administrador confirma la unificación, **Then** la consola muestra el resultado confirmado, incluido el total de prestadores afectados que informe el servidor.
4. **Given** que el origen no está `PENDING`, el destino no está `APPROVED`, son la misma categoría o una no existe, **When** se intenta unificar, **Then** se muestra el error correspondiente y no se representa la acción como completada.
5. **Given** una persona sin autorización `ADMIN`, **When** intenta listar o unificar categorías administrativas, **Then** el servidor deniega la operación.

### User Story 3 - Acceder a la consola según el rol autorizado (Priority: P1)

Como personal autorizado, quiero iniciar sesión y acceder únicamente a las funciones administrativas permitidas por mi rol, para proteger los datos de TÖÖ.

**Why this priority**: La consola maneja datos personales y acciones administrativas; el control de acceso es condición para usar cualquier módulo.

**Independent Test**: Probar acceso con credenciales válidas de una cuenta `ADMIN`, credenciales incorrectas y cuentas de otros roles; verificar que rutas y datos administrativos queden protegidos por el servidor en todos los casos.

**Acceptance Scenarios**:

1. **Given** credenciales válidas de una cuenta con rol `ADMIN`, **When** inicia sesión, **Then** la consola abre las áreas administrativas confirmadas.
2. **Given** credenciales inválidas, **When** intenta iniciar sesión, **Then** recibe un mensaje comprensible sin información sensible ni detalles internos.
3. **Given** una cuenta autenticada cuyo rol no autoriza una acción administrativa, **When** la intenta mediante la consola o una solicitud directa, **Then** el servidor la deniega y la consola informa que no tiene acceso.
4. **Given** una sesión vencida o revocada, **When** la persona visita un área protegida, **Then** la consola solicita autenticación nuevamente y no presenta datos protegidos almacenados como vigentes.

### User Story 4 - Encontrar módulos y operar en distintos tamaños (Priority: P2)

Como integrante autorizado del equipo, quiero encontrar rápidamente las áreas disponibles en una navegación coherente y completar las tareas principales desde desktop o móvil.

**Why this priority**: Una navegación compartida permite usar de forma consistente las capacidades confirmadas y reduce la pérdida de contexto al cambiar de módulo o dispositivo.

**Independent Test**: Navegar entre módulos y aplicar/limpiar filtros en las pantallas disponibles, en viewport amplio y compacto, usando teclado; verificar resultados correctos, sección activa y estados diferenciados.

**Acceptance Scenarios**:

1. **Given** una persona autenticada y un viewport amplio, **When** navega por la consola, **Then** encuentra un drawer vertical persistente con Inicio, Reportes y Categorías, y la sección activa está identificada visualmente y para tecnologías de asistencia.
2. **Given** un viewport compacto, **When** abre la navegación, **Then** accede a las mismas áreas mediante un drawer lateral adaptable y accesible.
3. **Given** cualquier módulo administrativo disponible, **When** la persona lo usa con teclado, foco visible y texto ampliado, **Then** puede acceder a los controles y completar las tareas principales.
4. **Given** una pantalla con filtros, **When** selecciona uno o más valores, **Then** se muestran solo resultados coincidentes y cada filtro activo puede quitarse individualmente o todos juntos.
5. **Given** una lista sin resultados para los filtros activos, **When** limpia los filtros, **Then** la pantalla vuelve al conjunto de resultados disponible y diferencia ese caso de una lista originalmente vacía.
6. **Given** una pantalla de categorías o reportes, **When** el administrador configura filtros, **Then** solo se usan filtros admitidos por el contrato actual; la búsqueda superior, si existe, conduce a módulos/acciones y no aparenta buscar registros.
7. **Given** un viewport compacto o amplio, **When** administra filtros con teclado, **Then** puede abrir, cambiar y limpiar filtros con foco visible y los controles no desbordan el área de contenido.
8. **Given** un administrador autorizado, **When** abre Usuarios y prestadores, **Then** ve ambas poblaciones juntas en una sola pantalla de solo lectura, y las demás áreas administrativas aprobadas continúan disponibles.

### User Story 5 - Acceder a opciones administrativas respaldadas de punta a punta (Priority: P2)

Como integrante del equipo, quiero que cada opción administrativa acordada tenga su operación real y protegida en el API antes de usarla en la consola, para que la administración cubra el producto de punta a punta.

**Why this priority**: La app incluye áreas para las que todavía faltan operaciones administrativas globales. El backend es parte de la entrega y debe soportar las opciones de administración, no quedar como una dependencia indefinida.

**Independent Test**: Para cada acción aprobada en la matriz de administración, verificar una operación protegida del API, su controller, su modelo/DTO y su prueba; comprobar que la consola solo la habilita cuando todo el recorrido funciona.

**Acceptance Scenarios**:

1. **Given** una acción acordada cuyo API aún no está implementado, **When** el administrador consulta la consola, **Then** esa opción no se presenta como operativa.
2. **Given** una acción acordada, **When** se completa su desarrollo, **Then** existe contrato, controller, modelo/DTO, validación, autorización de servidor y pruebas antes de habilitar su control en la interfaz.
3. **Given** la página Inicio, **When** presenta el resumen administrativo, **Then** muestra usuarios registrados, prestadores activos y servicios publicados, además de los tres pendientes y los indicadores de nuevos usuarios/prestadores según FR-008; los indicadores no redirigen y el selector alterna 7/30 días.

### Edge Cases

- El servidor responde `401` o `403` durante una consulta, una resolución o una unificación; la consola conserva la integridad de los datos visibles, informa el problema y no declara éxito.
- Una lista administrativa devuelve cero registros: se diferencia el estado vacío de una carga en curso o un error.
- Un filtro no produce resultados: se explica que no hay coincidencias y se facilita limpiar el filtro.
- Una acción de unificación recibe referencias inválidas, duplicadas o estados no admitidos: se conservan las selecciones y se comunica el error del servidor.
- La conexión se interrumpe antes de recibir confirmación: el resultado se considera no confirmado y se permite volver a consultar el estado antes de repetir una acción de impacto.
- El texto de reporte o los datos del autor son extensos o contienen campos nulos: se presentan de forma legible y segura sin exponer secretos ni errores internos.
- La sesión expira mientras el usuario completa un formulario o revisa una lista: los cambios no se comunican como guardados.
- En un viewport compacto, filtros, confirmaciones y controles de fila deben seguir siendo alcanzables sin desbordamiento horizontal que impida completar las tareas.

## Requirements

### Requisitos de acceso y seguridad

- **FR-001**: La consola MUST permitir el acceso administrativo solo a una sesión autenticada con rol `ADMIN`; el servidor MUST denegar a `SUPPORT` y a cualquier otro rol todas las operaciones administrativas de la primera versión.
- **FR-002**: La consola MUST comprobar las respuestas de autorización del servidor en cada operación protegida; ocultar controles o restringir rutas en cliente MUST NOT sustituir la autorización del servidor.
- **FR-003**: El ingreso administrativo MUST usar el mecanismo de autenticación vigente del API y MUST NOT permitir que la consola cree o eleve cuentas a `ADMIN`.
- **FR-004**: Si una credencial o sesión no es válida, la consola MUST evitar presentar contenido administrativo protegido como vigente y MUST comunicar el estado sin revelar tokens, secretos, datos personales innecesarios ni detalles internos.
- **FR-005**: Las cuentas `ADMIN` MUST ser aprovisionadas por un operador autorizado fuera de la consola; el registro público y la consola MUST NOT crear ni elevar cuentas a `ADMIN` en la primera versión. La política de recuperación de acceso, duración y revocación de sesiones MUST quedar definida antes de considerar completo el flujo de acceso.

### Requisitos de navegación, diseño y accesibilidad

- **FR-006**: La consola MUST presentar navegación lateral agrupada, persistente en layouts amplios y adaptable en layouts compactos, siguiendo la jerarquía de composición de `design-reference.md` sin replicar su marca o contenido.
- **FR-007**: La navegación MUST reflejar únicamente módulos y opciones cuyo flujo esté implementado y autorizado de punta a punta para el rol activo, indicar la sección actual y conservar acceso equivalente en desktop y móvil.
- **FR-008**: La consola MUST ofrecer una página Inicio con el resumen administrativo solicitado, en indicadores informativos no clicables; la navegación entre módulos permanece en el drawer. Usuarios registrados cuentan cuentas `User` con rol `CLIENT` o `PROVIDER`, excluyendo `ADMIN`/`SUPPORT`. Prestadores activos cuentan registros `ProviderProfile` cuya cuenta asociada tenga `User.isAccountActive = true`, independientemente de disponibilidad horaria. Servicios publicados cuentan asociaciones de categoría primaria/secundaria de `ProviderProfile` con categorías `APPROVED` e `isActive = true`, sin crear entidad `Service`. Solicitudes de contacto pendientes cuentan `ContactIntent.status = PENDING` y MUST NOT presentarse como mensajes de chat. Prestadores por verificar cuentan únicamente `ProviderProfile.verificationStatus = PENDING`, sin inferirlo de `isMatriculado`. Reseñas reportadas cuentan reseñas distintas con al menos un `Report.reviewId` vinculado no resuelto (`isResolved = false`), sin inferir reportes de `Review.visibility`. Indicadores de nuevos usuarios y nuevos prestadores cuentan altas dentro de una ventana móvil UTC de 7 o 30 días, seleccionable en Inicio; por defecto son 7 días. Todas las cifras deben confirmarse por el servidor y mostrar su fuente/regla; estados de carga, error y reintento MUST ser perceptibles.
- **FR-009**: La consola MUST permitir completar en desktop y móvil los flujos principales de consultar, filtrar y ejecutar acciones administrativas confirmadas.
- **FR-010**: Los controles MUST ser operables mediante teclado, conservar foco visible, exponer nombres y estados a lectores de pantalla, mantener contraste suficiente y tolerar ampliación de texto. El texto y los iconos del navbar MUST distinguirse del fondo en estados activo e inactivo; la sección seleccionada MUST tener un tratamiento de fondo perceptiblemente distinto.
- **FR-011**: La consola MUST conservar la identidad visual TooApp alineada con `too_app_mobile/lib/src/globals/app_theme.dart`: azul primario `#0875CE`, verde `#007A59` y fondo `#F6F6F7`, con texto oscuro y superficies claras. Estos valores son los tokens de referencia para el dashboard; no importar paletas, tipografías ni estilos de marca de la referencia visual externa.
- **FR-043**: El área de contenido MUST usar la jerarquía observada en `design-reference.md`: barra superior con contexto/controles disponibles, encabezado de página y paneles/tarjetas adaptables. MUST NOT presentar métricas, acciones globales o controles que no estén respaldados por datos o comportamiento confirmado del API.
- **FR-044**: Las pantallas administrativas MUST presentar búsqueda y filtros contextuales en una zona consistente bajo el encabezado del módulo, con composición inspirada en `design-reference.md` y colores tomados de los tokens TooApp.
- **FR-045**: La búsqueda global, si se muestra, MUST encontrar únicamente módulos y acciones de navegación disponibles. MUST NOT aparentar búsqueda global de registros ni emitir consultas entre entidades sin contrato explícito.
- **FR-046**: Cada filtro MUST corresponder a una capacidad confirmada del API. Usuarios y prestadores usan los parámetros de `GET /admin/accounts`; categorías se filtran por estado/actividad y reportes por tipo/resolución, sin inventar capacidades fuera de sus contratos. Contactos y reseñas conservan solo filtros de sus contratos vigentes.
- **FR-047**: Los filtros activos MUST ser identificables y limpiables individualmente o en conjunto. Al cambiar búsqueda o filtros, la pantalla MUST actualizar resultados y reiniciar a la primera página cuando haya paginación.
- **FR-048**: En anchos amplios, búsqueda y filtros MUST presentarse en una zona compacta bajo el encabezado. En anchos estrechos, los controles MUST reorganizarse para caber en el contenido sin desbordamiento, conservando filtros activos, acciones para limpiarlos y acceso a resultados.
- **FR-049**: Las pantallas filtrables MUST distinguir carga, error recuperable, lista vacía y resultados sin coincidencias. Limpiar filtros MUST permitir volver al conjunto de resultados disponible.

### Requisitos de capacidades administrativas y contrato vigente

- **FR-012**: Para el módulo Reportes, la consola MUST consultar la lista administrativa con los datos disponibles: identificador, autor, tipo (`SUGGESTION`, `CLAIM` o `USER_REPORT`), contenido, estado resuelto/no resuelto y fechas de creación y actualización; cuando esté disponible, MUST mostrar del autor identificador, nombre, apellido, email y teléfono.
- **FR-013**: Reportes MUST permitir filtrar por tipo y estado de resolución. La consulta administrativa actual no ofrece búsqueda textual ni paginación; la interfaz MUST no enviar esos parámetros no confirmados.
- **FR-014**: Reportes MUST permitir marcar un elemento como resuelto mediante la acción administrativa autorizada. La consola MUST solicitar confirmación antes de ejecutar la acción y comunicar el estado solo después de la confirmación del servidor. No se debe asumir una acción para reabrir o eliminar reportes.
- **FR-015**: Para el módulo Categorías, la consola MUST consultar nombre, URL de icono cuando exista, estado (`APPROVED`, `PENDING`, `REJECTED`), actividad, fecha de creación y conteos de prestadores primarios y secundarios retornados por el API.
- **FR-016**: Categorías MUST permitir filtrar por estado y actividad. La consulta administrativa actual no ofrece búsqueda textual ni paginación; la interfaz MUST no enviar esos parámetros no confirmados.
- **FR-017**: Categorías MUST permitir la unificación administrativa solo entre una categoría de origen `PENDING` y una categoría destino `APPROVED`, distintas entre sí. Antes de confirmar, la consola MUST explicar el impacto de reasignación y solicitar confirmación explícita; después MUST mostrar únicamente el resultado confirmado por el servidor.
- **FR-018**: Categorías MUST permitir crear en `PENDING`, editar nombre e icono, transicionar de `PENDING` a `APPROVED` o `REJECTED` (siendo `REJECTED` terminal) y desactivar categorías `APPROVED`. No permitir eliminación permanente.
- **FR-019**: Los módulos Reportes y Categorías MUST mostrar estados distinguibles de carga, vacío, sin coincidencias, éxito y error, y permitir reintentar una consulta fallida cuando corresponda.

### Requisitos de cobertura administrativa y desarrollo del API

- **FR-020**: La solución completa MUST cubrir las áreas administrativas acordadas para el producto y MUST clasificar cada acción como **disponible con contrato confirmado**, **requiere desarrollo del API** o **fuera del alcance acordado**. La presencia de una pantalla, tabla o entidad MUST NOT implicar por sí sola permiso administrativo.
- **FR-021**: El inicio, renovación y cierre de sesión existentes son capacidades confirmadas. En la primera versión, un operador autorizado aprovisiona las cuentas `ADMIN` fuera de la consola; la consola y el registro público MUST NOT crear ni elevar cuentas a `ADMIN`. Solo `ADMIN` puede operar la consola; `SUPPORT` MUST NOT acceder a sus módulos ni operaciones. La recuperación y revocación de cuentas deben seguir una política segura definida para la entrega.
- **FR-022**: Categorías tiene consulta filtrada y unificación confirmadas. Toda otra opción administrativa acordada para este módulo —por ejemplo alta, edición, aprobación/rechazo o activación/desactivación— MUST tener reglas de negocio y operación administrativa implementada en el API antes de aparecer en la consola.
- **FR-023**: Reportes tiene listado filtrado y resolución confirmados. Toda otra opción administrativa acordada —por ejemplo búsqueda, paginación, lectura individual, asignación, notas internas, reapertura o eliminación— MUST tener contrato y operación implementados en el API antes de aparecer en la consola.
- **FR-024**: La consola MUST presentar clientes y prestadores de la app en una única pantalla administrativa de solo lectura, con tipo de cuenta identificable y consulta conjunta conforme a los datos que entrega el API. MUST NOT ofrecer edición de perfil, activación/desactivación, creación de cuenta ni moderación de portafolio desde esta pantalla. MUST NOT exponer DNI, contraseñas, hashes ni coordenadas precisas; la localidad es solo lectura.
- **FR-025**: La pantalla conjunta MUST consumir `GET /admin/accounts`, protegido para `ADMIN`, que combina clientes y prestadores en un solo resultado paginado globalmente, con `page`/`limit` (default 20, máximo 100), búsqueda `q` y filtros admitidos para tipo de cuenta, estado, localidad y atributos de prestador como categoría/disponibilidad. Cada fila MUST identificar `CLIENT` o `PROVIDER` y puede incluir datos de perfil profesional solo para prestadores. El endpoint y la pantalla son de solo lectura; MUST NOT ofrecer edición, activación/desactivación, creación ni moderación de portafolio. El endpoint reutiliza los modelos existentes y MUST NOT requerir cambios de esquema ni modificaciones a la base de datos. MUST NOT exponer DNI, credenciales ni coordenadas precisas. Los servicios siguen representados mediante categorías y datos del perfil, sin entidad independiente `Service`.
- **FR-026**: Contactos MUST permitir consulta y filtros por estado/proveedor/categoría/cliente; el listado no expone la descripción libre del problema. Las únicas transiciones administrativas son `PENDING`→`SCHEDULED`/`CANCELLED` y `SCHEDULED`→`COMPLETED`/`CANCELLED`; no se reabren estados terminales. Cada cambio registra actor, fecha y transición.
- **FR-027**: Para reseñas, `ADMIN` MUST poder consultar y moderar la visibilidad mediante ocultar y restaurar. Cada cambio MUST exigir un motivo, registrar actor, fecha, acción y motivo en auditoría, y conservar el contenido original. `ADMIN` MUST NOT editar el contenido ni eliminar permanentemente una reseña en la primera versión. Las operaciones de cliente/prestador existentes no autorizan moderación administrativa; el API deberá implementar estados, modelos/DTOs y operaciones de moderación.
- **FR-028**: Administración puede consultar localidad y resumen de disponibilidad del prestador; no puede ver ni modificar coordenadas precisas ni editar disponibilidad en la primera versión.
- **FR-029**: Membresías MUST permitir consultar y administrar niveles con nombre, descripción y precio entero en ARS, archivar tiers preservando asignaciones y asignar un tier a un prestador con confirmación y auditoría. No crear entidades de suscripción ni historial de renovaciones en la primera versión. Pagos quedan fuera de la primera versión: el API no tiene modelo ni fuente de pagos identificada; no se crearán datos, modelos ni endpoints ficticios. No habrá operaciones financieras.
- **FR-030**: La consola MUST mostrar la localidad como dato de solo lectura en vistas de consulta dentro de los módulos administrativos aprobados y MUST NOT incluirla en formularios de edición. MUST NOT ofrecer un módulo independiente de localidades ni permitir buscar, crear, editar, habilitar, deshabilitar o eliminar localidades en la primera versión.
- **FR-031**: Para Inicio, cualquier cifra o indicador MUST provenir de un agregado definido y entregado por el API. Si no se acuerdan métricas, Inicio MUST limitarse a orientar hacia módulos y tareas.
- **FR-032**: Cada opción administrativa incluida en el producto MUST tener un contrato del API que especifique operación, request y response tipados, campos, filtros/paginación, validaciones, estados, reglas de negocio, rol/permisos del servidor, efectos secundarios y errores esperables.
- **FR-033**: El alcance de entrega MUST incluir en el API las rutas, autenticación/autorización, validadores, controllers, lógica de servicio, persistencia y modelos/DTOs tipados que requiera cada opción administrativa acordada. Se deben reutilizar modelos existentes cuando representen fielmente la entidad; se crearán o modificarán modelos de dominio/persistencia solo cuando el cambio de datos esté justificado por reglas aprobadas. No se considerará completa una opción si solo existe su control visual o si su controller no persiste y devuelve el resultado real.
- **FR-034**: La consola MUST NOT mostrar una acción como disponible hasta que su operación del API esté implementada, protegida, documentada y verificada mediante pruebas de contrato e integración. La ausencia actual de soporte se considera trabajo obligatorio de backend dentro del alcance acordado, no una autorización para simular la función.
- **FR-035**: El equipo MUST mantener una matriz trazable que relacione área y acción administrativa con rol autorizado, contrato/operación del API, controller, modelo/DTO, validaciones, pruebas y control visible de la consola. Ninguna acción acordada puede quedar sin correspondencia en ambos lados.
- **FR-036**: La definición de campos consultables, edición permitida, transiciones de estado y tratamiento de datos sensibles MUST completarse antes de implementar la operación correspondiente. Los elementos sin decisión deben permanecer identificados como pendientes de definición y no se deben completar por inferencia.
- **FR-041**: Como nivel base de gestión, cada módulo acordado MUST permitir consultar y, cuando aplique a la entidad, crear, editar y cambiar estados mediante acciones autorizadas por el servidor, salvo la pantalla conjunta de Usuarios y prestadores definida por FR-024 y FR-025, que es estrictamente de solo lectura. Las transiciones concretas se definirán por entidad y no se inferirán de operaciones de la app móvil.
- **FR-042**: La consola y el API MUST conservar los registros administrativos mediante desactivación o archivo en lugar de eliminación permanente. Una excepción requiere una regla de negocio específica, autorización, confirmación, trazabilidad y aprobación previa; la unificación de categorías existente se trata como flujo especial con reasignación y confirmación, no como acción de borrado genérica.
- **FR-050**: Los formularios de creación y edición MUST mostrar únicamente datos que el administrador pueda modificar en ese formulario. Los datos de solo lectura se omiten del formulario, aunque puedan mostrarse en listados o vistas de detalle.
- **FR-051**: Los listados administrativos de registros repetidos MUST usar una tabla con encabezados claros, divisores de fila, estados compactos y acciones por registro; deben conservar los campos y acciones respaldados por el API. En anchos compactos, el desplazamiento horizontal MUST mantener accesibles todas las columnas y controles. Los contenidos extensos que requieren lectura íntegra pueden conservar una presentación de lectura completa.

### Requisitos de consulta y manejo de resultados

- **FR-037**: Toda acción con impacto significativo o irreversible MUST presentar un resumen de impacto y solicitar confirmación explícita antes de enviarse. La unificación de categorías y la resolución de reportes requieren confirmación.
- **FR-038**: La consola MUST validar las selecciones y entradas antes del envío y MUST reflejar los errores de validación del servidor de manera comprensible sin exponer mensajes internos sensibles.
- **FR-039**: Si una solicitud falla, expira o no recibe confirmación, la consola MUST NOT marcarla como exitosa; debe comunicar el resultado desconocido o fallido y permitir verificar el estado antes de repetir acciones con efectos.
- **FR-040**: La consola MUST limitar la información personal a los campos que el servidor entrega y que son necesarios para la tarea administrativa autorizada. La interfaz MUST NOT registrar ni mostrar tokens, contraseñas, hashes o secretos.

### Organización funcional trazable

El dashboard target ya contiene arquitectura por `lib/src/features/<funcionalidad>/{data,models,presentation}` y pantallas para varias áreas; el router y contratos deben reconciliarse con el estado real antes de habilitar cada destino. La matriz establece además el trabajo administrativo API requerido. Las acciones y campos permitidos son los definidos por área en esta especificación; la matriz no concede permisos por sí sola.

| Área | API administrativo existente | Trabajo requerido en el API para completar la administración acordada | Organización funcional del dashboard |
|---|---|---|---|
| Acceso administrativo | `POST /auth/login`, `/auth/refresh`, `/auth/logout` con JWT Bearer. Solo `ADMIN`; `SUPPORT` queda excluido. | Proteger todos los módulos y conservar aprovisionamiento externo de cuentas `ADMIN`; sin creación pública de `ADMIN` ni acceso de `SUPPORT`. | `features/access/{data,models,presentation}` |
| Inicio | `GET /admin/dashboard/summary?periodDays=7|30` devuelve conteos agregados protegidos por `ADMIN`. | Flutter presenta totales, pendientes y altas recientes; se usa `ContactIntent.status=PENDING` para solicitudes de contacto. | Agregados de lectura en API, sin entidad Service; estado de verificación y vínculo opcional Report–Review según FR-008. | Ventana móvil UTC; default 7 días; sin tarjetas de navegación en el área de contenido. |
| Reportes | `GET /admin/reports` y `PATCH /admin/reports/:id/resolve`. | Integrar filtros y resolución, vincular los reportes aplicables a `Review` y exponer en Inicio el conteo de reseñas distintas con reportes no resueltos; no agregar asignación, notas, reapertura ni borrado. | `features/reports/{data,models,presentation}` |
| Categorías | Lectura, creación, edición, actividad y unificación admin ya existen. | Ajustar Flutter a filtros y reglas actuales; conservar transiciones aprobadas y flujo especial transaccional de unificación. | `features/categories/{data,models,presentation}` |
| Usuarios y prestadores | Nuevo `GET /admin/accounts` de solo lectura, protegido por rol ADMIN y paginado globalmente. | Agregar contrato y consulta que combine `User` CLIENT y PROVIDER con sus perfiles, búsqueda/filtros globales y DTO discriminado; reutilizar tablas/modelos existentes sin migraciones ni cambios a la base de datos. | Una pantalla `Usuarios y prestadores` integra `features/users/` y `features/providers/`; no ofrece mutaciones. |
| Servicios y portafolio | No existe una entidad independiente `Service`; los servicios se representan mediante categorías y datos del perfil. | Las categorías conservan su módulo propio. La pantalla conjunta solo consulta datos de perfil; no ofrece moderación del portafolio. | Categorías en `features/categories/`; datos de prestador visibles en la pantalla conjunta, solo lectura. |
| Contactos | `GET` admin de lista/detalle; clientes mantienen sus propios cambios de estado. | Usar `PATCH` admin con transiciones aprobadas y registrar actor/fecha; omitir descripción libre en listados. | `features/contacts/{data,models,presentation}` |
| Reseñas | `GET /admin/reviews` existía; visibilidad y detalle/auditoría se agregan en este incremento. | Ocultar/restaurar con motivo y auditoría; conservar contenido original, sin edición ni borrado permanente. | `features/reviews/{data,models,presentation}` |
| Disponibilidad y ubicaciones | Disponibilidad admin se agrega como lectura resumida por prestador; localidades siguen siendo públicas/dato relacionado. | No modificar disponibilidad/localidad ni exponer coordenadas precisas. | `features/availability/{data,models,presentation}` |
| Membresías y suscripciones | `GET` admin de niveles/detalle existía; tiers no archivados y perfil propio del prestador. | Se agregan alta/edición/archivo y asignación reversible; no se modelan suscripciones históricas. | `features/memberships/{data,models,presentation}` |
| Pagos | Excluidos de v1; no hay fuente de pagos identificada. | No crear modelos, DTOs, endpoints ni pantallas de pagos. | Fuera de alcance |
| Localidades | Dato relacionado de solo lectura; sin mantenimiento administrativo en v1. | Exponer únicamente el dato de localidad necesario dentro de módulos autorizados; sin listado, búsqueda ni mutaciones administrativas. | Se muestra como campo relacionado en `features/providers/` o `features/availability/`; no crear `features/localities/` |

La presentación, estado, acceso a datos y modelos tipados deben mantener responsabilidades separadas conforme a la constitución. En el API, cada área debe usar los controllers, servicios, persistencia, validadores y modelos/DTOs que correspondan a las operaciones acordadas, respetando las convenciones ya existentes. El mapeo no aprueba dependencias ni fija nombres concretos de rutas o archivos; la decisión explícita de G1–G9 sí aprueba `Provider`, `Dio` y `go_router` para esta feature, con versiones compatibles por resolver contra el SDK del dashboard.

## Key Entities

- **Cuenta administrativa**: cuenta de usuario autenticada con rol `ADMIN`; el API contempla además `SUPPORT`, pero no autoriza ese rol en los endpoints administrativos confirmados. Su aprovisionamiento y permisos por módulo están pendientes.
- **Reporte**: comunicación de un usuario con tipo, contenido, estado de resolución, autor y fechas. Los reportes de reseñas mantienen una relación explícita con `Review`; el conteo de Inicio considera reseñas distintas con al menos un reporte no resuelto. El contrato de listado administrativo incluye datos básicos del autor.
- **Categoría**: clasificación que posee nombre, URL de icono opcional, estado, actividad y referencias de prestadores; puede ser origen o destino de una unificación bajo las reglas confirmadas.
- **Prestador afectado**: perfil profesional que puede estar asociado a categorías primarias y secundarias; aparece en el conteo/resultado de unificación, pero no es administrable globalmente con los contratos actuales.
- **Cuenta de la app**: cliente (`CLIENT`) o prestador (`PROVIDER`); `GET /admin/accounts` las combina en una lista globalmente paginada con tipo identificable. Los datos de perfil de prestador se relacionan con su cuenta; el DTO no incluye coordenadas ni datos sensibles.
- **Contacto, reseña, disponibilidad y membresía**: áreas con acciones administrativas aprobadas en esta feature, sujetas a los contratos y permisos descritos en los requisitos.
- **Localidad**: dato relacionado de solo lectura; no tiene módulo ni mantenimiento administrativo en v1.
- **Pagos**: fuera de alcance de v1 porque no se identificó una fuente de verdad en el API.
- **Auditoría de moderación**: registro de la reseña afectada, actor `ADMIN`, acción de ocultar/restaurar, motivo y fecha; debe conservarse junto con el contenido original de la reseña.

## Success Criteria

### Measurable Outcomes

- **SC-001**: En pruebas de aceptación, el 100% de las solicitudes administrativas protegidas realizadas por una sesión sin autorización vigente terminan en denegación del servidor y no se presentan como exitosas.
- **SC-002**: Un administrador puede completar el recorrido de filtrar reportes y resolver uno, con resultado y estado final concordantes con la respuesta del servidor en todas las pruebas de aceptación.
- **SC-003**: Un administrador puede completar una unificación válida de categorías y recibe el resultado confirmado; una combinación inválida se rechaza sin mensaje de éxito en todas las pruebas de aceptación.
- **SC-004**: En pruebas de viewport amplio y compacto, todas las áreas y acciones incluidas en la cobertura administrativa aprobada siguen siendo accesibles y sus flujos principales pueden completarse sin controles inaccesibles por tamaño de pantalla.
- **SC-005**: Cada opción administrativa acordada tiene una correspondencia verificable en la matriz de trazabilidad entre interfaz, operación protegida del API, controller, modelo/DTO y pruebas; no quedan controles sin backend ni operaciones administrativas sin autorización documentada.
- **SC-006**: Las pruebas de estados de interfaz verifican por separado carga, vacío, ausencia de coincidencias, éxito confirmado y error para cada módulo operativo.
- **SC-007**: Las pruebas de accesibilidad verifican navegación por teclado, foco visible, nombres accesibles de controles y comprensión de estados con lector de pantalla en los flujos principales.
- **SC-008**: En las ocho pantallas administrativas cubiertas, la aceptación confirma que los filtros enviados coinciden con el contrato del API, que los filtros activos se pueden limpiar y que vacío y sin coincidencias se entienden como estados diferentes en anchos compactos y amplios.

## Assumptions

- El API vigente de `/Users/matybazan/Documents/api-tooapp` es la fuente autoritativa inspeccionada para determinar las capacidades actuales; una futura versión puede cambiar el inventario y deberá revisarse antes de planificar.
- La entrega completa incluye cambios coordinados en el repositorio del API, además de la consola. La especificación por sí sola no significa que los controllers, modelos o contratos faltantes ya estén desarrollados.
- En la primera versión, solo el personal con rol `ADMIN` accede a la consola y a sus operaciones; `SUPPORT` queda excluido aunque exista como rol en el modelo de datos. Un operador autorizado aprovisiona las cuentas `ADMIN` fuera de la consola; habilitar gestión de cuentas administrativas desde la consola requeriría una decisión posterior.
- El API cuenta con inicio, renovación y cierre de sesión, pero el ciclo completo de alta y soporte de cuentas administrativas aún requiere definición; no se asume SSO, MFA ni recuperación de contraseña.
- En ausencia de paginación confirmada, los listados administrativos descritos usan el conjunto que entregue el API; la consola no debe inventar paginación ni prometer escalabilidad de consulta.
- La app móvil sirve como evidencia de áreas, lenguaje de producto y campos mostrados a usuarios, no como evidencia de autorización administrativa.
- La identidad visual existente sirve como referencia; la adopción final de tokens, tipografía y composición para web debe validarse.
- No hay una definición confirmada de métricas globales, SLA, volumen de datos ni tiempos máximos de respuesta; no se agregan objetivos numéricos de rendimiento en esta especificación.
- Las áreas de la matriz forman parte del alcance administrativo acordado, pero las opciones exactas por área y sus permisos deben definirse antes de implementar. Las brechas de API detectadas son trabajo requerido del backend para alcanzar esa cobertura, no capacidades ya disponibles ni exclusiones permanentes.
