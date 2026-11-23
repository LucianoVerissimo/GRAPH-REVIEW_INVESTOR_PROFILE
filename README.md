# Análise de carteira de investimento usando grafo

## Objetivo
O objetivo é criar e usar uma função PL/SQL que retorna o JSON que descreve o perfil de investidor de um cliente. Essa função pode ser chamada como um ferramenta para agentes, com o objetivo de padronizar respostas e evitar inferências desnecessárias. A função executa operações de leitura pré-determinadas sobre um grafo. 

## Sobre o grafo de propriedades no Oracle Database 
O Oracle database possui suporte a grafos desde a versão 10.2 (2005). Na época era ofereciodo apenas grafo semântico. Com a evolução das versões do Oracle, na verão 12.2, por volta de 2017, foi introduzido Grafo de Propriedades através do uso da linguagem PGQL (com cliente próprio). Em 2023, foi introduzido suporte SQL/PGQ (padrão ANSI) para realizar navegação em grafos a partir de qualquer cliente Oracle. 

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

Este modelo permite que um gerente de investimento descubra qual o perfil de investidor definido pelo banco (seja por classificações manuais ou automáticas). Produtos são comprados por clientes. Cada produto tem uma classificação de Perfil de Investidor adequado, e obrigatoriamente tem um banco emissor. Por fim, agências de risco avaliam o risco de crédito do emissor. Como cada agência tem um padrão de nomenclatura diferente, foi criado um Rating Normalizado que define um intervalo de 1 (melhor avaliação) a 5 (pior avaliação), deste modo, criamos uma padronização de classificação que é independente da nomenclatura da agência avaliadora. 
