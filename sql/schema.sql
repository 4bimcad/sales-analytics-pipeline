-- =========================================================
-- Sales Analytics Pipeline — Database Schema
-- Target: PostgreSQL (Supabase)
-- This file reflects the ACTUAL structure currently in Supabase
-- (extracted via information_schema.columns)
-- =========================================================

DROP TABLE IF EXISTS compras CASCADE;
DROP TABLE IF EXISTS certificados CASCADE;
DROP TABLE IF EXISTS cursos CASCADE;
DROP TABLE IF EXISTS categoria CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;

-- ---------------------------------------------------------
-- categoria: course category lookup
-- ---------------------------------------------------------
CREATE TABLE categoria (
    id          SERIAL PRIMARY KEY,
    categoria   VARCHAR(50) NOT NULL
);

-- ---------------------------------------------------------
-- certificados: certification tier catalog
-- (Inicial / Profesional / Premium, with fixed price per tier)
-- ---------------------------------------------------------
CREATE TABLE certificados (
    id            SERIAL PRIMARY KEY,
    certificado   VARCHAR(50),
    precio        NUMERIC
);

-- ---------------------------------------------------------
-- clientes: buyers
-- ---------------------------------------------------------
CREATE TABLE clientes (
    id              SERIAL PRIMARY KEY,
    nombre_cliente  VARCHAR(150) NOT NULL,
    fecha_registro  DATE
);

-- ---------------------------------------------------------
-- cursos: course catalog
-- ---------------------------------------------------------
CREATE TABLE cursos (
    id              SERIAL PRIMARY KEY,
    nombre_curso    VARCHAR(200) NOT NULL,
    horas_curso     INTEGER NOT NULL,
    modulos_curso   INTEGER NOT NULL,
    categoria_id    INTEGER NOT NULL REFERENCES categoria(id)
);

-- ---------------------------------------------------------
-- compras: purchase / transaction fact table
-- ---------------------------------------------------------
CREATE TABLE compras (
    id                  SERIAL PRIMARY KEY,
    cliente_id          INTEGER NOT NULL REFERENCES clientes(id),
    curso_id            INTEGER NOT NULL REFERENCES cursos(id),
    categoria_id        INTEGER NOT NULL REFERENCES categoria(id),
    certificado_id      INTEGER REFERENCES certificados(id),
    fecha_compra        DATE NOT NULL,
    monto               NUMERIC(10,2) NOT NULL
);

-- ---------------------------------------------------------
-- Indexes for common analytical queries
-- ---------------------------------------------------------
CREATE INDEX idx_compras_cliente   ON compras(cliente_id);
CREATE INDEX idx_compras_curso     ON compras(curso_id);
CREATE INDEX idx_compras_categoria ON compras(categoria_id);
CREATE INDEX idx_compras_fecha     ON compras(fecha_compra);
