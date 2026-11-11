/*
TRABALHO 02 - FUNCTIONS NO POSTGRESQL
Tema: Sistema de Gestão de uma Loja de Informática
Aluno: Túlio Araújo Dutra
RA: 007669

Este arquivo é uma continuação do Trabalho 01.
As funções utilizam as tabelas:
clientes, funcionarios, categorias, produtos, pedidos e itens_pedido.

ATENÇÃO:
Execute este arquivo depois de executar o script_trabalho01.sql,
pois as funções dependem das tabelas criadas no Trabalho 01.
*/

-- =========================================================
-- FUNCTION 1: CALCULAR O VALOR TOTAL DE UM PEDIDO
-- Recebe o ID do pedido e retorna a soma dos seus itens.
-- Se o pedido não possuir itens, retorna 0.
-- =========================================================

CREATE OR REPLACE FUNCTION fn_total_pedido(p_id_pedido INTEGER)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(10,2);
BEGIN
    SELECT COALESCE(SUM(quantidade * preco_unitario), 0)
      INTO v_total
      FROM itens_pedido
     WHERE id_pedido = p_id_pedido;

    RETURN v_total;
END;
$$;


-- =========================================================
-- FUNCTION 2: CONSULTAR A SITUAÇÃO DO ESTOQUE DE UM PRODUTO
-- Informa se o produto está sem estoque, com estoque baixo
-- (até 5 unidades) ou com estoque disponível.
-- =========================================================

CREATE OR REPLACE FUNCTION fn_situacao_estoque(p_id_produto INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_nome_produto VARCHAR(100);
    v_estoque INTEGER;
BEGIN
    SELECT nome, estoque
      INTO v_nome_produto, v_estoque
      FROM produtos
     WHERE id_produto = p_id_produto;

    IF NOT FOUND THEN
        RETURN 'Produto não encontrado!';
    END IF;

    IF v_estoque = 0 THEN
        RETURN v_nome_produto || ' - Sem estoque';
    ELSIF v_estoque <= 5 THEN
        RETURN v_nome_produto || ' - Estoque baixo: '
               || v_estoque || ' unidade(s)';
    ELSE
        RETURN v_nome_produto || ' - Estoque disponível: '
               || v_estoque || ' unidade(s)';
    END IF;
END;
$$;


-- =========================================================
-- FUNCTION 3: FINALIZAR UM PEDIDO
-- Confere se o pedido existe, se está ABERTO, se possui itens
-- e se há estoque suficiente. Depois baixa o estoque e altera
-- o status do pedido para PAGO.
-- =========================================================

CREATE OR REPLACE FUNCTION fn_finalizar_pedido(p_id_pedido INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_item RECORD;
BEGIN
    -- Verifica se o pedido existe e obtém seu status.
    SELECT status
      INTO v_status
      FROM pedidos
     WHERE id_pedido = p_id_pedido;

    IF NOT FOUND THEN
        RETURN 'Pedido não encontrado!';
    END IF;

    IF v_status <> 'ABERTO' THEN
        RETURN 'Não é possível finalizar: o pedido não está ABERTO.';
    END IF;

    -- Verifica se o pedido possui pelo menos um item.
    IF NOT EXISTS (
        SELECT 1
          FROM itens_pedido
         WHERE id_pedido = p_id_pedido
    ) THEN
        RETURN 'Não é possível finalizar: o pedido não possui itens.';
    END IF;

    -- Primeiro confere o estoque de todos os produtos.
    -- Nenhuma baixa é feita antes de todas as verificações passarem.
    FOR v_item IN
        SELECT ip.id_produto,
               ip.quantidade,
               pr.nome,
               pr.estoque
          FROM itens_pedido ip
          JOIN produtos pr ON pr.id_produto = ip.id_produto
         WHERE ip.id_pedido = p_id_pedido
    LOOP
        IF v_item.estoque < v_item.quantidade THEN
            RETURN 'Estoque insuficiente para o produto: '
                   || v_item.nome;
        END IF;
    END LOOP;

    -- Com o estoque validado, realiza a baixa dos produtos.
    UPDATE produtos pr
       SET estoque = pr.estoque - itens.quantidade_total
      FROM (
            SELECT id_produto, SUM(quantidade) AS quantidade_total
              FROM itens_pedido
             WHERE id_pedido = p_id_pedido
             GROUP BY id_produto
           ) AS itens
     WHERE pr.id_produto = itens.id_produto;

    -- Atualiza a situação do pedido.
    UPDATE pedidos
       SET status = 'PAGO'
     WHERE id_pedido = p_id_pedido;

    RETURN 'Pedido finalizado com sucesso! Estoque atualizado e status alterado para PAGO.';
END;
$$;


-- =========================================================
-- TESTES DAS FUNCTIONS
-- Execute os SELECTs abaixo para verificar os resultados.
-- =========================================================

-- Function 1: valor total do pedido.
SELECT fn_total_pedido(1) AS total_pedido_1;

-- Function 2: situação do estoque de um produto.
SELECT fn_situacao_estoque(1) AS situacao_estoque;
SELECT fn_situacao_estoque(99) AS produto_inexistente;

-- Function 3: finalizar pedido.
-- No script do Trabalho 01, o pedido 3 está ABERTO e possui item.
-- A execução altera o pedido 3 para PAGO e reduz o estoque.
SELECT fn_finalizar_pedido(3) AS resultado_finalizacao;

-- Conferir o status do pedido após a finalização.
SELECT id_pedido, status
  FROM pedidos
 WHERE id_pedido = 3;

-- Conferir o estoque dos produtos após a finalização.
SELECT id_produto, nome, estoque
  FROM produtos
 ORDER BY id_produto;

-- Conferir o total do pedido após a finalização.
SELECT id_pedido, fn_total_pedido(id_pedido) AS valor_total
  FROM pedidos
 WHERE id_pedido = 3;
