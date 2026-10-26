-- =====================================================================
-- Projeto: A geografia do frete
-- Etapa 1 - Staging: carga dos CSVs da Olist
--
-- Como executar (no psql / SQL Shell), a partir da raiz do repositório:
--   \cd 'C:/caminho/para/geografia-do-frete'
--   \i sql/01_staging/02_carregar_staging.sql
--
-- Pré-requisitos:
--   * tabelas criadas por 01_criar_tabelas_staging.sql
--   * CSVs da Olist dentro da pasta data/ (sem subpasta)
--
-- Observação: \copy é um comando do psql (lê o arquivo no SEU
-- computador) e precisa ficar em uma única linha.
-- =====================================================================

\copy staging.customers FROM 'data/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy staging.geolocation FROM 'data/olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy staging.order_items FROM 'data/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy staging.order_payments FROM 'data/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy staging.order_reviews FROM 'data/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy staging.orders FROM 'data/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy staging.products FROM 'data/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy staging.sellers FROM 'data/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy staging.product_category_translation FROM 'data/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Conferência rápida da carga (contagem de linhas por tabela)
SELECT 'customers' AS tabela, COUNT(*) AS linhas FROM staging.customers
UNION ALL SELECT 'geolocation', COUNT(*) FROM staging.geolocation
UNION ALL SELECT 'order_items', COUNT(*) FROM staging.order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM staging.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM staging.order_reviews
UNION ALL SELECT 'orders', COUNT(*) FROM staging.orders
UNION ALL SELECT 'products', COUNT(*) FROM staging.products
UNION ALL SELECT 'sellers', COUNT(*) FROM staging.sellers
UNION ALL SELECT 'product_category_translation', COUNT(*) FROM staging.product_category_translation;
