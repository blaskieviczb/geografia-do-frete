-- =====================================================================
-- Projeto: A geografia do frete
-- Etapa 1 - Checagem de qualidade dos dados (camada staging)
--
-- Objetivo: entender os problemas do dado ANTES de analisar, para
-- decidir (e documentar) o escopo da análise.
--
-- Como executar (PSQL Tool do pgAdmin, banco geografia_frete):
--   \cd 'C:/Users/Samsung/OneDrive/Documents/GitHub/geografia-do-frete'
--   \i sql/01_staging/03_checagem_qualidade.sql
--
-- Este script só LÊ dados (SELECT). Não altera nada.
-- Lembrete: em staging todas as colunas são TEXT. Datas no formato
-- 'AAAA-MM-DD hh:mm:ss' ordenam corretamente mesmo como texto.
-- =====================================================================


\echo
\echo '=== A. Pedidos por status ==='
-- Quantos pedidos há em cada situação (entregue, cancelado, etc.)?
SELECT
    order_status,
    COUNT(*) AS pedidos,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentual
FROM staging.orders
GROUP BY order_status
ORDER BY pedidos DESC;


\echo
\echo '=== B. Datas ausentes na tabela de pedidos ==='
-- Quantos pedidos não têm cada data? (NULL ou texto vazio)
SELECT
    COUNT(*) AS total_pedidos,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL OR order_approved_at = '')
        AS sem_data_aprovacao,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL OR order_delivered_carrier_date = '')
        AS sem_data_postagem,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL OR order_delivered_customer_date = '')
        AS sem_data_entrega_cliente,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL OR order_estimated_delivery_date = '')
        AS sem_data_estimada
FROM staging.orders;


\echo
\echo '=== C. Inconsistências entre status e data de entrega ==='
-- C1: pedidos "delivered" SEM data de entrega ao cliente
-- C2: pedidos que NÃO são "delivered" mas TÊM data de entrega
SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND (order_delivered_customer_date IS NULL OR order_delivered_customer_date = '')
    ) AS entregues_sem_data_entrega,
    COUNT(*) FILTER (
        WHERE order_status <> 'delivered'
          AND order_delivered_customer_date IS NOT NULL
          AND order_delivered_customer_date <> ''
    ) AS nao_entregues_com_data_entrega
FROM staging.orders;


\echo
\echo '=== D. Duplicidade em pedidos e clientes ==='
-- order_id deve ser único em orders.
-- customer_id é único por pedido; customer_unique_id identifica a PESSOA
-- (uma pessoa pode ter vários pedidos).
SELECT
    (SELECT COUNT(*) FROM staging.orders)                        AS linhas_orders,
    (SELECT COUNT(DISTINCT order_id) FROM staging.orders)        AS order_id_distintos,
    (SELECT COUNT(*) FROM staging.customers)                     AS linhas_customers,
    (SELECT COUNT(DISTINCT customer_id) FROM staging.customers)  AS customer_id_distintos,
    (SELECT COUNT(DISTINCT customer_unique_id) FROM staging.customers) AS clientes_unicos;


\echo
\echo '=== E. Avaliações por pedido ==='
-- Um pedido pode ter 0, 1 ou mais avaliações? Se tiver mais de uma,
-- um JOIN direto com reviews DUPLICA pedidos (efeito "fan-out").
SELECT
    avaliacoes_no_pedido,
    COUNT(*) AS pedidos
FROM (
    SELECT order_id, COUNT(*) AS avaliacoes_no_pedido
    FROM staging.order_reviews
    GROUP BY order_id
) t
GROUP BY avaliacoes_no_pedido
ORDER BY avaliacoes_no_pedido;

\echo '--- pedidos SEM nenhuma avaliação ---'
SELECT COUNT(*) AS pedidos_sem_avaliacao
FROM staging.orders o
LEFT JOIN (SELECT DISTINCT order_id FROM staging.order_reviews) r
       ON r.order_id = o.order_id
WHERE r.order_id IS NULL;


\echo
\echo '=== F. Itens por pedido e pedidos sem itens ==='
-- O frete (freight_value) está por ITEM, não por pedido.
-- Para o frete do pedido será preciso somar os itens.
SELECT
    COUNT(*)                  AS linhas_de_itens,
    COUNT(DISTINCT order_id)  AS pedidos_com_itens
FROM staging.order_items;

\echo '--- pedidos que não aparecem em order_items ---'
SELECT COUNT(*) AS pedidos_sem_itens
FROM staging.orders o
LEFT JOIN (SELECT DISTINCT order_id FROM staging.order_items) i
       ON i.order_id = o.order_id
WHERE i.order_id IS NULL;


\echo
\echo '=== G. Período coberto (pedidos por mês) ==='
-- Meses das pontas costumam ser incompletos; isso justifica o recorte.
SELECT
    LEFT(order_purchase_timestamp, 7) AS ano_mes,
    COUNT(*) AS pedidos
FROM staging.orders
GROUP BY 1
ORDER BY 1;


\echo
\echo '=== H. Frete e preço: valores zero ou estranhos ==='
-- Frete zero distorce o "frete como % do valor". Precisamos saber quantos há.
SELECT
    COUNT(*)                                          AS itens,
    COUNT(*) FILTER (WHERE freight_value::numeric = 0) AS itens_frete_zero,
    COUNT(*) FILTER (WHERE price::numeric = 0)         AS itens_preco_zero,
    MIN(freight_value::numeric)                        AS frete_minimo,
    MAX(freight_value::numeric)                        AS frete_maximo,
    ROUND(AVG(freight_value::numeric), 2)              AS frete_medio
FROM staging.order_items;


\echo
\echo '=== I. Produtos sem categoria ou sem peso ==='
-- Categoria e peso serão usados para controlar o frete. Quantos faltam?
SELECT
    COUNT(*) AS produtos,
    COUNT(*) FILTER (WHERE product_category_name IS NULL OR product_category_name = '')
        AS sem_categoria,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL OR product_weight_g = '')
        AS sem_peso,
    COUNT(*) FILTER (WHERE product_weight_g = '0')
        AS peso_zero
FROM staging.products;


\echo
\echo '=== J. Estados dos clientes ==='
-- Esperamos 27 UFs. Algo fora disso indica erro de digitação.
SELECT
    customer_state,
    COUNT(*) AS clientes
FROM staging.customers
GROUP BY customer_state
ORDER BY clientes DESC;

\echo
\echo '=== Fim das checagens ==='
