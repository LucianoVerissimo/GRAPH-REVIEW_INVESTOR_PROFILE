------------------------------------------------------------------------------
-- 1. LIMPEZA PARA REDEPLOY
-- Remove exclusivamente os objetos deste exemplo no schema conectado.
------------------------------------------------------------------------------

DROP PROPERTY GRAPH IF EXISTS grafo_investimentos;

DROP TABLE IF EXISTS agencia_avalia_emissor CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS produto_emitido_por_emissor CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS produto_recomendado_perfil CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS cliente_compra_produto CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS cliente_tem_perfil CASCADE CONSTRAINTS PURGE;

DROP TABLE IF EXISTS agencia_risco CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS emissor CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS produto CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS perfil_investidor CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS cliente CASCADE CONSTRAINTS PURGE;

DROP FUNCTION IF EXISTS fn_retorno_equivalente;
