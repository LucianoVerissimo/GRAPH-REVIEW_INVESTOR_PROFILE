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
