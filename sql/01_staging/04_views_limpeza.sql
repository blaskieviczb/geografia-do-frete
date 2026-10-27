-- =====================================================================
-- Projeto: A geografia do frete
-- Etapa 1 - Camada limpa: views que aplicam as decisões de escopo
--           (ver docs/decisoes_dados.md)
--
-- Como executar (PSQL Tool do pgAdmin, banco geografia_frete):
--   \cd 'C:/Users/Samsung/OneDrive/Documents/GitHub/geografia-do-frete'
--   \i sql/01_staging/04_views_limpeza.sql
--
-- Ideia: staging guarda o dado BRUTO (tudo texto). Aqui criamos VIEWS
-- (consultas salvas com nome) no schema "limpo", que convertem tipos e
-- aplicam as regras. Nada é apagado de staging.
-- Script reexecutável: apaga e recria as views.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS limpo;

-- Apagamos na ordem inversa da dependência (pedidos_base usa as outras).
DROP VIEW IF EXISTS limpo.pedidos_base;
DROP VIEW IF EXISTS limpo.frete_por_pedido;
DROP VIEW IF EXISTS limpo.avaliacao_por_pedido;
DROP VIEW IF EXISTS limpo.pedidos_entregues;
DROP VIEW IF EXISTS limpo.produtos;


-- ---------------------------------------------------------------------
-- 1. pedidos_entregues
-- Regras: status 'delivered', com data de entrega ao cliente, comprados
-- de jan/2017 a ago/2018 (meses completos).
-- NULLIF(coluna, '') troca texto vazio por NULL; depois ::timestamp
-- converte o texto em data/hora.
-- ---------------------------------------------------------------------
CREATE VIEW limpo.pedidos_entregues AS
SELECT
    order_id,
    customer_id,
    NULLIF(order_purchase_timestamp, '')::timestamp       AS data_compra,
    NULLIF(order_approved_at, '')::timestamp              AS data_aprovacao,
    NULLIF(order_delivered_carrier_date, '')::timestamp   AS data_postagem,
    NULLIF(order_delivered_customer_date, '')::timestamp  AS data_entrega,
    NULLIF(order_estimated_delivery_date, '')::timestamp  AS data_entrega_estimada
FROM staging.orders
WHERE order_status = 'delivered'
  AND NULLIF(order_delivered_customer_date, '') IS NOT NULL
  AND NULLIF(order_purchase_timestamp, '')::timestamp >= TIMESTAMP '2017-01-01'
  AND NULLIF(order_purchase_timestamp, '')::timestamp <  TIMESTAMP '2018-09-01';


-- ---------------------------------------------------------------------
-- 2. avaliacao_por_pedido
-- Regra: UMA avaliação por pedido, a mais recente.
-- ROW_NUMBER() numera as avaliações de cada pedido (PARTITION BY order_id),
-- da mais recente para a mais antiga; ficamos só com a número 1.
-- Isso evita que o pedido apareça duplicado nos JOINs.
-- ---------------------------------------------------------------------
CREATE VIEW limpo.avaliacao_por_pedido AS
SELECT
    order_id,
    review_id,
    nota,
    data_resposta
FROM (
    SELECT
        order_id,
        review_id,
        review_score::int                                   AS nota,
        NULLIF(review_answer_timestamp, '')::timestamp      AS data_resposta,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY NULLIF(review_answer_timestamp, '')::timestamp DESC NULLS LAST,
                     NULLIF(review_creation_date, '')::timestamp   DESC NULLS LAST,
                     review_id
        ) AS ordem
    FROM staging.order_reviews
) t
WHERE ordem = 1;


-- ---------------------------------------------------------------------
-- 3. frete_por_pedido
-- Regra: frete e valor do pedido = soma dos itens (o dado original
-- registra o frete por item). frete_zero marca pedidos com frete total 0.
-- ---------------------------------------------------------------------
CREATE VIEW limpo.frete_por_pedido AS
SELECT
    order_id,
    COUNT(*)                          AS qtd_itens,
    SUM(price::numeric)               AS valor_produtos,
    SUM(freight_value::numeric)       AS valor_frete,
    (SUM(freight_value::numeric) = 0) AS frete_zero
FROM staging.order_items
GROUP BY order_id;


-- ---------------------------------------------------------------------
-- 4. produtos
-- Regras: produto sem categoria vira 'sem_categoria'; usamos o nome em
-- inglês quando existe tradução (senão, o nome original); peso zero ou
-- ausente vira NULL (não é peso real).
-- ---------------------------------------------------------------------
CREATE VIEW limpo.produtos AS
SELECT
    p.product_id,
    COALESCE(
        NULLIF(t.product_category_name_english, ''),
        NULLIF(p.product_category_name, ''),
        'sem_categoria'
    ) AS categoria,
    CASE
        WHEN NULLIF(p.product_weight_g, '')::numeric > 0
            THEN NULLIF(p.product_weight_g, '')::numeric
    END AS peso_g
FROM staging.products p
LEFT JOIN staging.product_category_translation t
       ON t.product_category_name = p.product_category_name;


-- ---------------------------------------------------------------------
-- 5. pedidos_base (uma linha por pedido entregue no escopo)
-- Junta tudo. Usamos LEFT JOIN para NÃO perder pedidos que não têm
-- itens ou avaliação (esses campos ficam NULL). Como cada visão
-- auxiliar tem no máximo 1 linha por pedido, não há duplicação.
-- ---------------------------------------------------------------------
CREATE VIEW limpo.pedidos_base AS
SELECT
    p.order_id,
    p.data_compra,
    p.data_aprovacao,
    p.data_postagem,
    p.data_entrega,
    p.data_entrega_estimada,
    c.customer_unique_id,
    c.customer_zip_code_prefix  AS cep_prefixo_cliente,
    c.customer_city             AS cidade_cliente,
    c.customer_state            AS uf_cliente,
    f.qtd_itens,
    f.valor_produtos,
    f.valor_frete,
    f.frete_zero,
    (f.order_id IS NOT NULL)    AS tem_itens,
    a.nota                      AS nota_avaliacao
FROM limpo.pedidos_entregues p
JOIN staging.customers c
       ON c.customer_id = p.customer_id
LEFT JOIN limpo.frete_por_pedido f
       ON f.order_id = p.order_id
LEFT JOIN limpo.avaliacao_por_pedido a
       ON a.order_id = p.order_id;


-- =====================================================================
-- CONFERÊNCIAS
-- =====================================================================
\echo
\echo '=== Linhas por visao ==='
SELECT 'pedidos_entregues' AS visao, COUNT(*) AS linhas FROM limpo.pedidos_entregues
UNION ALL SELECT 'avaliacao_por_pedido', COUNT(*) FROM limpo.avaliacao_por_pedido
UNION ALL SELECT 'frete_por_pedido',     COUNT(*) FROM limpo.frete_por_pedido
UNION ALL SELECT 'produtos',             COUNT(*) FROM limpo.produtos
UNION ALL SELECT 'pedidos_base',         COUNT(*) FROM limpo.pedidos_base;

\echo
\echo '=== Teste de duplicacao em pedidos_base (sem_duplicacao deve ser t) ==='
SELECT
    COUNT(*)                                AS linhas,
    COUNT(DISTINCT order_id)                AS pedidos_distintos,
    COUNT(*) = COUNT(DISTINCT order_id)     AS sem_duplicacao
FROM limpo.pedidos_base;

\echo
\echo '=== Cobertura em pedidos_base ==='
SELECT
    COUNT(*)                          AS pedidos,
    COUNT(*) FILTER (WHERE tem_itens) AS com_itens,
    COUNT(nota_avaliacao)             AS com_avaliacao
FROM limpo.pedidos_base;
