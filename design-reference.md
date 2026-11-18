# Guía visual para TÖÖ Administración

## Referencia observada

Usar [Kite Admin Dashboard](https://demo.dashboardpack.com/kite/) como referencia de composición para la consola TÖÖ. Se inspeccionaron en escritorio las pantallas Dashboard y Products. La demo muestra una navegación lateral agrupada, una barra superior compacta y, para Products, una barra local de búsqueda y filtros, acciones en contexto, tabla con filas separadas y paginación. No se inspeccionó su diseño compacto.

La demo contiene navegación y métricas de comercio electrónico que no pertenecen al producto TÖÖ. La referencia orienta la organización y densidad visual; no confirma datos, capacidades ni permisos de TooApp.

## Patrones que se adoptan

- Sidebar persistente con módulos agrupados, iconos outline consistentes e indicador claro de sección activa.
- Barra superior breve con el contexto de navegación y acciones ya disponibles. No agregar búsqueda global, notificaciones ni cambio de tema sin datos y comportamiento confirmados.
- Encabezados de página compactos con título, contexto y acción principal cuando el módulo la soporte.
- Barra local de listado que reúne búsqueda, filtros de contrato, limpiar filtros, actualizar y acciones principales aprobadas.
- Tablas administrativas con encabezado de bajo contraste, divisores finos, estados compactos y menú por fila; paginación cuando el API ya la ofrece.
- En listados con contenido extenso, como el cuerpo completo de un reporte, conservar una presentación que permita leerlo íntegramente.
- En anchos compactos, permitir desplazamiento horizontal de tablas para conservar todas las columnas y acciones.

## Aplicación en TÖÖ

- Conservar los tokens centralizados en `lib/src/core/theme/admin_theme.dart`: marca `#165D54`, fondo `#F5F7F6` y superficies claras. Los tonos de sidebar y resaltado se derivan del verde de marca; no se copia el azul oscuro, cian o naranja de Kite.
- Usar Flutter Material 3 y los Material Icons ya habilitados por `uses-material-design: true`; no añadir un paquete de iconos.
- Agrupar únicamente módulos administrativos confirmados. La sección activa debe distinguirse con fondo y contraste suficientes.
- Aplicar el patrón tabular a usuarios, prestadores, contactos, reseñas, categorías, membresías y disponibilidad. Conservar los campos, acciones, filtros y límites que actualmente respalda el API.
- Mantener los buscadores por módulo y filtros contextuales existentes. No inventar una búsqueda global, notificaciones, gráficas, conteos o acciones.
- No alterar contratos ni cambiar la API solo para reproducir el ejemplo. Una operación aparece en el dashboard únicamente cuando el contrato y los permisos vigentes la respaldan.
- Mantener etiquetas accesibles, foco visible, teclado y estados explícitos de carga, vacío, error, éxito y acceso denegado.

## Regla para acciones y datos

Una acción aparece en la consola solo cuando su ruta, DTO, validación y permiso `ADMIN` estén implementados en el API. Se usan las acciones reversibles aprobadas por la especificación; no se agrega borrado permanente. Ningún dato o acción de la demo se copia como dato de TÖÖ.
