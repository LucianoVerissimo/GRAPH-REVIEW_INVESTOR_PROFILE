------------------------------------------------------------------------------
-- 1. TABELAS DE VERTICES
------------------------------------------------------------------------------

CREATE TABLE cliente (
  id_cliente           NUMBER(10)    CONSTRAINT pk_cliente PRIMARY KEY,
  nome_cliente         VARCHAR2(100) NOT NULL,
  idade_cliente        NUMBER(3)     NOT NULL,
  tipo_cliente         VARCHAR2(2)   NOT NULL,
  classe_cliente       CHAR(1)       NOT NULL,
  cliente_normalizado  NUMBER(1)     NOT NULL,
  CONSTRAINT ck_cliente_idade CHECK (idade_cliente BETWEEN 18 AND 120),
  CONSTRAINT ck_cliente_tipo CHECK (tipo_cliente IN ('PF', 'PJ')),
  CONSTRAINT ck_cliente_classe CHECK (classe_cliente IN ('A', 'B', 'C', 'D', 'E')),
  CONSTRAINT ck_cliente_classe_norm CHECK (
    (classe_cliente = 'A' AND cliente_normalizado = 1) OR
    (classe_cliente = 'B' AND cliente_normalizado = 2) OR
    (classe_cliente = 'C' AND cliente_normalizado = 3) OR
    (classe_cliente = 'D' AND cliente_normalizado = 4) OR
    (classe_cliente = 'E' AND cliente_normalizado = 5)
  )
);

CREATE TABLE perfil_investidor (
  id_perfil             NUMBER(10)    CONSTRAINT pk_perfil_investidor PRIMARY KEY,
  nome_perfil           VARCHAR2(100) NOT NULL,
  limite_renda_mensal   NUMBER(14,2)  NOT NULL,
  limite_patrimonio     NUMBER(16,2)  NOT NULL,
  perfil_padrao         VARCHAR2(15)  NOT NULL,
  CONSTRAINT uq_perfil_nome UNIQUE (nome_perfil),
  CONSTRAINT ck_perfil_padrao CHECK (perfil_padrao IN ('CONSERVADOR', 'MODERADO', 'ARROJADO')),
  CONSTRAINT ck_perfil_limites CHECK (limite_renda_mensal > 0 AND limite_patrimonio > 0)
);

CREATE TABLE emissor (
  id_emissor            NUMBER(10)    CONSTRAINT pk_emissor PRIMARY KEY,
  nome_emissor          VARCHAR2(150) NOT NULL,
  tipo_emissor          VARCHAR2(12)  NOT NULL,
  CONSTRAINT uq_emissor_nome UNIQUE (nome_emissor),
  CONSTRAINT ck_emissor_tipo CHECK (tipo_emissor IN ('BANCO', 'EMPRESA', 'CORRETORA'))
);

CREATE TABLE agencia_risco (
  id_agencia            NUMBER(10)   CONSTRAINT pk_agencia_risco PRIMARY KEY,
  nome_agencia          VARCHAR2(80) NOT NULL,
  CONSTRAINT uq_agencia_nome UNIQUE (nome_agencia)
);

CREATE TABLE produto (
  id_produto            NUMBER(10)    CONSTRAINT pk_produto PRIMARY KEY,
  nome_produto          VARCHAR2(150) NOT NULL,
  oferta_ativa          CHAR(1)       NOT NULL,
  data_vencimento       DATE          NOT NULL,
  tipo                  VARCHAR2(30)  NOT NULL,
  subtipo               VARCHAR2(30)  NOT NULL,
  tipo_imposto          VARCHAR2(12)  NOT NULL,
  tipo_indexacao        VARCHAR2(6)   NOT NULL,
  valor_indexacao       NUMBER(9,4)   NOT NULL,
  valor_equivalente     NUMBER(9,4)   NOT NULL,
  CONSTRAINT ck_produto_oferta CHECK (oferta_ativa IN ('S', 'N')),
  CONSTRAINT ck_produto_tipo CHECK (tipo IN ('RENDA FIXA', 'FUNDO INVESTIMENTO')),
  CONSTRAINT ck_produto_subtipo CHECK (
    subtipo IN ('CDB', 'LCI', 'LCA', 'LCD',
                'FUNDO RF', 'FUNDO MULTIMERCADO', 'FUNDO ACOES')
  ),
  CONSTRAINT ck_produto_imposto CHECK (tipo_imposto IN ('ISENTO', 'REGRESSIVO')),
  CONSTRAINT ck_produto_indexacao CHECK (tipo_indexacao IN ('CDI', 'IPCA', 'PRE')),
  CONSTRAINT ck_produto_valores CHECK (valor_indexacao > 0 AND valor_equivalente > 0)
);

------------------------------------------------------------------------------
-- 2. TABELAS DE ARESTAS
------------------------------------------------------------------------------

-- CLIENTE -> PERFIL_INVESTIDOR
CREATE TABLE cliente_tem_perfil (
  id_cliente_perfil     NUMBER(10) CONSTRAINT pk_cliente_tem_perfil PRIMARY KEY,
  id_cliente            NUMBER(10) NOT NULL,
  id_perfil             NUMBER(10) NOT NULL,
  data_atribuicao       DATE       NOT NULL,
  CONSTRAINT uq_cliente_perfil UNIQUE (id_cliente),
  CONSTRAINT fk_ctp_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
  CONSTRAINT fk_ctp_perfil FOREIGN KEY (id_perfil) REFERENCES perfil_investidor (id_perfil)
);

-- CLIENTE -> PRODUTO
CREATE TABLE cliente_compra_produto (
  id_compra             NUMBER(10)   CONSTRAINT pk_cliente_compra_produto PRIMARY KEY,
  id_cliente            NUMBER(10)   NOT NULL,
  id_produto            NUMBER(10)   NOT NULL,
  data_compra           DATE         NOT NULL,
  quantidade            NUMBER(12,4) NOT NULL,
  valor_aplicado        NUMBER(16,2) NOT NULL,
  CONSTRAINT fk_ccp_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente),
  CONSTRAINT fk_ccp_produto FOREIGN KEY (id_produto) REFERENCES produto (id_produto),
  CONSTRAINT ck_ccp_valores CHECK (quantidade > 0 AND valor_aplicado > 0)
);

-- PRODUTO -> PERFIL_INVESTIDOR
CREATE TABLE produto_recomendado_perfil (
  id_recomendacao       NUMBER(10)   CONSTRAINT pk_produto_recomendado_perfil PRIMARY KEY,
  id_produto            NUMBER(10)   NOT NULL,
  id_perfil             NUMBER(10)   NOT NULL,
  score_adequacao        NUMBER(5,2)  NOT NULL,
  justificativa         VARCHAR2(300) NOT NULL,
  CONSTRAINT uq_produto_perfil UNIQUE (id_produto, id_perfil),
  CONSTRAINT fk_prp_produto FOREIGN KEY (id_produto) REFERENCES produto (id_produto),
  CONSTRAINT fk_prp_perfil FOREIGN KEY (id_perfil) REFERENCES perfil_investidor (id_perfil),
  CONSTRAINT ck_prp_score CHECK (score_adequacao > 70 AND score_adequacao <= 100)
);

-- PRODUTO -> EMISSOR: produto emitido por emissor
CREATE TABLE produto_emitido_por_emissor (
  id_produto_emissor    NUMBER(10) CONSTRAINT pk_produto_emitido_por_emissor PRIMARY KEY,
  id_produto            NUMBER(10) NOT NULL,
  id_emissor            NUMBER(10) NOT NULL,
  CONSTRAINT uq_produto_emissor UNIQUE (id_produto),
  CONSTRAINT fk_pepe_produto FOREIGN KEY (id_produto) REFERENCES produto (id_produto),
  CONSTRAINT fk_pepe_emissor FOREIGN KEY (id_emissor) REFERENCES emissor (id_emissor)
);

-- AGENCIA_RISCO -> EMISSOR. O grau normalizado vai de 1 (melhor) a 5 (pior).
CREATE TABLE agencia_avalia_emissor (
  id_avaliacao                    NUMBER(10)   CONSTRAINT pk_agencia_avalia_emissor PRIMARY KEY,
  id_agencia                      NUMBER(10)   NOT NULL,
  id_emissor                      NUMBER(10)   NOT NULL,
  grau_investimento_agencia       VARCHAR2(12),
  grau_especulacao_agencia        VARCHAR2(12),
  grau_investimento_normalizado   NUMBER(1)    NOT NULL,
  grau_especulacao_normalizado    NUMBER(1)    NOT NULL,
  data_avaliacao                  DATE         NOT NULL,
  CONSTRAINT uq_agencia_emissor UNIQUE (id_agencia, id_emissor),
  CONSTRAINT fk_aae_agencia FOREIGN KEY (id_agencia) REFERENCES agencia_risco (id_agencia),
  CONSTRAINT fk_aae_emissor FOREIGN KEY (id_emissor) REFERENCES emissor (id_emissor),
  CONSTRAINT ck_aae_invest_norm CHECK (grau_investimento_normalizado BETWEEN 1 AND 5),
  CONSTRAINT ck_aae_espec_norm CHECK (grau_especulacao_normalizado BETWEEN 1 AND 5)
);


------------------------------------------------------------------------------
-- 3. INDICES PARA JUNCOES RELACIONAIS E PADROES DO GRAFO
------------------------------------------------------------------------------

CREATE INDEX ix_ctp_perfil ON cliente_tem_perfil (id_perfil);
CREATE INDEX ix_ccp_cliente ON cliente_compra_produto (id_cliente);
CREATE INDEX ix_ccp_produto ON cliente_compra_produto (id_produto);
CREATE INDEX ix_prp_perfil ON produto_recomendado_perfil (id_perfil);
CREATE INDEX ix_pepe_emissor ON produto_emitido_por_emissor (id_emissor);
CREATE INDEX ix_aae_emissor ON agencia_avalia_emissor (id_emissor);
CREATE INDEX ix_cliente_classe ON cliente (classe_cliente, cliente_normalizado);
CREATE INDEX ix_produto_filtro ON produto (oferta_ativa, subtipo, tipo_indexacao, data_vencimento);


------------------------------------------------------------------------------
-- 4. METADADOS SEMANTICOS PARA NL2SQL E DICIONARIO DE DADOS
------------------------------------------------------------------------------

COMMENT ON TABLE cliente IS 'Vertice Cliente. Pessoa fisica ou juridica que possui perfil de investidor e pode comprar produtos de renda fixa.';
COMMENT ON COLUMN cliente.id_cliente IS 'Identificador unico do cliente; chave primaria do vertice Cliente.';
COMMENT ON COLUMN cliente.nome_cliente IS 'Nome da pessoa fisica ou razao social da pessoa juridica.';
COMMENT ON COLUMN cliente.idade_cliente IS 'Idade do cliente em anos; aplicavel principalmente a pessoa fisica.';
COMMENT ON COLUMN cliente.tipo_cliente IS 'Natureza do cliente: PF para pessoa fisica; PJ para pessoa juridica.';
COMMENT ON COLUMN cliente.classe_cliente IS 'Segmentacao comercial do cliente: A, B, C, D ou E. Nao representa perfil de risco.';
COMMENT ON COLUMN cliente.cliente_normalizado IS 'Codigo ordinal da classe comercial: A=1, B=2, C=3, D=4, E=5.';

COMMENT ON TABLE perfil_investidor IS 'Vertice Perfil de Investidor. Define tolerancia a risco e limites de capacidade financeira; nao infere perfil apenas por renda ou patrimonio.';
COMMENT ON COLUMN perfil_investidor.id_perfil IS 'Identificador unico do perfil de investidor; chave primaria do vertice Perfil de Investidor.';
COMMENT ON COLUMN perfil_investidor.nome_perfil IS 'Nome interno do perfil, combinando faixa financeira e estrategia, por exemplo PF_CONSERVADOR_10K.';
COMMENT ON COLUMN perfil_investidor.limite_renda_mensal IS 'Limite superior da faixa de renda mensal do perfil, em reais brasileiros.';
COMMENT ON COLUMN perfil_investidor.limite_patrimonio IS 'Limite superior da faixa de patrimonio financeiro do perfil, em reais brasileiros.';
COMMENT ON COLUMN perfil_investidor.perfil_padrao IS 'Tolerancia a risco e objetivo de investimento: CONSERVADOR, MODERADO ou ARROJADO. Independente de renda e patrimonio.';

COMMENT ON TABLE produto IS 'Vertice Produto. Titulo de renda fixa ou fundo de investimento ofertado, com indexacao, tributacao, horizonte e retorno anual liquido equivalente.';
COMMENT ON COLUMN produto.id_produto IS 'Identificador unico do produto; chave primaria do vertice Produto.';
COMMENT ON COLUMN produto.nome_produto IS 'Nome comercial do titulo de renda fixa.';
COMMENT ON COLUMN produto.oferta_ativa IS 'Indicador de disponibilidade comercial: S para produto ofertado e N para oferta encerrada.';
COMMENT ON COLUMN produto.data_vencimento IS 'Data de vencimento do titulo. O retorno normalizado considera manter o investimento ate esta data.';
COMMENT ON COLUMN produto.tipo IS 'Classe ampla do investimento: RENDA FIXA ou FUNDO INVESTIMENTO.';
COMMENT ON COLUMN produto.subtipo IS 'Modalidade do produto: CDB, LCI, LCA, LCD, FUNDO RF, FUNDO MULTIMERCADO ou FUNDO ACOES.';
COMMENT ON COLUMN produto.tipo_imposto IS 'Regra tributaria do rendimento: REGRESSIVO para IR regressivo de renda fixa ou ISENTO para produto isento de IR.';
COMMENT ON COLUMN produto.tipo_indexacao IS 'Indexador de retorno: CDI para percentual do CDI, IPCA para IPCA mais spread, PRE para taxa prefixada.';
COMMENT ON COLUMN produto.valor_indexacao IS 'Valor percentual da indexacao: 102 significa 102 por cento do CDI; 7.25 significa IPCA mais 7.25 por cento ao ano; 13.15 significa 13.15 por cento prefixado ao ano.';
COMMENT ON COLUMN produto.valor_equivalente IS 'Retorno anual liquido equivalente, em percentual, calculado por FN_RETORNO_EQUIVALENTE com inflacao, CDI, prazo ate vencimento e IR ou isencao. Usar para comparar produtos de indexadores diferentes.';

COMMENT ON TABLE emissor IS 'Vertice Emissor. Instituicao responsavel pela emissao do produto de renda fixa.';
COMMENT ON COLUMN emissor.id_emissor IS 'Identificador unico do emissor; chave primaria do vertice Emissor.';
COMMENT ON COLUMN emissor.nome_emissor IS 'Nome da instituicao emissora, como banco, empresa ou corretora.';
COMMENT ON COLUMN emissor.tipo_emissor IS 'Categoria do emissor: BANCO, EMPRESA ou CORRETORA.';

COMMENT ON TABLE agencia_risco IS 'Vertice Agencia de Risco. Agencia ou classificacao interna que avalia o risco de credito de emissores.';
COMMENT ON COLUMN agencia_risco.id_agencia IS 'Identificador unico da agencia de risco; chave primaria do vertice Agencia de Risco.';
COMMENT ON COLUMN agencia_risco.nome_agencia IS 'Nome da agencia classificadora, por exemplo MOODYS, FITCH, SP ou classificacao interna.';

COMMENT ON TABLE cliente_tem_perfil IS 'Aresta Cliente para Perfil de Investidor. Cada linha informa o perfil atualmente atribuido a um cliente.';
COMMENT ON COLUMN cliente_tem_perfil.id_cliente_perfil IS 'Identificador unico da aresta TEM_PERFIL.';
COMMENT ON COLUMN cliente_tem_perfil.id_cliente IS 'Vertice de origem: cliente que possui o perfil.';
COMMENT ON COLUMN cliente_tem_perfil.id_perfil IS 'Vertice de destino: perfil de investidor atribuido ao cliente.';
COMMENT ON COLUMN cliente_tem_perfil.data_atribuicao IS 'Data em que o perfil foi atribuido ao cliente.';

COMMENT ON TABLE cliente_compra_produto IS 'Aresta Cliente para Produto. Cada linha representa uma compra ou aplicacao efetuada por um cliente em um produto.';
COMMENT ON COLUMN cliente_compra_produto.id_compra IS 'Identificador unico da aresta COMPRA.';
COMMENT ON COLUMN cliente_compra_produto.id_cliente IS 'Vertice de origem: cliente comprador ou investidor.';
COMMENT ON COLUMN cliente_compra_produto.id_produto IS 'Vertice de destino: produto adquirido pelo cliente.';
COMMENT ON COLUMN cliente_compra_produto.data_compra IS 'Data da aplicacao ou compra do produto.';
COMMENT ON COLUMN cliente_compra_produto.quantidade IS 'Quantidade de unidades, cotas ou titulos adquiridos.';
COMMENT ON COLUMN cliente_compra_produto.valor_aplicado IS 'Valor financeiro aplicado na compra, em reais brasileiros.';

COMMENT ON TABLE produto_recomendado_perfil IS 'Aresta Produto para Perfil de Investidor. Representa que um produto e recomendado ou adequado para um perfil.';
COMMENT ON COLUMN produto_recomendado_perfil.id_recomendacao IS 'Identificador unico da aresta RECOMENDADO_PARA.';
COMMENT ON COLUMN produto_recomendado_perfil.id_produto IS 'Vertice de origem: produto recomendado.';
COMMENT ON COLUMN produto_recomendado_perfil.id_perfil IS 'Vertice de destino: perfil de investidor para o qual o produto e recomendado.';
COMMENT ON COLUMN produto_recomendado_perfil.score_adequacao IS 'Pontuacao de adequacao do produto ao perfil, acima de 70 e ate 100; maior valor indica maior aderencia. Arestas de recomendacao nao sao criadas para score menor ou igual a 70.';
COMMENT ON COLUMN produto_recomendado_perfil.justificativa IS 'Explicacao textual da recomendacao, por exemplo isencao, indexacao ou risco do emissor.';

COMMENT ON TABLE produto_emitido_por_emissor IS 'Aresta Produto para Emissor. Representa que o produto e emitido pelo emissor; direcao Produto -> Emissor.';
COMMENT ON COLUMN produto_emitido_por_emissor.id_produto_emissor IS 'Identificador unico da aresta EMITIDO_POR.';
COMMENT ON COLUMN produto_emitido_por_emissor.id_produto IS 'Vertice de origem: produto de renda fixa emitido.';
COMMENT ON COLUMN produto_emitido_por_emissor.id_emissor IS 'Vertice de destino: instituicao emissora do produto.';

COMMENT ON TABLE agencia_avalia_emissor IS 'Aresta Agencia de Risco para Emissor. Registra a avaliacao de risco de credito de um emissor por uma agencia; direcao Agencia -> Emissor.';
COMMENT ON COLUMN agencia_avalia_emissor.id_avaliacao IS 'Identificador unico da aresta AVALIA.';
COMMENT ON COLUMN agencia_avalia_emissor.id_agencia IS 'Vertice de origem: agencia que emitiu a classificacao de risco.';
COMMENT ON COLUMN agencia_avalia_emissor.id_emissor IS 'Vertice de destino: emissor avaliado pela agencia.';
COMMENT ON COLUMN agencia_avalia_emissor.grau_investimento_agencia IS 'Nota original de grau de investimento publicada pela agencia, por exemplo AAA, AA, A ou BBB. N/A se a nota for especulativa.';
COMMENT ON COLUMN agencia_avalia_emissor.grau_especulacao_agencia IS 'Nota original especulativa publicada pela agencia, por exemplo BB ou B. N/A se a nota for grau de investimento.';
COMMENT ON COLUMN agencia_avalia_emissor.grau_investimento_normalizado IS 'Escala interna comparavel entre agencias: 1 e melhor risco de credito e 5 e pior risco trabalhado.';
COMMENT ON COLUMN agencia_avalia_emissor.grau_especulacao_normalizado IS 'Escala interna comparavel entre agencias para risco especulativo: 1 e melhor e 5 e pior risco trabalhado.';
COMMENT ON COLUMN agencia_avalia_emissor.data_avaliacao IS 'Data de referencia da classificacao de risco.';


