------------------------------------------------------------------------------
-- 7. CONSULTAS BÁSICAS (SQL/GRAPH_TABLE)
------------------------------------------------------------------------------
set lines 300
col nome_emissor for a30
col nome_produto for a50
set pages 100 
set echo on 

-- A. Produtos ativos adequados ao mesmo perfil de um cliente.
SELECT *
FROM GRAPH_TABLE (grafo_investimentos
  MATCH (c IS cliente)-[tp IS tem_perfil]->(pf IS perfil_investidor)
        <-[rp IS recomendado_para]-(p IS produto)
  WHERE c.id_cliente = 9
    AND p.oferta_ativa = 'S'
  COLUMNS (p.id_produto, p.nome_produto, p.subtipo, p.tipo_indexacao,
           p.valor_indexacao, p.valor_equivalente, rp.score_adequacao)
)
ORDER BY score_adequacao DESC, valor_equivalente DESC;

-- B. Produtos ativos, recomendados a conservadores, cujos emissores possuem risco <= 2.
SELECT DISTINCT *
FROM GRAPH_TABLE (grafo_investimentos
  MATCH (p IS produto)-[rp IS recomendado_para]->(pf IS perfil_investidor),
        (p)-[pe IS emitido_por]->(e IS emissor)<-[av IS avalia]-(a IS agencia_risco)
  WHERE pf.perfil_padrao = 'CONSERVADOR'
    AND p.oferta_ativa = 'S'
    AND av.grau_investimento_normalizado <= 2
  COLUMNS (p.id_produto, p.nome_produto, e.nome_emissor,
           a.nome_agencia, av.grau_investimento_agencia,
           av.grau_investimento_normalizado)
)
ORDER BY grau_investimento_normalizado, nome_produto;

-- C. Clientes que ainda nao compraram nenhum produto (consulta relacional de controle).
SELECT c.id_cliente, c.nome_cliente, c.classe_cliente, p.nome_perfil
FROM cliente c
JOIN cliente_tem_perfil cp ON cp.id_cliente = c.id_cliente
JOIN perfil_investidor p ON p.id_perfil = cp.id_perfil
WHERE NOT EXISTS (
  SELECT 1 FROM cliente_compra_produto cc WHERE cc.id_cliente = c.id_cliente
)
ORDER BY c.id_cliente;

-- D. Risco medio normalizado de cada emissor, combinando as tres agencias.
SELECT e.nome_emissor,
       ROUND(AVG(a.grau_investimento_normalizado), 2) AS risco_medio_normalizado
FROM emissor e
JOIN agencia_avalia_emissor a ON a.id_emissor = e.id_emissor
GROUP BY e.nome_emissor
ORDER BY risco_medio_normalizado, e.nome_emissor;

-- E. Recomenda produtos ativos de baixo risco para o perfil do cliente 5.
-- Baixo risco = nota normalizada da agencia menor ou igual a 2.
SELECT DISTINCT *
FROM GRAPH_TABLE (grafo_investimentos
  MATCH (c IS cliente)-[tp IS tem_perfil]->(pf IS perfil_investidor)
        <-[rp IS recomendado_para]-(p IS produto)-[pe IS emitido_por]->(e IS emissor)
        <-[av IS avalia]-(a IS agencia_risco)
  WHERE c.id_cliente = 5
    AND p.oferta_ativa = 'S'
    AND av.grau_investimento_normalizado <= 2
  COLUMNS (
    p.id_produto,
    p.nome_produto,
    p.subtipo,
    p.tipo_indexacao,
    p.valor_equivalente,
    e.nome_emissor,
    rp.score_adequacao,
    av.grau_investimento_normalizado
  )
)
ORDER BY score_adequacao DESC, valor_equivalente DESC;

-- F. Emissores e produtos de renda fixa prefixados (PRE), ativos, com vencimento
-- nos proximos dois anos. A ordenacao apresenta os melhores por retorno equivalente.
SELECT *
FROM GRAPH_TABLE (grafo_investimentos
  MATCH (p IS produto)-[pe IS emitido_por]->(e IS emissor)
  WHERE p.tipo = 'RENDA FIXA'
    AND p.tipo_indexacao = 'PRE'
    AND p.oferta_ativa = 'S'
  COLUMNS (
    e.id_emissor,
    e.nome_emissor,
    e.tipo_emissor,
    p.id_produto,
    p.nome_produto,
    p.subtipo,
    p.data_vencimento,
    p.valor_indexacao,
    p.valor_equivalente
  )
)
WHERE data_vencimento >= TRUNC(SYSDATE)
  AND data_vencimento <= ADD_MONTHS(TRUNC(SYSDATE), 24)
ORDER BY valor_equivalente DESC, data_vencimento;
