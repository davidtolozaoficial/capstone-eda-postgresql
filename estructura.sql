-- =====================================================================
-- ESTRUCTURA.SQL
-- Proyecto Capstone: Análisis Exploratorio de Datos (EDA) en PostgreSQL
-- Negocio simulado: "NovaSport" - tienda online de indumentaria deportiva
-- Autor: David Toloza
-- =====================================================================
-- Este script:
--   1) Crea las tablas clientes, productos y pedidos.
--   2) Carga datos de ejemplo, incluyendo registros "sucios" a propósito
--      (pedidos sin precio o sin fecha, y productos sin precio de lista)
--      para poder demostrar una limpieza real en analisis.sql, tal como
--      pide la consigna.
--
-- Cómo ejecutar:
--   1. Crear la base:      CREATE DATABASE capstone_project;
--   2. Conectarse:         \c capstone_project
--   3. Correr este script: \i estructura.sql
-- =====================================================================

-- Paso 1: Configuración de la base de datos.
-- (Se deja comentado porque normalmente se corre una sola vez, fuera de una
--  transacción, y antes de conectarse a la base recién creada)
-- CREATE DATABASE capstone_project;
-- \c capstone_project

-- Reseteo para poder re-ejecutar el script sin errores.
-- Primero se elimina la vista pedidos_limpios (se crea en analisis.sql)
-- porque depende de pedidos y productos: si existe, Postgres no deja
-- borrar esas tablas y el script falla por la dependencia.
DROP VIEW IF EXISTS pedidos_limpios;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;

-- ---------------------------------------------------------------------
-- Tabla: clientes
-- ---------------------------------------------------------------------
CREATE TABLE clientes (
    cliente_id      SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    email           VARCHAR(150),
    ciudad          VARCHAR(60),
    fecha_alta      DATE            -- puede venir NULL: cliente cargado sin fecha de alta
);

-- ---------------------------------------------------------------------
-- Tabla: productos
-- ---------------------------------------------------------------------
CREATE TABLE productos (
    producto_id     SERIAL PRIMARY KEY,
    nombre_producto VARCHAR(120) NOT NULL,
    categoria       VARCHAR(60) NOT NULL,
    precio          NUMERIC(10,2)   -- puede venir NULL: producto cargado sin precio de lista
);

-- ---------------------------------------------------------------------
-- Tabla: pedidos
-- Un pedido = un cliente que compra un producto en una fecha, con una
-- cantidad y un precio unitario (el precio unitario se guarda "congelado"
-- al momento de la venta, como en un sistema real de facturación).
-- ---------------------------------------------------------------------
CREATE TABLE pedidos (
    pedido_id       SERIAL PRIMARY KEY,
    cliente_id      INTEGER REFERENCES clientes(cliente_id),
    producto_id     INTEGER REFERENCES productos(producto_id),
    cantidad        INTEGER NOT NULL,
    precio_unitario NUMERIC(10,2),  -- puede venir NULL: falla de carga desde el POS
    fecha_pedido    DATE            -- puede venir NULL: falla de carga desde el POS
);

-- =====================================================================
-- CARGA DE CLIENTES (30 clientes, algunos con datos incompletos)
-- =====================================================================
INSERT INTO clientes (nombre, email, ciudad, fecha_alta) VALUES
('Martina Gómez',        'martina.gomez@mail.com',   'Buenos Aires',  '2024-01-15'),
('Lucas Fernández',      'lucas.fernandez@mail.com', 'Córdoba',       '2024-01-22'),
('Sofía Ramírez',        'sofia.ramirez@mail.com',   'Rosario',       '2024-02-03'),
('Mateo Sosa',           'mateo.sosa@mail.com',      'Mendoza',       '2024-02-10'),
('Valentina Torres',     'valentina.torres@mail.com','Buenos Aires',  NULL),
('Benjamín Díaz',        'benjamin.diaz@mail.com',   'La Plata',      '2024-02-28'),
('Camila Herrera',       'camila.herrera@mail.com',  'Córdoba',       '2024-03-05'),
('Joaquín Molina',       'joaquin.molina@mail.com',  'Rosario',       '2024-03-09'),
('Isabella Acosta',      'isabella.acosta@mail.com', 'Mar del Plata', '2024-03-14'),
('Santiago Rojas',       'santiago.rojas@mail.com',  'Buenos Aires',  '2024-03-20'),
('Emma Castro',          'emma.castro@mail.com',     'Salta',         '2024-03-25'),
('Thiago Ortiz',         'thiago.ortiz@mail.com',    'Córdoba',       NULL),
('Mía Silva',            'mia.silva@mail.com',       'Tucumán',       '2024-04-02'),
('Bautista Núñez',       'bautista.nunez@mail.com',  'Buenos Aires',  '2024-04-08'),
('Catalina Ibáñez',      'catalina.ibanez@mail.com', 'Rosario',       '2024-04-15'),
('Agustín Medina',       'agustin.medina@mail.com',  'Mendoza',       '2024-04-19'),
('Renata Vega',          'renata.vega@mail.com',     'La Plata',      '2024-04-27'),
('Francisco Aguirre',    'francisco.aguirre@mail.com','Córdoba',      '2024-05-03'),
('Olivia Peralta',       'olivia.peralta@mail.com',  'Buenos Aires',  '2024-05-11'),
('Ignacio Flores',       'ignacio.flores@mail.com',  'Salta',         '2024-05-18'),
('Julieta Cabrera',      'julieta.cabrera@mail.com', 'Rosario',       NULL),
('Dante Morales',        'dante.morales@mail.com',   'Mar del Plata', '2024-05-30'),
('Pilar Vargas',         'pilar.vargas@mail.com',    'Buenos Aires',  '2024-06-04'),
('Simón Godoy',          'simon.godoy@mail.com',     'Tucumán',       '2024-06-09'),
('Delfina Paz',          'delfina.paz@mail.com',     'Córdoba',       '2024-06-15'),
('Tomás Villalba',       'tomas.villalba@mail.com',  'Buenos Aires',  '2024-06-21'),
('Guadalupe Correa',     'guadalupe.correa@mail.com','Rosario',       '2024-06-28'),
('Máximo Juárez',        'maximo.juarez@mail.com',   'Mendoza',       '2024-07-02'),
('Antonella Luna',       'antonella.luna@mail.com',  'La Plata',      '2024-07-08'),
('Nicolás Ponce',        'nicolas.ponce@mail.com',   'Buenos Aires',  '2024-07-14');

-- =====================================================================
-- CARGA DE PRODUCTOS (20 productos en 5 categorías, algunos sin precio)
-- =====================================================================
INSERT INTO productos (nombre_producto, categoria, precio) VALUES
('Zapatillas Running Pro',        'Calzado',       89999.00),
('Zapatillas Training Flex',      'Calzado',       74999.00),
('Botines Fútbol Turf',           'Calzado',       64999.00),
('Ojotas Deportivas',             'Calzado',       14999.00),
('Zapatillas Urbanas',            'Calzado',       NULL),        -- sin precio cargado
('Remera Dry-Fit',                'Indumentaria',  19999.00),
('Short Training',                'Indumentaria',  16999.00),
('Campera Rompeviento',           'Indumentaria',  45999.00),
('Calza Deportiva',               'Indumentaria',  22999.00),
('Buzo Canguro',                  'Indumentaria',  38999.00),
('Pelota de Fútbol N°5',          'Accesorios',    24999.00),
('Mochila Deportiva',             'Accesorios',    29999.00),
('Botella Térmica 1L',            'Accesorios',    12999.00),
('Guantes de Arquero',            'Accesorios',    NULL),        -- sin precio cargado
('Gorra Deportiva',               'Accesorios',    9999.00),
('Set Mancuernas 10kg',           'Fitness',       54999.00),
('Colchoneta Yoga',               'Fitness',       17999.00),
('Banda Elástica x3',             'Fitness',       8999.00),
('Reloj Deportivo GPS',           'Tecnología',    149999.00),
('Auriculares Inalámbricos Sport','Tecnología',    69999.00);

-- =====================================================================
-- CARGA DE PEDIDOS (160 pedidos, de enero al 23 de agosto de 2024;
-- agosto es un mes incompleto)
-- Incluye adrede: precio_unitario NULL, fecha_pedido NULL y cantidades
-- variadas para poder demostrar limpieza y agregaciones reales.
-- =====================================================================
INSERT INTO pedidos (cliente_id, producto_id, cantidad, precio_unitario, fecha_pedido) VALUES
(1, 1, 1, 89999.00, '2024-01-16'),
(2, 6, 2, 19999.00, '2024-01-18'),
(3, 11, 1, 24999.00, '2024-01-20'),
(1, 9, 1, 22999.00, '2024-01-25'),
(4, 3, 1, 64999.00, '2024-01-28'),
(5, 16, 1, 54999.00, '2024-02-01'),
(2, 2, 1, 74999.00, '2024-02-03'),
(6, 19, 1, 149999.00, '2024-02-05'),
(7, 6, 3, 19999.00, '2024-02-07'),
(3, 15, 2, 9999.00, '2024-02-09'),
(8, 1, 1, 89999.00, NULL),                 -- fecha sin cargar (falla de POS)
(9, 8, 1, 45999.00, '2024-02-14'),
(10, 20, 1, 69999.00, '2024-02-16'),
(1, 5, 1, NULL, '2024-02-18'),              -- precio sin cargar (el producto no tenía precio de lista)
(11, 12, 1, 29999.00, '2024-02-20'),
(4, 7, 2, 16999.00, '2024-02-22'),
(12, 1, 1, 89999.00, '2024-02-24'),
(13, 14, 1, NULL, '2024-02-26'),            -- precio sin cargar
(6, 6, 1, 19999.00, '2024-02-28'),
(14, 17, 1, 17999.00, '2024-03-01'),
(2, 11, 2, 24999.00, '2024-03-03'),
(15, 3, 1, 64999.00, '2024-03-05'),
(7, 9, 1, 22999.00, '2024-03-07'),
(16, 19, 1, 149999.00, '2024-03-09'),
(3, 6, 1, 19999.00, '2024-03-11'),
(17, 2, 1, 74999.00, '2024-03-13'),
(8, 13, 1, 12999.00, '2024-03-15'),
(18, 1, 1, 89999.00, '2024-03-17'),
(9, 20, 1, 69999.00, '2024-03-19'),
(19, 8, 1, 45999.00, '2024-03-21'),
(4, 15, 3, 9999.00, '2024-03-23'),
(20, 6, 2, 19999.00, '2024-03-25'),
(10, 12, 1, 29999.00, '2024-03-27'),
(21, 3, 1, 64999.00, '2024-03-29'),
(5, 1, 1, 89999.00, '2024-03-31'),
(22, 18, 2, 8999.00, '2024-04-02'),
(11, 9, 1, 22999.00, '2024-04-04'),
(23, 19, 1, 149999.00, '2024-04-06'),
(6, 6, 1, 19999.00, '2024-04-08'),
(24, 2, 1, 74999.00, NULL),                 -- fecha sin cargar
(12, 11, 2, 24999.00, '2024-04-12'),
(25, 7, 1, 16999.00, '2024-04-14'),
(13, 1, 1, 89999.00, '2024-04-16'),
(7, 20, 1, 69999.00, '2024-04-18'),
(26, 8, 1, 45999.00, '2024-04-20'),
(14, 15, 1, 9999.00, '2024-04-22'),
(27, 6, 3, 19999.00, '2024-04-24'),
(8, 12, 1, 29999.00, '2024-04-26'),
(28, 3, 1, 64999.00, '2024-04-28'),
(15, 1, 1, 89999.00, '2024-04-30'),
(29, 18, 1, 8999.00, '2024-05-02'),
(9, 9, 1, 22999.00, '2024-05-04'),
(30, 19, 1, 149999.00, '2024-05-06'),
(16, 6, 2, 19999.00, '2024-05-08'),
(1, 2, 1, 74999.00, '2024-05-10'),
(17, 11, 1, 24999.00, '2024-05-12'),
(10, 7, 2, 16999.00, '2024-05-14'),
(18, 1, 1, 89999.00, '2024-05-16'),
(2, 20, 1, 69999.00, '2024-05-18'),
(19, 8, 1, 45999.00, '2024-05-20'),
(11, 15, 1, 9999.00, '2024-05-22'),
(20, 6, 1, 19999.00, '2024-05-24'),
(3, 12, 2, 29999.00, '2024-05-26'),
(21, 3, 1, 64999.00, '2024-05-28'),
(12, 1, 1, 89999.00, '2024-05-30'),
(22, 18, 1, 8999.00, '2024-06-01'),
(4, 9, 1, 22999.00, '2024-06-03'),
(23, 19, 1, 149999.00, '2024-06-05'),
(13, 6, 2, 19999.00, '2024-06-07'),
(5, 2, 1, 74999.00, '2024-06-09'),
(24, 11, 1, 24999.00, '2024-06-11'),
(14, 7, 1, 16999.00, '2024-06-13'),
(25, 1, 1, 89999.00, '2024-06-15'),
(6, 20, 1, 69999.00, '2024-06-17'),
(26, 8, 1, 45999.00, '2024-06-19'),
(15, 15, 2, 9999.00, '2024-06-21'),
(27, 6, 1, 19999.00, '2024-06-23'),
(7, 12, 1, 29999.00, '2024-06-25'),
(28, 3, 1, 64999.00, '2024-06-27'),
(16, 1, 1, 89999.00, '2024-06-29'),
(1, 1, 2, 89999.00, '2024-07-01'),
(1, 11, 1, 24999.00, '2024-07-02'),
(1, 6, 3, 19999.00, '2024-07-03'),
(1, 19, 1, 149999.00, '2024-07-05'),
(1, 8, 1, 45999.00, '2024-07-08'),
(2, 1, 1, 89999.00, '2024-07-02'),
(2, 9, 2, 22999.00, '2024-07-04'),
(2, 12, 1, 29999.00, '2024-07-06'),
(3, 6, 2, 19999.00, '2024-07-07'),
(3, 15, 3, 9999.00, '2024-07-09'),
(3, 2, 1, 74999.00, '2024-07-11'),
(29, 7, 1, 16999.00, '2024-07-10'),
(30, 20, 1, 69999.00, '2024-07-12'),
(8, 18, 2, 8999.00, '2024-07-14'),
(9, 3, 1, 64999.00, '2024-07-16'),
(10, 19, 1, 149999.00, '2024-07-18'),
(17, 6, 1, 19999.00, '2024-07-20'),
(18, 11, 2, 24999.00, '2024-07-22'),
(19, 9, 1, 22999.00, '2024-07-24'),
(20, 1, 1, 89999.00, '2024-07-26'),
(21, 8, 1, 45999.00, '2024-07-28'),
(4, 4, 2, 14999.00, '2024-01-30'),
(5, 4, 1, 14999.00, '2024-02-12'),
(6, 10, 1, 38999.00, '2024-03-02'),
(7, 10, 1, 38999.00, '2024-04-01'),
(8, 16, 1, 54999.00, '2024-05-03'),
(9, 17, 2, 17999.00, '2024-06-02'),
(10, 13, 1, 12999.00, '2024-07-01'),
(22, 5, 1, NULL, '2024-03-04'),             -- precio sin cargar
(23, 14, 1, NULL, '2024-04-05'),            -- precio sin cargar
(24, 4, 1, 14999.00, '2024-05-06'),
(25, 10, 1, 38999.00, '2024-06-06'),
(26, 13, 2, 12999.00, '2024-07-06'),
(27, 17, 1, 17999.00, '2024-01-19'),
(28, 16, 1, 54999.00, '2024-02-19'),
(29, 5, 1, NULL, NULL),                     -- precio y fecha sin cargar
(30, 4, 1, 14999.00, '2024-04-19'),
(11, 3, 1, 64999.00, '2024-05-19'),
(12, 8, 1, 45999.00, '2024-06-19'),
(13, 9, 2, 22999.00, '2024-07-19'),
(14, 1, 1, 89999.00, '2024-01-21'),
(15, 6, 1, 19999.00, '2024-02-21'),
(16, 11, 1, 24999.00, '2024-03-21'),
(17, 20, 1, 69999.00, '2024-04-21'),
(18, 19, 1, 149999.00, '2024-05-21'),
(19, 2, 1, 74999.00, '2024-06-21'),
(20, 8, 1, 45999.00, '2024-07-21'),
(21, 15, 3, 9999.00, '2024-01-23'),
(22, 12, 1, 29999.00, '2024-02-23'),
(23, 6, 2, 19999.00, '2024-03-23'),
(24, 1, 1, 89999.00, '2024-04-23'),
(25, 9, 1, 22999.00, '2024-05-23'),
(26, 3, 1, 64999.00, '2024-06-23'),
(27, 20, 1, 69999.00, '2024-07-23'),
(28, 18, 1, 8999.00, '2024-01-27'),
(29, 11, 2, 24999.00, '2024-02-27'),
(30, 7, 1, 16999.00, '2024-03-27'),
(1, 1, 1, 89999.00, '2024-08-01'),
(2, 6, 1, 19999.00, '2024-08-02'),
(3, 9, 1, 22999.00, '2024-08-03'),
(4, 11, 2, 24999.00, '2024-08-04'),
(5, 19, 1, 149999.00, '2024-08-05'),
(6, 2, 1, 74999.00, '2024-08-06'),
(7, 8, 1, 45999.00, '2024-08-07'),
(8, 20, 1, 69999.00, '2024-08-08'),
(9, 1, 1, 89999.00, '2024-08-09'),
(10, 15, 2, 9999.00, '2024-08-10'),
(1, 3, 1, 64999.00, '2024-08-11'),
(2, 16, 1, 54999.00, '2024-08-12'),
(3, 19, 1, 149999.00, '2024-08-13'),
(11, 6, 1, 19999.00, '2024-08-14'),
(12, 9, 1, 22999.00, '2024-08-15'),
(13, 1, 1, 89999.00, '2024-08-16'),
(14, 11, 1, 24999.00, '2024-08-17'),
(15, 8, 1, 45999.00, '2024-08-18'),
(16, 20, 1, 69999.00, '2024-08-19'),
(17, 12, 1, 29999.00, '2024-08-20'),
(18, 6, 2, 19999.00, '2024-08-21'),
(19, 3, 1, 64999.00, '2024-08-22'),
(20, 9, 1, 22999.00, '2024-08-23');
