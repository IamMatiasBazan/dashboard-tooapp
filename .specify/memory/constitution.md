<!--
Informe de impacto de sincronización
- Cambio de versión: plantilla sin versión → 1.0.0 (primera constitución del dashboard).
- Principios establecidos: cobertura administrativa; fidelidad al API; autorización;
  navegación; arquitectura; adaptabilidad y accesibilidad; identidad visual; operaciones
  responsables; resiliencia; pruebas y entrega.
- Secciones añadidas: capacidades verificadas y pendientes; restricciones tecnológicas;
  estructura de carpetas; flujo de desarrollo y gobierno.
- Secciones eliminadas: ninguna.
- Plantillas inspeccionadas: .specify/templates/plan-template.md, spec-template.md y
  tasks-template.md. No modificadas por el alcance explícito de cambiar únicamente esta
  constitución. Revisión de sincronización pendiente para una etapa autorizada posterior.
- Pendientes: confirmar ratificación original; definir autenticación y roles administrativos;
  acordar permisos por área; ampliar/confirmar contratos de API para operaciones admin;
  aprobar dependencias adicionales y validar decisiones visuales web.
-->
# Constitución de TÖÖ Admin Dashboard

## Core Principles

### I. Cobertura administrativa trazable
Cada especificación DEBE inventariar las áreas, entidades y datos presentes en el producto
móvil y definir, para cada una, qué acciones están permitidas a cada rol administrativo:
consultar, crear, editar, activar, desactivar, aprobar, rechazar o eliminar cuando
corresponda. No se DEBE inferir un permiso administrativo a partir de una pantalla, acción
o rol de la app móvil. Las áreas sin operación administrativa implementada DEBEN quedar
registradas como pendientes o limitaciones y no se DEBEN simular como funcionales.

### II. El contrato vigente del API determina las capacidades
El código y los contratos vigentes del API son la autoridad para los datos, campos,
estados, operaciones y permisos que el dashboard puede ofrecer. El cliente NO DEBE inventar
rutas, campos, reglas de negocio ni autorizaciones. Una operación deseada sin respaldo
vigente DEBE registrarse como dependencia, decisión pendiente o limitación antes de diseñar
su implementación. Los cambios requeridos al API necesitan su propio alcance y aprobación.

### III. Mínimo privilegio y autorización en servidor
Toda operación protegida DEBE exigir autenticación y autorización comprobadas por el
servidor para el rol correspondiente. Ocultar controles o restringir rutas únicamente en la
interfaz NO constituye autorización. El dashboard DEBE mostrar solo las acciones que el
contrato permita al rol autenticado y manejar de forma segura las respuestas de acceso
denegado. Tokens, secretos, datos personales y detalles internos de errores NO DEBEN quedar
expuestos en código, almacenamiento inseguro, registros visibles ni mensajes de interfaz.

### IV. Navegación administrativa basada en módulos reales
En layouts amplios, la consola DEBE ofrecer un drawer vertical persistente con acceso claro
a las áreas administrativas respaldadas por el producto. En pantallas compactas DEBE
adaptarse a un drawer lateral accesible u otro patrón equivalente que conserve las áreas y
respete los permisos. La navegación NO DEBE presentar como disponibles módulos ni tareas
que no estén confirmados; las capacidades pendientes no se representarán como acciones
operativas.

### V. Arquitectura por funcionalidad y responsabilidades
El código DEBE organizarse por funcionalidad y separar presentación, estado, acceso a datos
y modelos tipados. Widgets de interfaz NO DEBEN ejecutar solicitudes HTTP ni decodificar
respuestas sin tipo; los servicios de datos NO DEBEN contener widgets ni navegación. La
estructura de referencia es `lib/src/app/` para composición, rutas y layout; `lib/src/core/`
para configuración, red, sesión, tema, widgets compartidos y utilidades; y
`lib/src/features/<funcionalidad>/` con `data/`, `models/` y `presentation/` según aplique.
Las responsabilidades de drawer y diseño adaptable pertenecen a `app/layout/`. Las
funcionalidades concretas se determinarán en la especificación a partir de la inspección
del producto y del API; la propuesta de carpetas no confirma por sí misma que exista una
capacidad administrativa. Toda desviación estructural DEBE justificarse en la decisión
técnica correspondiente.

### VI. Desktop, móvil y accesibilidad son requisitos del producto
La consola DEBE funcionar en desktop y móvil y adaptar la composición al ancho disponible.
Los flujos DEBEN poder operarse con teclado, conservar foco visible, exponer nombres y
estados comprensibles a lectores de pantalla, mantener contraste suficiente y tolerar texto
ampliado. La adaptación NO DEBE quitar áreas ni permisos; puede cambiar su presentación.

### VII. Identidad visual verificada y tokens centralizados
El diseño DEBE conservar la identidad TÖÖ comprobable en las fuentes de referencia y
centralizar colores, tipografía, espaciado y demás tokens visuales aprobados. Los valores
observados en la app móvil son evidencia de referencia, no aprobación automática para el
dashboard web. Las propuestas visuales y los detalles aún no verificados DEBEN identificarse
como tales y aprobarse antes de tratarlos como estándar. Los estilos no DEBEN dispersar
valores visuales arbitrarios por las funcionalidades.

### VIII. Datos y acciones con resultado confirmado
Las vistas DEBEN comunicar estados de carga, vacío, éxito y error. Las entradas DEBEN
validarse antes de enviarse; las acciones de impacto significativo o irreversibles DEBEN
pedir confirmación. La interfaz DEBE informar el resultado confirmado por el servidor y NO
DEBE presentar datos, métricas, estados o cambios no confirmados como verdaderos.

### IX. Consultas eficientes y resiliencia
Las consultas DEBEN ajustarse a filtros, paginación y límites que realmente soporte el API;
el cliente NO DEBE asumir capacidades de consulta global que no existan. Los fallos de red,
respuestas inválidas y errores de autorización DEBEN manejarse sin exponer datos y sin
marcar una acción fallida como exitosa. No se impondrán SLA ni umbrales numéricos sin una
decisión respaldada por requisitos del producto.

### X. Verificación proporcional al riesgo
La estrategia de pruebas DEBE cubrir permisos, contratos y flujos de lectura y edición; las
acciones de impacto significativo requieren verificaciones acordes a su riesgo. El flujo de
entrega DEBE incluir análisis estático, formato y revisión de seguridad, además de pruebas
pertinentes. No se exigirán porcentajes de cobertura ni umbrales inventados. Las pruebas
DEBEN comprobar que errores del servidor y falta de autorización no se representen como
éxitos.

## Additional Constraints
### Database boundary (absolute)

El agente MUST NOT conectarse a ninguna base de datos, ni siquiera para consultas de solo lectura, ni ejecutar SQL, inspecciones de estado, seeds, resets, db push, migraciones o comandos equivalentes. El esquema y las migraciones solo pueden inspeccionarse o editarse como archivos locales; eso no autoriza ejecutarlos ni aplicarlos a una base de datos.


### Capacidades observadas y límites actuales
La app móvil de referencia presenta acceso/sesión y áreas de cliente y prestador, entre
ellas perfiles, búsqueda por categorías, disponibilidad, contactos, reseñas, métricas y
membresías. Estos elementos identifican datos y áreas que deben evaluarse en la futura
especificación administrativa; no implican que el personal administrador pueda verlos o
modificarlos.

En la API inspeccionada están confirmadas operaciones para roles `CLIENT` y `PROVIDER`,
incluidas consultas de categorías y prestadores, datos y actividad propios del prestador,
disponibilidad, portafolio, categorías secundarias, contactos, reseñas y niveles de
membresía. Las rutas protegidas aplican autenticación y autorización por esos roles, pero
no se encontró un rol `ADMIN` ni operaciones administrativas globales de consulta o gestión
de usuarios, prestadores, categorías, reseñas, pagos o membresías. La lista de capacidades
se debe revalidar contra el código y los contratos vigentes al especificar cada cambio.

Por lo tanto, el acceso administrativo integral, los permisos por rol administrativo y las
operaciones de administración global son capacidades incompletas o no disponibles en el
contrato inspeccionado. Su diseño y entrega dependen de decisiones de producto y cambios
del lado del servidor. La futura especificación DEBE distinguir esas brechas de las
capacidades confirmadas y enumerar decisiones pendientes sin afirmar que ya están resueltas.

### Restricciones tecnológicas y decisiones pendientes
El repositorio declara Flutter y Dart con restricción `^3.13.5`, además de
`flutter_lints: ^6.0.0`; la aplicación actual solo contiene el punto de entrada generado.
Estas son las dependencias confirmadas. `Provider`, `Dio`, paquetes de routing, autenticación
o componentes web NO están aprobados por este repositorio. Cualquier dependencia adicional
requiere una decisión técnica explícita y compatible con el `pubspec.yaml`; no se deben
inventar versiones ni asumir que las dependencias de la app móvil están disponibles aquí.

Quedan por decidir el mecanismo de autenticación administrativa, los roles y permisos, las
operaciones que debe exponer el API, la política de acceso a datos personales, y los tokens
visuales y dependencias para web. Estas decisiones no se completarán por inferencia.

## Development Workflow

La estructura inicial de referencia para implementar funcionalidades es:

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
        └── <funcionalidad_confirmada>/
            ├── data/
            ├── models/
            └── presentation/
```

Cada funcionalidad DEBE añadir solo las carpetas que utilice. La lista y los nombres de
módulos propuestos para el futuro (por ejemplo, usuarios, prestadores, servicios,
categorías, reseñas, membresías y pagos) son candidatos para investigar, no una declaración
de que haya pantallas, rutas o permisos administrativos disponibles. El plan DEBE comprobar
la estructura presente, el contrato vigente y las dependencias aprobadas antes de fijar
rutas de archivos o tecnología.

Antes de implementar, la especificación y el plan DEBEN verificar cobertura, permisos,
capacidades faltantes, decisiones pendientes, diseño adaptable, accesibilidad, manejo de
estados y estrategia de pruebas conforme a estos principios. Toda excepción DEBE documentar
el motivo, el riesgo y una alternativa considerada. Al cerrar el trabajo, la revisión DEBE
confirmar que la implementación respeta el contrato y que el servidor confirmó las
operaciones reportadas como exitosas.

## Governance

Esta constitución gobierna el desarrollo de TÖÖ Admin Dashboard y prevalece sobre prácticas
locales incompatibles. Toda enmienda requiere revisión del responsable del proyecto,
actualización de la versión y fecha, y un informe de impacto que indique principios y
artefactos afectados. Las plantillas Spec Kit y las guías de ejecución DEBEN sincronizarse
cuando la enmienda altere sus requisitos; esta primera actualización deja esa sincronización
pendiente para respetar el alcance solicitado de modificar solo la constitución.

El versionado es semántico: MAJOR para cambios incompatibles o redefiniciones de gobierno,
MINOR para principios o requisitos nuevos o ampliados sustancialmente y PATCH para
aclaraciones sin cambio de obligaciones. La fecha de ratificación original no se pudo
verificar y queda como `TODO(RATIFICATION_DATE)`; no se atribuye una fecha histórica. La
conformidad DEBE revisarse durante planificación y al completar cada funcionalidad, con
excepciones justificadas y trazables.

**Version**: 1.0.0 | **Ratified**: TODO(RATIFICATION_DATE): confirmar adopción original | **Last Amended**: 2026-10-30
