# Decisões sobre os dados

Registro das checagens de qualidade feitas na camada `staging` e das regras de escopo aplicadas na camada `limpo`. O código está em `sql/01_staging/` (`03_checagem_qualidade.sql` e `04_views_limpeza.sql`).

## O que encontramos

| Tema | Achado | Impacto |
|---|---|---|
| Status dos pedidos | 97,0% entregues (96.478 de 99.441). O restante está em andamento ou não concluído (enviado, cancelado, indisponível etc.) | Medir atraso e satisfação exige pedidos entregues |
| Datas ausentes | 2.965 pedidos sem data de entrega ao cliente | Sem data não há prazo nem atraso |
| Inconsistências | 8 pedidos "entregues" sem data de entrega; 6 pedidos "não entregues" com data de entrega | Erros do dado, tratados por exclusão |
| Duplicidade | `order_id` único (99.441). `customer_unique_id` tem 96.096 valores | Para contar pessoas, usar `customer_unique_id` |
| Avaliações | 98.126 pedidos com 1 avaliação, 547 com 2 ou 3, 768 sem nenhuma | Um JOIN direto duplicaria pedidos |
| Itens e frete | 112.650 itens em 98.666 pedidos; frete registrado por item | O frete do pedido é a soma dos itens |
| Período | Quase sem pedidos em 2016 e depois de agosto de 2018; volume consistente de jan/2017 a ago/2018 | Recorte temporal |
| Frete zero | 383 itens (0,3%) com frete zero | Distorce o frete como % do valor |
| Produtos | 610 sem categoria, 2 sem peso, 4 com peso zero | Categoria e peso serão usados para comparar fretes |
| Estados | 27 UFs, com volume muito desigual (SP: 41.746 clientes; RR: 46) | Exige volume mínimo por mercado |

## Decisões de escopo

1. **Pedidos:** somente status `delivered` com data de entrega ao cliente preenchida.
2. **Período:** pedidos feitos de 01/01/2017 a 31/08/2018, meses com volume completo.
3. **Avaliações:** uma por pedido, a mais recente (por data de resposta). Pedidos sem avaliação permanecem nas métricas de logística e ficam fora das de satisfação.
4. **Frete do pedido:** soma do frete dos itens. Pedidos com frete zero ficam, sinalizados em `frete_zero`, para testar se mudam as conclusões.
5. **Produtos sem categoria:** rotulados `sem_categoria` e excluídos das comparações por categoria. Peso zero ou ausente é tratado como desconhecido (`NULL`).
6. **Volume mínimo por mercado:** a definir na etapa de métricas, depois de ver a distribuição de pedidos por estado.

## Resultado do escopo

| Etapa | Pedidos |
|---|---|
| Pedidos entregues (status) | 96.478 |
| Após exigir data de entrega e recorte jan/2017 a ago/2018 (`pedidos_base`) | 96.203 |
| Com itens (frete calculável) | 96.203 |
| Com avaliação | 95.560 |

Testes realizados: `pedidos_base` tem uma linha por pedido, sem duplicação.

## Limitações conhecidas

- Os dados cobrem 2016 a 2018 e não descrevem o mercado atual.
- O frete médio de um estado depende do mix de produtos, por isso a análise controla por categoria e peso.
- Avaliações têm viés de resposta: nem todos os clientes avaliam.
- Os resultados territoriais descrevem regiões, não indivíduos, e não implicam causalidade.
