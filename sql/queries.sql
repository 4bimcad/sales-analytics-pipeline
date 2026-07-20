-- =========================================================
-- Analytical queries — matches actual schema (see schema.sql)
-- =========================================================

-- 1. Top clients by total revenue
SELECT
    cl.nombre_cliente,
    SUM(co.monto) AS revenue_total,
    COUNT(co.id)  AS compras_totales
FROM compras co
JOIN clientes cl ON cl.id = co.cliente_id
GROUP BY cl.nombre_cliente
ORDER BY revenue_total DESC
LIMIT 10;

-- 2. Revenue by month
SELECT
    DATE_TRUNC('month', fecha_compra)::date AS mes,
    SUM(monto) AS revenue_mensual,
    COUNT(*)   AS num_compras
FROM compras
GROUP BY 1
ORDER BY 1;

-- 3. Revenue by category
SELECT
    ca.categoria,
    SUM(co.monto) AS revenue_total,
    COUNT(co.id)  AS num_compras
FROM compras co
JOIN categoria ca ON ca.id = co.categoria_id
GROUP BY ca.categoria
ORDER BY revenue_total DESC;

-- 4. Top courses by number of purchases
SELECT
    cu.nombre_curso,
    COUNT(co.id) AS compras,
    SUM(co.monto) AS revenue
FROM compras co
JOIN cursos cu ON cu.id = co.curso_id
GROUP BY cu.nombre_curso
ORDER BY compras DESC
LIMIT 10;

-- 5. Revenue and volume by certification tier (Inicial/Profesional/Premium)
SELECT
    ce.certificado AS tier,
    ce.precio      AS precio_lista,
    COUNT(co.id)   AS compras,
    SUM(co.monto)  AS revenue_total
FROM compras co
JOIN certificados ce ON ce.id = co.certificado_id
GROUP BY ce.certificado, ce.precio
ORDER BY revenue_total DESC;

-- 6. Client conversion: % of clients with more than 1 purchase (repeat buyers)
WITH compras_por_cliente AS (
    SELECT cliente_id, COUNT(*) AS n_compras
    FROM compras
    GROUP BY cliente_id
)
SELECT
    COUNT(*) FILTER (WHERE n_compras > 1)::decimal
        / COUNT(*) * 100 AS pct_clientes_recurrentes
FROM compras_por_cliente;

-- 7. Simple month-over-month retention
-- (clients active in month N who were also active in month N-1)
WITH actividad_mensual AS (
    SELECT DISTINCT
        cliente_id,
        DATE_TRUNC('month', fecha_compra)::date AS mes
    FROM compras
)
SELECT
    a.mes,
    COUNT(DISTINCT a.cliente_id) AS clientes_activos,
    COUNT(DISTINCT b.cliente_id) AS clientes_retenidos
FROM actividad_mensual a
LEFT JOIN actividad_mensual b
    ON b.cliente_id = a.cliente_id
    AND b.mes = a.mes - INTERVAL '1 month'
GROUP BY a.mes
ORDER BY a.mes;

-- 8. Average ticket size per client
SELECT
    cl.nombre_cliente,
    ROUND(AVG(co.monto), 2) AS ticket_promedio
FROM compras co
JOIN clientes cl ON cl.id = co.cliente_id
GROUP BY cl.nombre_cliente
ORDER BY ticket_promedio DESC;

-- 9. New clients per month (based on first purchase date)
WITH primera_compra AS (
    SELECT cliente_id, MIN(fecha_compra) AS primera_fecha
    FROM compras
    GROUP BY cliente_id
)
SELECT
    DATE_TRUNC('month', primera_fecha)::date AS mes,
    COUNT(*) AS clientes_nuevos
FROM primera_compra
GROUP BY 1
ORDER BY 1;
