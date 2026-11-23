# Análise de carteira de investimento usando grafo

## Objetivo
O objetivo é criar e usar uma função PL/SQL que retorna o JSON que descreve o perfil de investidor de um cliente. Essa função pode ser chamada como um ferramenta para agentes, com o objetivo de padronizar respostas e evitar inferências desnecessárias. A função executa operações de leitura pré-determinadas sobre um grafo. 

## Sobre o grafo de propriedades no Oracle Database 
O Oracle database possui suporte a grafos desde a versão 10.2 (2005). Na época era ofereciodo apenas grafo semântico. Com a evolução das versões do Oracle, na verão 12.2, por volta de 2017, foi introduzido Grafo de Propriedades através do uso da linguagem PGQL (com cliente próprio). Em 2023, foi introduzido suporte SQL/PGQ (padrão ANSI) para realizar navegação em grafos a partir de qualquer cliente Oracle. Os scripts deste repositório dependem do Oracle Database 26ai. Uma imagem gratuita pode ser obtida aqui: https://www.oracle.com/database/free/

## Modelo grafo utilizado neste repositório
O modelo de grafo apresentado conecta clientes, produtos financeiros, perfis de investidor, emissores e agências de risco. 


```text
                         ┌──────────────────────┐
                         │ PERFIL DE INVESTIDOR │
                         └──────────────────────┘
                             ▲              ▲
                             │              │
                     TEM_PERFIL      RECOMENDADO_PARA
                  (sem propriedades) (score de adequação)
                             │              │
┌───────────┐                │              │
│  CLIENTE  │────────────────┘              │
└───────────┘                               │
      │                               ┌───────────┐
      └────────── COMPRA ────────────►│  PRODUTO  │
             (data e valor aplicado)  └───────────┘
                                            │
                                       EMITIDO_POR
                                            │
                                            ▼
                                      ┌───────────┐
                                      │  EMISSOR  │
                                      └───────────┘
                                            ▲
                                            │
                                          AVALIA
                                 (rating normalizado 1–5)
                                            │
                                  ┌───────────────────┐
                                  │ AGÊNCIA DE RISCO  │
                                  └───────────────────┘
```

Este modelo permite que um gerente de investimento descubra qual o perfil de investidor previamente definido pelo banco (seja por classificações manuais ou automáticas). Também é possível ver quais produtos foram comprados por quais clientes, o produtos podem ser CDBs, LCIs, LCAs, etc. A aresta COMPRA indica a aquisiçcão de um produto por um cliente (fato que aconteceu em um dia, por um determinado valor). Cada produto tem uma classificação de Perfil de Investidor mais aderente. Cada produto sempre tem um banco emissor, com isso o grafo pode indicar de quais bancos um cliente compra produtos. Por fim, agências de risco avaliam o risco de crédito do emissor, e como cada agência tem um padrão de nomenclatura diferente, foi criado um Rating Normalizado que define um intervalo de 1 (melhor avaliação) a 5 (pior avaliação), deste modo, criamos uma padronização de classificação que é independente da nomenclatura da agência avaliadora. 


## Conteúdo dos Arquivos

- 01-limpeza.sql: Apaga todos os objetos criados.
- 02-setup_inicial.sql: Criar tabelas usadas como vértices e aresta, define comentários de tabelas e colunas (útil para NL2SQL), cria índices para acelerar navegação no grafo entre vértices através das arestas.
- 03-carga_dados_exemplo.sql: Carrega alguns dados para testes.
- 04-cria_grafo_de_propriedades.sql: Comando que cria o grafo chamado grafo_investimentos (que será usado para navegação de descoberta).
- 05-pesquisas_básicas.sql: Executa algumas instruções SQL/PGQ sobre o grafo criado. 
- 06-cria_função_para_extração_perfil.sql: Função que executa diversas leituras no grafo e retorna um JSON para consumo posterior por agente de LLM. 

