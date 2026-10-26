# A geografia do frete

**Onde a logística pesa no bolso e na satisfação do cliente no e-commerce brasileiro**

> 🚧 **Status: em desenvolvimento.** Este repositório está sendo construído em etapas. O checklist no final mostra o andamento.

## Problema de negócio

Uma plataforma de e-commerce atende clientes em todas as regiões do Brasil, mas não tem uma visão integrada de **onde os custos de frete e os problemas de entrega coincidem com experiências de compra piores**. Sem essa visão, é difícil decidir onde concentrar esforços de melhoria logística.

## Pergunta central

> **Quais mercados apresentam os maiores atritos logísticos e devem ser priorizados para melhorias na experiência de compra?**

## Hipóteses

Formuladas antes da análise, para serem testadas (e eventualmente refutadas):

1. **H1:** o atraso na entrega está associado a avaliações piores em todas as regiões, mas com intensidade diferente entre elas.
2. **H2:** o frete pesa mais em regiões distantes dos polos de vendedores, mesmo depois de controlar por categoria e peso do produto.
3. **H3:** mercados com pior desempenho logístico tendem a ter menor renda e infraestrutura (indicadores territoriais do IBGE).

## Dados

| Fonte | Uso |
|---|---|
| [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle) | Pedidos, itens, frete, prazos, avaliações, clientes, vendedores e geolocalização (2016-2018) |
| IBGE | Indicadores territoriais por município (população, PIB, renda) |

Os arquivos de dados **não** estão versionados neste repositório. Veja `data/README.md` para instruções de download.

## Abordagem

1. **SQL (PostgreSQL):** ingestão, limpeza, dimensão territorial e views analíticas de indicadores logísticos.
2. **Power BI:** modelo estrela, medidas DAX e dashboard executivo com duas páginas (diagnóstico geográfico e relação entre logística, satisfação e prioridades).
3. **Matriz de priorização:** score que combina frete relativo, atraso, avaliações negativas e volume de pedidos, com análise de sensibilidade dos pesos.
4. **Interpretação territorial:** leitura dos resultados à luz de indicadores socioeconômicos regionais.

## Estrutura do repositório

```
geografia-do-frete/
├── data/        # dados brutos (não versionados)
├── sql/
│   ├── 01_staging/
│   ├── 02_dimensoes/
│   ├── 03_metricas/
│   └── 04_views_powerbi/
├── docs/        # modelo de dados e dicionário de dados
├── powerbi/     # dashboard
└── imagens/     # capturas de tela
```

## Limitações

- Os dados da Olist cobrem **2016-2018**. O projeto é um estudo de caso histórico: o método é replicável com dados atuais, mas os resultados não descrevem o mercado de hoje.
- A associação entre indicadores territoriais e desempenho logístico é entre **regiões**, não entre indivíduos, e não implica causalidade.
- Avaliações de clientes estão sujeitas a viés de resposta.

## Andamento

- [x] Etapa 0: organização do repositório
- [ ] Etapa 1: ingestão e qualidade dos dados
- [ ] Etapa 2: dimensão territorial (IBGE)
- [ ] Etapa 3: métricas logísticas
- [ ] Etapa 4: análise das hipóteses
- [ ] Etapa 5: matriz de priorização
- [ ] Etapa 6: dashboard no Power BI
- [ ] Etapa 7: interpretação e recomendação

## Autoria

Bruna Stall Blaskievicz · www.linkedin.com/in/bruna-blaskievicz2607
