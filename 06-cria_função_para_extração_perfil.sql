------------------------------------------------------------------------------
-- 8. FUNÇÃO PARA EXTRAÇÃO DE PERFIL DE INVESTIDOR EM FORMATO JSON
------------------------------------------------------------------------------

set long 50000
set pages 0 


create or replace FUNCTION fn_analise_carteira_json (
  p_id_cliente           IN cliente.id_cliente%TYPE
) RETURN CLOB
AUTHID DEFINER
IS
  p_limite_por_emissor number :=250000; 
  l_por_emissor   CLOB;
  l_por_risco     CLOB;
  l_por_tipo      CLOB;
  l_por_subtipo   CLOB;
  l_por_prazo     CLOB;
  l_resultado     CLOB;
  l_cliente_id    cliente.id_cliente%TYPE;
  l_nome_cliente  cliente.nome_cliente%TYPE;
  l_id_perfil     perfil_investidor.id_perfil%TYPE;
  l_nome_perfil   perfil_investidor.nome_perfil%TYPE;
  l_perfil_padrao perfil_investidor.perfil_padrao%TYPE;
  l_limite_renda  perfil_investidor.limite_renda_mensal%TYPE;
  l_limite_patrimonio perfil_investidor.limite_patrimonio%TYPE;
  l_data_atribuicao cliente_tem_perfil.data_atribuicao%TYPE;
BEGIN
  IF p_id_cliente IS NULL THEN
    RAISE_APPLICATION_ERROR(-20001, 'p_id_cliente e obrigatorio.');
  END IF;

  IF p_limite_por_emissor IS NULL OR p_limite_por_emissor <= 0 THEN
    RAISE_APPLICATION_ERROR(
      -20002,
      'p_limite_por_emissor deve ser maior que zero.'
    );
  END IF;

  --------------------------------------------------------------------------
  -- Validacao inicial e identificacao do cliente e de seu perfil cadastrado.
  -- O filtro fica fora do GRAPH_TABLE porque variaveis PL/SQL nao podem ser
  -- referenciadas dentro desse operador.
  --------------------------------------------------------------------------
  BEGIN
    SELECT gt.id_cliente,
           gt.nome_cliente,
           gt.id_perfil,
           gt.nome_perfil,
           gt.perfil_padrao,
           gt.limite_renda_mensal,
           gt.limite_patrimonio,
           gt.data_atribuicao
      INTO l_cliente_id,
           l_nome_cliente,
           l_id_perfil,
           l_nome_perfil,
           l_perfil_padrao,
           l_limite_renda,
           l_limite_patrimonio,
           l_data_atribuicao
      FROM GRAPH_TABLE (grafo_investimentos
        MATCH (c IS cliente)-[tp IS tem_perfil]->(pf IS perfil_investidor)
        COLUMNS (
          c.id_cliente,
          c.nome_cliente,
          pf.id_perfil,
          pf.nome_perfil,
          pf.perfil_padrao,
          pf.limite_renda_mensal,
          pf.limite_patrimonio,
          tp.data_atribuicao
        )
      ) gt
      WHERE gt.id_cliente = p_id_cliente;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(
        -20003,
        'Cliente inexistente ou sem perfil de investidor associado: '
        || p_id_cliente
      );
  END;

  --------------------------------------------------------------------------
  -- Topico 1: concentracao e capacidade remanescente por emissor.
  --------------------------------------------------------------------------
  SELECT JSON_ARRAYAGG(
           JSON_OBJECT(
             'nome_emissor'                 VALUE nome_emissor,
             'valor_total_aplicado'         VALUE valor_total_aplicado,
             'percentual_distribuido'       VALUE percentual_distribuido,
             'percentual_uso_limite'        VALUE percentual_uso_limite,
             'valor_disponivel_para_investir' VALUE valor_disponivel_para_investir
             RETURNING JSON
           )
           ORDER BY valor_total_aplicado DESC, nome_emissor
           RETURNING CLOB
         )
    INTO l_por_emissor
    FROM (
      SELECT nome_emissor,
             valor_total_aplicado,
             ROUND(
               100 * RATIO_TO_REPORT(valor_total_aplicado) OVER (),
               2
             ) AS percentual_distribuido,
             ROUND(
               100 * valor_total_aplicado / p_limite_por_emissor,
               2
             ) AS percentual_uso_limite,
             GREATEST(
               0,
               p_limite_por_emissor - valor_total_aplicado
             ) AS valor_disponivel_para_investir
      FROM (
        SELECT nome_emissor,
               SUM(valor_aplicado) AS valor_total_aplicado
        FROM GRAPH_TABLE (grafo_investimentos
          MATCH (c IS cliente)-[cp IS compra]->(p IS produto)
                -[pe IS emitido_por]->(e IS emissor)
          COLUMNS (
            c.id_cliente,
            e.nome_emissor,
            cp.valor_aplicado
          )
        ) gt
        WHERE gt.id_cliente = p_id_cliente
        GROUP BY nome_emissor
      )
    );

  --------------------------------------------------------------------------
  -- Topico 2: distribuicao pelo pior rating normalizado entre as agencias.
  --------------------------------------------------------------------------
  SELECT JSON_ARRAYAGG(
           JSON_OBJECT(
             'grau_investimento_normalizado' VALUE grau_investimento_normalizado,
             'valor_total_aplicado'           VALUE valor_total_aplicado,
             'percentual_distribuido'         VALUE percentual_distribuido
             RETURNING JSON
           )
           ORDER BY grau_investimento_normalizado
           RETURNING CLOB
         )
    INTO l_por_risco
    FROM (
      SELECT grau_investimento_normalizado,
             valor_total_aplicado,
             ROUND(
               100 * RATIO_TO_REPORT(valor_total_aplicado) OVER (),
               2
             ) AS percentual_distribuido
      FROM (
        SELECT pior_grau_investimento_normalizado AS grau_investimento_normalizado,
               SUM(valor_aplicado) AS valor_total_aplicado
        FROM (
          SELECT id_compra,
                 valor_aplicado,
                 MAX(grau_investimento_normalizado)
                   AS pior_grau_investimento_normalizado
          FROM GRAPH_TABLE (grafo_investimentos
            MATCH (c IS cliente)-[cp IS compra]->(p IS produto)
                  -[pe IS emitido_por]->(e IS emissor)
                  <-[av IS avalia]-(a IS agencia_risco)
            COLUMNS (
              c.id_cliente,
              cp.id_compra,
              cp.valor_aplicado,
              av.grau_investimento_normalizado
            )
          ) gt
          WHERE gt.id_cliente = p_id_cliente
          GROUP BY id_compra, valor_aplicado
        )
        GROUP BY pior_grau_investimento_normalizado
      )
    );

  --------------------------------------------------------------------------
  -- Topico 3: distribuicao por tipo de investimento.
  --------------------------------------------------------------------------
  SELECT JSON_ARRAYAGG(
           JSON_OBJECT(
             'tipo'                    VALUE tipo,
             'valor_total_aplicado'    VALUE valor_total_aplicado,
             'percentual_distribuido'  VALUE percentual_distribuido
             RETURNING JSON
           )
           ORDER BY valor_total_aplicado DESC, tipo
           RETURNING CLOB
         )
    INTO l_por_tipo
    FROM (
      SELECT tipo,
             valor_total_aplicado,
             ROUND(
               100 * RATIO_TO_REPORT(valor_total_aplicado) OVER (),
               2
             ) AS percentual_distribuido
      FROM (
        SELECT tipo, SUM(valor_aplicado) AS valor_total_aplicado
        FROM GRAPH_TABLE (grafo_investimentos
          MATCH (c IS cliente)-[cp IS compra]->(p IS produto)
          COLUMNS (
            c.id_cliente,
            p.tipo,
            cp.valor_aplicado
          )
        ) gt
        WHERE gt.id_cliente = p_id_cliente
        GROUP BY tipo
      )
    );

  --------------------------------------------------------------------------
  -- Topico 4: distribuicao por subtipo de investimento.
  --------------------------------------------------------------------------
  SELECT JSON_ARRAYAGG(
           JSON_OBJECT(
             'subtipo'                 VALUE subtipo,
             'valor_total_aplicado'    VALUE valor_total_aplicado,
             'percentual_distribuido'  VALUE percentual_distribuido
             RETURNING JSON
           )
           ORDER BY valor_total_aplicado DESC, subtipo
           RETURNING CLOB
         )
    INTO l_por_subtipo
    FROM (
      SELECT subtipo,
             valor_total_aplicado,
             ROUND(
               100 * RATIO_TO_REPORT(valor_total_aplicado) OVER (),
               2
             ) AS percentual_distribuido
      FROM (
        SELECT subtipo, SUM(valor_aplicado) AS valor_total_aplicado
        FROM GRAPH_TABLE (grafo_investimentos
          MATCH (c IS cliente)-[cp IS compra]->(p IS produto)
          COLUMNS (
            c.id_cliente,
            p.subtipo,
            cp.valor_aplicado
          )
        ) gt
        WHERE gt.id_cliente = p_id_cliente
        GROUP BY subtipo
      )
    );

  --------------------------------------------------------------------------
  -- Topico 5: distribuicao pelo prazo remanescente na data da compra.
  -- Cada faixa possui 180 dias; a primeira representa prazo inferior a 180.
  --------------------------------------------------------------------------
  SELECT JSON_ARRAYAGG(
           JSON_OBJECT(
             'faixa_prazo'             VALUE faixa_prazo,
             'valor_total_aplicado'    VALUE valor_total_aplicado,
             'percentual_distribuido'  VALUE percentual_distribuido
             RETURNING JSON
           )
           ORDER BY ordem_faixa
           RETURNING CLOB
         )
    INTO l_por_prazo
    FROM (
      SELECT faixa_prazo,
             ordem_faixa,
             valor_total_aplicado,
             ROUND(
               100 * RATIO_TO_REPORT(valor_total_aplicado) OVER (),
               2
             ) AS percentual_distribuido
      FROM (
        SELECT faixa_prazo,
               ordem_faixa,
               SUM(valor_aplicado) AS valor_total_aplicado
        FROM (
          SELECT valor_aplicado,
                 CASE
                   WHEN dias_ate_vencimento < 180  THEN '000 a 179 dias'
                   WHEN dias_ate_vencimento < 360  THEN '180 a 359 dias'
                   WHEN dias_ate_vencimento < 540  THEN '360 a 539 dias'
                   WHEN dias_ate_vencimento < 720  THEN '540 a 719 dias'
                   WHEN dias_ate_vencimento < 900  THEN '720 a 899 dias'
                   WHEN dias_ate_vencimento < 1080 THEN '900 a 1.079 dias'
                   WHEN dias_ate_vencimento < 1260 THEN '1.080 a 1.259 dias'
                   WHEN dias_ate_vencimento < 1440 THEN '1.260 a 1.439 dias'
                   WHEN dias_ate_vencimento < 1620 THEN '1.440 a 1.619 dias'
                   WHEN dias_ate_vencimento < 1800 THEN '1.620 a 1.799 dias'
                   ELSE '1.800 dias ou mais'
                 END AS faixa_prazo,
                 CASE
                   WHEN dias_ate_vencimento < 180  THEN 1
                   WHEN dias_ate_vencimento < 360  THEN 2
                   WHEN dias_ate_vencimento < 540  THEN 3
                   WHEN dias_ate_vencimento < 720  THEN 4
                   WHEN dias_ate_vencimento < 900  THEN 5
                   WHEN dias_ate_vencimento < 1080 THEN 6
                   WHEN dias_ate_vencimento < 1260 THEN 7
                   WHEN dias_ate_vencimento < 1440 THEN 8
                   WHEN dias_ate_vencimento < 1620 THEN 9
                   WHEN dias_ate_vencimento < 1800 THEN 10
                   ELSE 11
                 END AS ordem_faixa
          FROM GRAPH_TABLE (grafo_investimentos
            MATCH (c IS cliente)-[cp IS compra]->(p IS produto)
            COLUMNS (
              c.id_cliente,
              cp.valor_aplicado,
              (p.data_vencimento - cp.data_compra) AS dias_ate_vencimento
            )
          ) gt
          WHERE gt.id_cliente = p_id_cliente
        )
        GROUP BY faixa_prazo, ordem_faixa
      )
    );

  -- JSON_ARRAYAGG retorna NULL quando nao ha compras; o contrato da funcao
  -- devolve arrays vazios para que o formato permaneça previsivel para APIs.
  l_por_emissor := COALESCE(l_por_emissor, '[]');
  l_por_risco   := COALESCE(l_por_risco,   '[]');
  l_por_tipo    := COALESCE(l_por_tipo,    '[]');
  l_por_subtipo := COALESCE(l_por_subtipo, '[]');
  l_por_prazo   := COALESCE(l_por_prazo,   '[]');

  SELECT JSON_SERIALIZE(
           JSON_OBJECT(
             'id_cliente' VALUE l_cliente_id,
             'nome_cliente' VALUE l_nome_cliente,
             'perfil_investidor' VALUE JSON_OBJECT(
               'id_perfil' VALUE l_id_perfil,
               'nome_perfil' VALUE l_nome_perfil,
               'perfil_padrao' VALUE l_perfil_padrao,
               'limite_renda_mensal' VALUE l_limite_renda,
               'limite_patrimonio' VALUE l_limite_patrimonio,
               'data_atribuicao' VALUE l_data_atribuicao
               RETURNING JSON
             ),
             'limite_por_emissor' VALUE p_limite_por_emissor,
             'topicos_analise' VALUE JSON_OBJECT(
               'por_emissor' VALUE l_por_emissor FORMAT JSON,
               'por_grau_investimento' VALUE JSON_OBJECT(
                 'criterio' VALUE 'Pior grau normalizado entre as agencias',
                 'distribuicao' VALUE l_por_risco FORMAT JSON
                 RETURNING JSON
               ),
               'por_tipo_investimento' VALUE l_por_tipo FORMAT JSON,
               'por_subtipo_investimento' VALUE l_por_subtipo FORMAT JSON,
               'por_prazo_vencimento' VALUE l_por_prazo FORMAT JSON
               RETURNING JSON
             )
             RETURNING JSON
           )
           RETURNING CLOB PRETTY
         )
    INTO l_resultado
    FROM dual;

  RETURN l_resultado;
END fn_analise_carteira_json;
/

-- Exemplo de consumo:
SELECT fn_analise_carteira_json(
 p_id_cliente         => 3
) AS carteira_json
FROM dual;

