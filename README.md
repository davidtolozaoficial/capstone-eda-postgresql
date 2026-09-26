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
| `analisis.sql` | Parte 1: verificación de tipos, detección de nulos, vista `pedidos_limpios` con `COALESCE` y chequeo de integridad de los JOINs. Parte 2: 6 consultas de negocio comentadas (GROUP BY, JOIN, CASE, RANK() y funciones de ventana). |
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

Ambos scripts fueron probados de punta a punta contra una instancia real de PostgreSQL 16 antes de subirse: corren sin errores de sintaxis y son re-ejecutables (`estructura.sql` empieza con `DROP TABLE IF EXISTS`).

## 4. Limpieza de datos (resumen)

Sobre 160 pedidos y 20 productos cargados:

- **5 pedidos** llegaron sin `precio_unitario`. Se resolvieron con `COALESCE(precio_unitario, precio_de_lista_del_producto, 0)` en la vista `pedidos_limpios`, para no perder esas filas en las sumas de facturación.
- **2 productos** no tenían precio de lista cargado (`Zapatillas Urbanas` y `Guantes de Arquero`), lo cual es justamente el origen de parte de los precios faltantes en pedidos. Se marca como hallazgo operativo: hay que completar esos precios en el catálogo.
- **3 pedidos** llegaron sin `fecha_pedido`. No se les "inventó" una fecha (hubiera sesgado el análisis mensual): se excluyeron puntualmente del reporte de ventas por mes, pero sí se cuentan en el gasto total por cliente (el pedido existió, no depende de la fecha).
- Se verificó que el JOIN `pedidos → clientes` no infla filas (160 antes y después del JOIN), confirmando que la relación 1‑a‑muchos está bien modelada.

## 5. Hallazgos principales

**Concentración de clientes.** El cliente top (Martina Gómez, Buenos Aires) generó **$803.987** en 11 pedidos, un 9,6% de toda la facturación histórica ella sola. El segmento "VIP" (gasto ≥ $300.000) son solo 10 de los 30 clientes, pero concentran cerca de la mitad de las ventas totales. Conclusión: conviene armar un programa de fidelización para ese 33% de la base antes que una campaña masiva pareja para todos.

**Estacionalidad creciente.** Las ventas mensuales subieron de forma sostenida de enero ($419.986) a julio ($1.521.963), un crecimiento de +262%. Agosto cierra por debajo de julio ($1.335.974), pero el dataset corta el 23 de agosto, es decir, es un mes incompleto — no se puede leer como una caída real sin más datos del resto del mes.

**Productos que casi no rotan.** Los 3 productos con menos unidades vendidas fueron `Guantes de Arquero` (2 unidades), `Zapatillas Urbanas` (3) y `Buzo Canguro` (3). Es una señal de alerta doble: dos de esos tres productos son justamente los que no tenían precio de lista cargado, lo que sugiere que el problema de datos y el problema comercial están conectados (un producto sin precio visible probablemente tampoco se está mostrando bien en la tienda).

**Líderes por categoría.** `Remera Dry-Fit` es el producto más vendido de todo el catálogo (32 unidades) y también líder de Indumentaria. En Tecnología hay un empate en el primer puesto entre `Reloj Deportivo GPS` y `Auriculares Inalámbricos Sport` (10 unidades cada uno) — con `RANK()` ambos quedan correctamente en el puesto #1, en vez de ordenarse arbitrariamente como haría `ROW_NUMBER()`.

**Preferencias por ciudad.** En 3 de las 8 ciudades, Calzado no es la categoría líder: en Buenos Aires y La Plata gana Tecnología ($1.039.992 y $289.997 respectivamente), y en Salta gana Indumentaria ($171.993). En las 5 ciudades restantes, Calzado domina cómodo. No es un caso aislado de Buenos Aires: es una minoría consistente que vale la pena investigar (quizás competencia más fuerte en calzado físico en esas 3 ciudades, o perfiles de cliente distintos) antes de asumir un catálogo destacado único a nivel nacional.

## 6. Próximos pasos sugeridos

- Completar el precio de lista de los productos que lo tienen en `NULL`, para no seguir generando pedidos con precio imputado en 0.
- Investigar por qué ciertos pedidos llegan sin `fecha_pedido` (falla puntual del POS o de una integración) antes de que crezca el volumen.
- Extender el análisis con datos de más de 8 meses para confirmar si la estacionalidad de julio es un pico real o un efecto de campaña puntual.
