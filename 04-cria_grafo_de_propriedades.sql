
------------------------------------------------------------------------------
-- 6. SQL PROPERTY GRAPH
------------------------------------------------------------------------------

CREATE PROPERTY GRAPH grafo_investimentos
  VERTEX TABLES (
    cliente KEY (id_cliente) LABEL cliente PROPERTIES ARE ALL COLUMNS,
    perfil_investidor KEY (id_perfil) LABEL perfil_investidor PROPERTIES ARE ALL COLUMNS,
    produto KEY (id_produto) LABEL produto PROPERTIES ARE ALL COLUMNS,
    emissor KEY (id_emissor) LABEL emissor PROPERTIES ARE ALL COLUMNS,
    agencia_risco KEY (id_agencia) LABEL agencia_risco PROPERTIES ARE ALL COLUMNS
  )
  EDGE TABLES (
    cliente_tem_perfil KEY (id_cliente_perfil)
      SOURCE KEY (id_cliente) REFERENCES cliente (id_cliente)
      DESTINATION KEY (id_perfil) REFERENCES perfil_investidor (id_perfil)
      LABEL tem_perfil PROPERTIES ARE ALL COLUMNS,
    cliente_compra_produto KEY (id_compra)
      SOURCE KEY (id_cliente) REFERENCES cliente (id_cliente)
      DESTINATION KEY (id_produto) REFERENCES produto (id_produto)
      LABEL compra PROPERTIES ARE ALL COLUMNS,
    produto_recomendado_perfil KEY (id_recomendacao)
      SOURCE KEY (id_produto) REFERENCES produto (id_produto)
      DESTINATION KEY (id_perfil) REFERENCES perfil_investidor (id_perfil)
      LABEL recomendado_para PROPERTIES ARE ALL COLUMNS,
    produto_emitido_por_emissor KEY (id_produto_emissor)
      SOURCE KEY (id_produto) REFERENCES produto (id_produto)
      DESTINATION KEY (id_emissor) REFERENCES emissor (id_emissor)
      LABEL emitido_por PROPERTIES ARE ALL COLUMNS,
    agencia_avalia_emissor KEY (id_avaliacao)
      SOURCE KEY (id_agencia) REFERENCES agencia_risco (id_agencia)
      DESTINATION KEY (id_emissor) REFERENCES emissor (id_emissor)
      LABEL avalia PROPERTIES ARE ALL COLUMNS
  )
  OPTIONS (ENFORCED MODE);