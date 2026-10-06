# Capstone: Análisis Exploratorio de Datos (EDA) en PostgreSQL — NovaSport

Proyecto final de la Diplomatura en Data Science (Coderhouse). Simula el trabajo de un analista de datos sobre **NovaSport**, una tienda online de indumentaria y accesorios deportivos: se modela, limpia y analiza la base de ventas para responder preguntas de negocio y presentar conclusiones accionables.

## 1. Problema de negocio

NovaSport vende online en 8 ciudades de Argentina, en 5 categorías (Calzado, Indumentaria, Accesorios, Fitness, Tecnología). El equipo comercial necesita responder:

1. ¿Quiénes son los clientes más valiosos y qué peso tienen sobre la facturación total?
2. ¿Cómo evolucionan las ventas mes a mes?
3. ¿Qué productos casi no rotan y podrían sacarse del catálogo o dejar de reponerse?
4. ¿Qué producto lidera cada categoría, para priorizar stock?
5. ¿Qué categoría conviene reforzar en cada ciudad?

Antes de responder, los datos de pedidos venían con problemas típicos de un sistema de carga real (POS): **precios unitarios y fechas de pedido faltantes**, y **productos sin precio de lista cargado**. El análisis empieza resolviendo eso.

## 2. Estructura del repositorio

| Archivo | Contenido |
|---|---|
| `estructura.sql` | Creación de las tablas `clientes`, `productos`, `pedidos` (con tipos `DATE` y `NUMERIC` correctos) y carga de datos de ejemplo, incluyendo registros con nulos a propósito para poder demostrar la limpieza. |
| `analisis.sql` | Parte 1: verificación de tipos, detección de nulos, vista `pedidos_limpios` con `COALESCE`, verificación final de la limpieza y chequeo de integridad de los JOINs. Parte 2: 7 consultas de negocio comentadas (GROUP BY, JOIN, CASE, RANK() y funciones de ventana). |
| `README.md` | Este archivo. |

## 3. Cómo ejecutar

Requisitos: PostgreSQL (probado en la versión 16) y `psql`, o pgAdmin.

```sql
-- 1. Crear la base y conectarse
CREATE DATABASE capstone_project;
\c capstone_project

-- 2. Crear tablas y cargar datos
\i estructura.sql

-- 3. Correr la limpieza y las consultas de análisis
\i analisis.sql
```

También se puede correr desde la terminal:

```bash
psql -U <usuario> -c "CREATE DATABASE capstone_project;"
psql -U <usuario> -d capstone_project -f estructura.sql
psql -U <usuario> -d capstone_project -f analisis.sql
```

Ambos scripts fueron probados de punta a punta contra una instancia real de PostgreSQL, ejecutándolos dos veces seguidas: corren sin errores y son re-ejecutables (`estructura.sql` empieza eliminando la vista `pedidos_limpios` y las tablas con `DROP ... IF EXISTS`, en el orden que exigen sus dependencias).

## 4. Limpieza de datos (resumen)

Sobre 160 pedidos y 20 productos cargados:

- **5 pedidos** llegaron sin `precio_unitario`. Se intentó resolverlos con `COALESCE(precio_unitario, precio_de_lista_del_producto, 0)` en la vista `pedidos_limpios`, pero en los 5 casos el producto tampoco tenía precio de lista, así que el precio quedó en **0**. Esos ceros representan **importes desconocidos**, no ventas gratis: la facturación calculada puede estar **subestimada**. Quedan identificables en la vista (`precio_unitario = 0`) y se verifican en la consulta 1.4 de `analisis.sql`.
- **2 productos** no tenían precio de lista cargado (`Zapatillas Urbanas` y `Guantes de Arquero`), lo cual explica los 5 precios faltantes en pedidos. Se marca como hallazgo operativo: hay que completar esos precios en el catálogo.
- **3 pedidos** llegaron sin `fecha_pedido`. No se les "inventó" una fecha (hubiera sesgado el análisis mensual): se excluyeron puntualmente del reporte de ventas por mes, pero sí se cuentan en el gasto total por cliente (el pedido existió, no depende de la fecha).
- Se verificó que el JOIN `pedidos → clientes` no infla filas (160 antes y después del JOIN), confirmando que la relación 1‑a‑muchos está bien modelada.
- Verificación final sobre la vista `pedidos_limpios`: 0 precios nulos, 0 cantidades nulas, 3 fechas nulas (marcadas a propósito) y 5 pedidos con precio 0 (importes desconocidos).

## 5. Hallazgos principales

**Concentración de clientes.** El cliente top (Martina Gómez, Buenos Aires) generó **$803.987** en 11 pedidos, un 9,6% de toda la facturación histórica ella sola. El segmento "VIP" (gasto ≥ $300.000) son solo 10 de los 30 clientes, pero concentran algo más de la mitad (51%) de las ventas totales. Conclusión: conviene armar un programa de fidelización para ese 33% de la base antes que una campaña masiva pareja para todos.

**Tendencia de ventas.** Entre enero ($419.986) y julio ($1.521.963) las ventas mensuales muestran una tendencia general de crecimiento, con fluctuaciones: hubo caídas en abril (frente a marzo) y en junio (frente a mayo). Agosto ($1.335.974) queda por debajo de julio, pero el dataset corta el 23 de agosto: es un mes incompleto y no se puede leer como una caída real. Con solo 8 meses de datos no alcanza para confirmar estacionalidad; haría falta al menos 12 a 24 meses para distinguir un patrón estacional de una tendencia o de efectos puntuales como campañas o promociones.

**Productos que casi no rotan.** Los 3 productos con menos unidades vendidas fueron `Guantes de Arquero` (2 unidades), `Zapatillas Urbanas` (3) y `Buzo Canguro` (3). Es una señal de alerta doble: dos de esos tres productos son justamente los que no tenían precio de lista cargado, lo que sugiere que el problema de datos y el problema comercial están conectados (un producto sin precio visible probablemente tampoco se está mostrando bien en la tienda).

**Líderes por categoría.** `Remera Dry-Fit` es el producto más vendido de todo el catálogo (32 unidades) y también líder de Indumentaria. En Tecnología hay un empate en el primer puesto entre `Reloj Deportivo GPS` y `Auriculares Inalámbricos Sport` (10 unidades cada uno) — con `RANK()` ambos quedan correctamente en el puesto #1, en vez de ordenarse arbitrariamente como haría `ROW_NUMBER()`. A nivel de pedidos individuales, el de mayor monto de todo el dataset es de Calzado: $179.998 (Martina Gómez, 2 pares de `Zapatillas Running Pro`, julio).

**Preferencias por ciudad.** En 3 de las 8 ciudades, Calzado no es la categoría líder: en Buenos Aires y La Plata gana Tecnología ($1.039.992 y $289.997 respectivamente), y en Salta gana Indumentaria ($171.993). En las 5 ciudades restantes, Calzado domina cómodo. No es un caso aislado de Buenos Aires: es una minoría consistente que vale la pena investigar (quizás competencia más fuerte en calzado físico en esas 3 ciudades, o perfiles de cliente distintos) antes de asumir un catálogo destacado único a nivel nacional.

## 6. Próximos pasos sugeridos

- Completar el precio de lista de los productos que lo tienen en `NULL`, para no seguir generando pedidos con precio 0 (importe desconocido) y subestimando la facturación.
- Investigar por qué ciertos pedidos llegan sin `fecha_pedido` (falla puntual del POS o de una integración) antes de que crezca el volumen.
- Extender el análisis a más meses (idealmente 12 a 24) para confirmar si existe estacionalidad o si el pico de julio fue un efecto de campaña puntual.
