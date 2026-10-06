-- =====================================================================
-- ANALISIS.SQL
-- Proyecto Capstone: Análisis Exploratorio de Datos (EDA) en PostgreSQL
-- Negocio simulado: "NovaSport" - tienda online de indumentaria deportiva
-- Autor: David Toloza
--
-- Estructura de este archivo:
--   PARTE 1: Verificación y limpieza de datos
--   PARTE 2: Preguntas de negocio (análisis)
-- =====================================================================


-- =====================================================================
-- PARTE 1: VERIFICACIÓN Y LIMPIEZA DE DATOS
-- =====================================================================

-- 1.1 Verificamos que los tipos de datos sean los correctos.
-- Por qué: si fecha_pedido o precio_unitario hubiesen quedado como TEXT
-- (típico cuando los datos vienen de un CSV mal tipado), no podríamos
-- hacer aritmética ni funciones de fecha más adelante sin castear.
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name IN ('clientes', 'productos', 'pedidos')
ORDER BY table_name, ordinal_position;
-- Resultado esperado: fecha_alta y fecha_pedido en DATE, precio y
-- precio_unitario en NUMERIC(10,2). Si esto viniera como VARCHAR habría
-- que aplicar: ALTER TABLE ... ALTER COLUMN ... TYPE DATE USING columna::DATE

-- 1.2 Detectamos nulos en columnas críticas (precio, fecha, cantidad).
-- Por qué: antes de sumar ingresos o agrupar por mes necesitamos saber
-- cuántas filas se verían afectadas por datos faltantes, para decidir
-- si las excluimos, las imputamos o las dejamos en 0 según el caso.
SELECT
    COUNT(*) FILTER (WHERE precio_unitario IS NULL) AS pedidos_sin_precio,
    COUNT(*) FILTER (WHERE fecha_pedido IS NULL)    AS pedidos_sin_fecha,
    COUNT(*) FILTER (WHERE cantidad IS NULL)        AS pedidos_sin_cantidad
FROM pedidos;

SELECT COUNT(*) AS productos_sin_precio_de_lista
FROM productos
WHERE precio IS NULL;

-- 1.3 Vista de limpieza: "pedidos_limpios".
-- Por qué CREATE VIEW y no UPDATE: preferimos no pisar los datos
-- originales (auditar es más fácil si el dato crudo sigue disponible).
-- La vista resuelve los nulos así:
--   * precio_unitario NULL -> se completa con el precio de lista vigente
--     del producto (COALESCE). Si tampoco hay precio de lista, queda en 0
--     para no romper las sumas y poder detectarlo fácil (precio_unitario = 0).
--   * fecha_pedido NULL -> no se puede "inventar" una fecha sin sesgar el
--     análisis temporal, así que esas filas quedan marcadas y se excluyen
--     puntualmente de los reportes por mes (no del análisis en general).
CREATE OR REPLACE VIEW pedidos_limpios AS
SELECT
    p.pedido_id,
    p.cliente_id,
    p.producto_id,
    p.cantidad,
    COALESCE(p.precio_unitario, pr.precio, 0)      AS precio_unitario,
    p.fecha_pedido,
    (p.fecha_pedido IS NULL)                       AS fecha_faltante,
    (p.precio_unitario IS NULL)                    AS precio_imputado
FROM pedidos p
LEFT JOIN productos pr ON pr.producto_id = p.producto_id;

-- Chequeo rápido de cuántas filas quedaron con precio imputado o fecha
-- faltante, para dejar constancia en el README de qué se tocó.
SELECT
    COUNT(*) FILTER (WHERE precio_imputado) AS filas_con_precio_imputado,
    COUNT(*) FILTER (WHERE fecha_faltante)  AS filas_con_fecha_faltante
FROM pedidos_limpios;

-- 1.4 Verificación final de la limpieza (cierre del ciclo).
-- Por qué: después de limpiar hay que demostrar qué quedó resuelto y qué
-- no. Esperado: 0 precios nulos y 0 cantidades nulas (COALESCE los resolvió),
-- 3 fechas nulas (se dejan marcadas a propósito: inventar una fecha sesgaría
-- el análisis mensual) y 5 pedidos con precio 0.
-- OJO: esos 5 ceros NO son ventas gratis, son importes DESCONOCIDOS (ni el
-- pedido ni el producto tenían precio cargado). Por eso la facturación que
-- calculamos más abajo puede estar SUBESTIMADA.
SELECT
    COUNT(*) FILTER (WHERE precio_unitario IS NULL)  AS precios_nulos,
    COUNT(*) FILTER (WHERE cantidad IS NULL)         AS cantidades_nulas,
    COUNT(*) FILTER (WHERE fecha_pedido IS NULL)     AS fechas_nulas,
    COUNT(*) FILTER (WHERE precio_unitario = 0)      AS pedidos_con_precio_cero
FROM pedidos_limpios;

-- 1.5 Verificación de la relación clientes-pedidos (evitar "explosión de
-- filas" en los JOINs). Por qué: pedidos.cliente_id y pedidos.producto_id
-- son foreign keys de tablas con cliente_id/producto_id como PK, es decir
-- la relación es 1-a-muchos en ambos casos, así que un INNER JOIN entre
-- pedidos y clientes (o productos) no debería multiplicar filas. Lo
-- confirmamos comparando el conteo antes y después del JOIN.
SELECT
    (SELECT COUNT(*) FROM pedidos) AS filas_antes_del_join,
    (SELECT COUNT(*)
     FROM pedidos p
     JOIN clientes c ON c.cliente_id = p.cliente_id) AS filas_despues_del_join;
-- Si estos dos números difirieran, sería señal de una relación mal
-- modelada (por ejemplo, cliente_id duplicado como PK).


-- =====================================================================
-- PARTE 2: PREGUNTAS DE NEGOCIO
-- =====================================================================

-- -----------------------------------------------------------------
-- Pregunta 1: Top 5 clientes por gasto total
-- Por qué NO filtramos por fecha_faltante acá (a diferencia de la
-- Pregunta 2): un pedido sin fecha igual representa una compra real
-- que el cliente pagó, así que lo incluimos en su gasto histórico.
-- La fecha solo es indispensable cuando agrupamos por mes (Pregunta 2);
-- para el gasto total por cliente, no excluirla es la decisión correcta.
-- -----------------------------------------------------------------
SELECT
    c.cliente_id,
    c.nombre,
    c.ciudad,
    COUNT(pl.pedido_id)                         AS cantidad_pedidos,
    SUM(pl.cantidad * pl.precio_unitario)       AS gasto_total
FROM pedidos_limpios pl
JOIN clientes c ON c.cliente_id = pl.cliente_id
GROUP BY c.cliente_id, c.nombre, c.ciudad
ORDER BY gasto_total DESC
LIMIT 5;

-- -----------------------------------------------------------------
-- Pregunta 2: Ventas totales por mes
-- Por qué excluimos fecha_faltante = true acá: no podemos asignar esos
-- pedidos a ningún mes sin inventar un dato, y mezclarlos rompería la
-- serie temporal (mejor reportarlos aparte, como en el chequeo 1.3).
-- Usamos DATE_TRUNC para agrupar por mes calendario real (no por texto).
-- -----------------------------------------------------------------
SELECT
    DATE_TRUNC('month', fecha_pedido)::DATE     AS mes,
    COUNT(*)                                    AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)             AS ventas_totales
FROM pedidos_limpios
WHERE fecha_faltante = false
GROUP BY DATE_TRUNC('month', fecha_pedido)
ORDER BY mes;

-- -----------------------------------------------------------------
-- Pregunta 3: 3 productos menos vendidos (por unidades)
-- Por qué LEFT JOIN y no INNER: si algún producto no tuviera ningún
-- pedido asociado, queremos que igual aparezca con 0 unidades vendidas
-- en vez de desaparecer del reporte (sería justamente el caso más
-- interesante para el negocio: productos que nunca se vendieron).
-- -----------------------------------------------------------------
SELECT
    pr.producto_id,
    pr.nombre_producto,
    pr.categoria,
    COALESCE(SUM(pl.cantidad), 0) AS unidades_vendidas
FROM productos pr
LEFT JOIN pedidos_limpios pl ON pl.producto_id = pr.producto_id
GROUP BY pr.producto_id, pr.nombre_producto, pr.categoria
ORDER BY unidades_vendidas ASC
LIMIT 3;

-- -----------------------------------------------------------------
-- Pregunta 4: Ranking de productos por ventas dentro de cada categoría
-- (Window Function RANK())
-- Por qué RANK() y no ROW_NUMBER(): si dos productos empatan en
-- unidades vendidas dentro de la misma categoría, queremos que
-- compartan el mismo puesto (RANK() deja el siguiente número salteado),
-- que es lo que un gerente de categoría esperaría ver.
-- -----------------------------------------------------------------
SELECT
    categoria,
    nombre_producto,
    unidades_vendidas,
    RANK() OVER (
        PARTITION BY categoria
        ORDER BY unidades_vendidas DESC
    ) AS ranking_en_categoria
FROM (
    SELECT
        pr.categoria,
        pr.nombre_producto,
        COALESCE(SUM(pl.cantidad), 0) AS unidades_vendidas
    FROM productos pr
    LEFT JOIN pedidos_limpios pl ON pl.producto_id = pr.producto_id
    GROUP BY pr.categoria, pr.nombre_producto
) ventas_por_producto
ORDER BY categoria, ranking_en_categoria;

-- -----------------------------------------------------------------
-- Pregunta 5 (extra): Segmentación de clientes por gasto (CASE +
-- Window Function), para identificar el "perfil del cliente más leal"
-- que menciona la guía del capstone.
-- Por qué CASE acá: el negocio no piensa en "gasto_total = 123456",
-- piensa en segmentos accionables (a quién le mando una promo VIP).
-- Por qué la CTE con SUM() OVER(): para poder calcular qué porcentaje
-- del gasto total de la tienda representa cada cliente, sin tener que
-- correr una segunda consulta agregada aparte.
-- -----------------------------------------------------------------
WITH gasto_por_cliente AS (
    SELECT
        c.cliente_id,
        c.nombre,
        SUM(pl.cantidad * pl.precio_unitario) AS gasto_total
    FROM pedidos_limpios pl
    JOIN clientes c ON c.cliente_id = pl.cliente_id
    GROUP BY c.cliente_id, c.nombre
)
SELECT
    cliente_id,
    nombre,
    gasto_total,
    ROUND(
        100.0 * gasto_total / SUM(gasto_total) OVER (), 2
    ) AS pct_del_total_de_ventas,
    CASE
        WHEN gasto_total >= 300000 THEN 'VIP'
        WHEN gasto_total >= 150000 THEN 'Frecuente'
        ELSE 'Ocasional'
    END AS segmento
FROM gasto_por_cliente
ORDER BY gasto_total DESC;

-- -----------------------------------------------------------------
-- Pregunta 6 (extra): ¿Qué categoría genera más ingresos por ciudad?
-- Combina JOIN de las 3 tablas + GROUP BY, para mostrar una pregunta de
-- negocio geográfica (en qué ciudad conviene reforzar stock de qué
-- categoría).
-- -----------------------------------------------------------------
SELECT
    c.ciudad,
    pr.categoria,
    SUM(pl.cantidad * pl.precio_unitario) AS ingresos
FROM pedidos_limpios pl
JOIN clientes c   ON c.cliente_id  = pl.cliente_id
JOIN productos pr ON pr.producto_id = pl.producto_id
GROUP BY c.ciudad, pr.categoria
ORDER BY c.ciudad, ingresos DESC;

-- -----------------------------------------------------------------
-- Pregunta 7 (extra): Top 3 pedidos de mayor monto dentro de cada
-- categoría, con RANK() sobre pedidos individuales (distinto de la
-- Pregunta 4, que rankea productos por unidades vendidas).
-- Por qué el desempate (fecha_pedido, pedido_id): hay muchos pedidos
-- con el mismo monto (por ejemplo, 10 pedidos de $149.999 en Tecnología).
-- Sin desempate, el top 3 devolvería 42 filas por los empates; con él,
-- queda un ranking acotado y reproducible. Los pedidos sin fecha van
-- últimos en el desempate (NULLS LAST) en lugar de inventarles una fecha.
-- -----------------------------------------------------------------

WITH pedidos_con_monto AS (
    SELECT
        pr.categoria,
        pl.pedido_id,
        c.nombre AS cliente,
        pl.fecha_pedido,
        pl.cantidad * pl.precio_unitario AS monto_pedido
    FROM pedidos_limpios pl
    JOIN productos pr ON pr.producto_id = pl.producto_id
    JOIN clientes c   ON c.cliente_id   = pl.cliente_id
),
ranking AS (
    SELECT
        categoria, pedido_id, cliente, fecha_pedido, monto_pedido,
        RANK() OVER (
            PARTITION BY categoria
            ORDER BY monto_pedido DESC, fecha_pedido ASC NULLS LAST, pedido_id
        ) AS ranking_pedido_en_categoria
    FROM pedidos_con_monto
)
SELECT *
FROM ranking
WHERE ranking_pedido_en_categoria <= 3
ORDER BY categoria, ranking_pedido_en_categoria;

