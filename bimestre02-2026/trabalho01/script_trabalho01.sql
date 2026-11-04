/*
TRABALHO PRÁTICO 01 - GESTÃO DE BANCO DE DADOS
Tema: Sistema de gestão de uma loja de informática

Justificativa e contextualização:
O tema foi escolhido por representar um negócio comum que precisa controlar
clientes, funcionários, produtos, pedidos e os itens vendidos em cada pedido.
O banco permite acompanhar o estoque, registrar vendas e consultar o desempenho
comercial da loja.

Tabelas:
1. clientes: armazena os dados das pessoas que realizam compras.
2. funcionarios: registra os colaboradores responsáveis pelo atendimento.
3. categorias: organiza os produtos por tipo.
4. produtos: mantém os produtos comercializados e suas quantidades em estoque.
5. pedidos: registra cada venda, relacionando cliente e funcionário.
6. itens_pedido: detalha os produtos e quantidades incluídos em cada venda.
*/

-- Remoção das tabelas para permitir executar o script novamente.
DROP TABLE IF EXISTS itens_pedido CASCADE;
DROP TABLE IF EXISTS pedidos CASCADE;
DROP TABLE IF EXISTS produtos CASCADE;
DROP TABLE IF EXISTS categorias CASCADE;
DROP TABLE IF EXISTS funcionarios CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;

-- 1. Clientes: dados cadastrais dos consumidores.
CREATE TABLE clientes (
    id_cliente      SERIAL PRIMARY KEY,
    nome            VARCHAR(100) NOT NULL,
    email           VARCHAR(120) NOT NULL UNIQUE,
    telefone        VARCHAR(20),
    data_cadastro   DATE NOT NULL DEFAULT CURRENT_DATE
);

-- 2. Funcionários: colaboradores que realizam as vendas.
CREATE TABLE funcionarios (
    id_funcionario SERIAL PRIMARY KEY,
    nome           VARCHAR(100) NOT NULL,
    email          VARCHAR(120) NOT NULL UNIQUE,
    cargo          VARCHAR(50) NOT NULL,
    salario        NUMERIC(10,2) NOT NULL CHECK (salario > 0)
);

-- 3. Categorias: classificação dos produtos da loja.
CREATE TABLE categorias (
    id_categoria SERIAL PRIMARY KEY,
    nome         VARCHAR(60) NOT NULL UNIQUE,
    descricao    VARCHAR(200)
);

-- 4. Produtos: catálogo e controle de estoque.
CREATE TABLE produtos (
    id_produto    SERIAL PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    marca         VARCHAR(60) NOT NULL,
    preco         NUMERIC(10,2) NOT NULL CHECK (preco > 0),
    estoque       INTEGER NOT NULL DEFAULT 0 CHECK (estoque >= 0),
    id_categoria  INTEGER NOT NULL REFERENCES categorias(id_categoria)
);

-- 5. Pedidos: cabeçalho de cada venda.
CREATE TABLE pedidos (
    id_pedido       SERIAL PRIMARY KEY,
    data_pedido     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          VARCHAR(20) NOT NULL DEFAULT 'ABERTO'
                    CHECK (status IN ('ABERTO', 'PAGO', 'CANCELADO', 'ENVIADO')),
    id_cliente      INTEGER NOT NULL REFERENCES clientes(id_cliente),
    id_funcionario  INTEGER NOT NULL REFERENCES funcionarios(id_funcionario)
);

-- 6. Itens do pedido: produtos, quantidades e preços praticados na venda.
CREATE TABLE itens_pedido (
    id_item      SERIAL PRIMARY KEY,
    id_pedido    INTEGER NOT NULL REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    id_produto   INTEGER NOT NULL REFERENCES produtos(id_produto),
    quantidade   INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(10,2) NOT NULL CHECK (preco_unitario > 0),
    UNIQUE (id_pedido, id_produto)
);

-- Inserção de clientes (6 registros).
INSERT INTO clientes (nome, email, telefone) VALUES
('Ana Souza', 'ana.souza@email.com', '(35) 99111-1111'),
('Bruno Lima', 'bruno.lima@email.com', '(35) 99222-2222'),
('Carla Mendes', 'carla.mendes@email.com', '(35) 99333-3333'),
('Diego Alves', 'diego.alves@email.com', '(35) 99444-4444'),
('Elaine Costa', 'elaine.costa@email.com', '(35) 99555-5555'),
('Felipe Rocha', 'felipe.rocha@email.com', '(35) 99666-6666');

-- Inserção de funcionários (5 registros).
INSERT INTO funcionarios (nome, email, cargo, salario) VALUES
('Marcos Oliveira', 'marcos@loja.com', 'Vendedor', 2500.00),
('Juliana Ribeiro', 'juliana@loja.com', 'Vendedora', 2650.00),
('Paulo Santos', 'paulo@loja.com', 'Gerente', 4200.00),
('Renata Ferreira', 'renata@loja.com', 'Vendedora', 2550.00),
('Lucas Martins', 'lucas@loja.com', 'Estoquista', 2300.00);

-- Inserção de categorias (5 registros).
INSERT INTO categorias (nome, descricao) VALUES
('Computadores', 'Desktops e notebooks'),
('Perifericos', 'Teclados, mouses e acessórios'),
('Armazenamento', 'HDs, SSDs e pen drives'),
('Monitores', 'Monitores e telas'),
('Componentes', 'Memórias, placas e processadores');

-- Inserção de produtos (8 registros).
INSERT INTO produtos (nome, marca, preco, estoque, id_categoria) VALUES
('Notebook IdeaPad 3', 'Lenovo', 3299.90, 8, 1),
('Desktop Gamer Start', 'Nexus', 4599.00, 4, 1),
('Teclado Mecânico K500', 'Redragon', 249.90, 20, 2),
('Mouse Gamer M60', 'Logitech', 139.90, 25, 2),
('SSD 1TB', 'Kingston', 499.90, 15, 3),
('Monitor 24 polegadas', 'Samsung', 899.90, 10, 4),
('Memória RAM 16GB', 'Corsair', 329.90, 18, 5),
('Processador Ryzen 5', 'AMD', 999.90, 7, 5);

-- Inserção de pedidos (6 registros).
INSERT INTO pedidos (status, id_cliente, id_funcionario) VALUES
('PAGO', 1, 1),
('PAGO', 2, 2),
('ABERTO', 3, 1),
('ENVIADO', 4, 4),
('PAGO', 5, 2),
('CANCELADO', 6, 4);

-- Inserção dos itens de cada pedido (10 registros).
INSERT INTO itens_pedido (id_pedido, id_produto, quantidade, preco_unitario) VALUES
(1, 1, 1, 3299.90),
(1, 4, 1, 139.90),
(2, 3, 2, 249.90),
(2, 5, 1, 499.90),
(3, 6, 1, 899.90),
(4, 2, 1, 4599.00),
(4, 7, 2, 329.90),
(5, 8, 1, 999.90),
(5, 4, 1, 139.90),
(6, 5, 1, 499.90);

-- CONSULTAS SQL

-- 1. JOIN: lista pedidos com nome do cliente e funcionário responsável.
SELECT p.id_pedido, p.data_pedido, p.status,
       c.nome AS cliente, f.nome AS funcionario
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
JOIN funcionarios f ON f.id_funcionario = p.id_funcionario
ORDER BY p.id_pedido;

-- 2. JOIN: detalha os produtos vendidos em cada pedido.
SELECT p.id_pedido, pr.nome AS produto, ip.quantidade,
       ip.preco_unitario,
       (ip.quantidade * ip.preco_unitario) AS subtotal
FROM itens_pedido ip
JOIN pedidos p ON p.id_pedido = ip.id_pedido
JOIN produtos pr ON pr.id_produto = ip.id_produto
ORDER BY p.id_pedido, pr.nome;

-- 3. GROUP BY: total de pedidos por cliente.
SELECT c.nome, COUNT(p.id_pedido) AS quantidade_pedidos
FROM clientes c
LEFT JOIN pedidos p ON p.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nome
ORDER BY quantidade_pedidos DESC;

-- 4. GROUP BY: valor total vendido por funcionário (exclui cancelados).
SELECT f.nome AS funcionario,
       COALESCE(SUM(ip.quantidade * ip.preco_unitario), 0) AS total_vendido
FROM funcionarios f
LEFT JOIN pedidos p ON p.id_funcionario = f.id_funcionario
                   AND p.status <> 'CANCELADO'
LEFT JOIN itens_pedido ip ON ip.id_pedido = p.id_pedido
GROUP BY f.id_funcionario, f.nome
ORDER BY total_vendido DESC;

-- 5. Filtro condicional: produtos com preço acima de R$ 300 e estoque positivo.
SELECT nome, marca, preco, estoque
FROM produtos
WHERE preco > 300 AND estoque > 0
ORDER BY preco DESC;

-- 6. Filtro condicional: pedidos pagos ou enviados.
SELECT id_pedido, data_pedido, status, id_cliente
FROM pedidos
WHERE status IN ('PAGO', 'ENVIADO')
ORDER BY data_pedido DESC;

-- 7. GROUP BY: quantidade de produtos cadastrados em cada categoria.
SELECT c.nome AS categoria, COUNT(pr.id_produto) AS total_produtos
FROM categorias c
LEFT JOIN produtos pr ON pr.id_categoria = c.id_categoria
GROUP BY c.id_categoria, c.nome
ORDER BY c.nome;

-- 8. Consulta de valor por pedido.
SELECT p.id_pedido, p.status,
       COALESCE(SUM(ip.quantidade * ip.preco_unitario), 0) AS valor_pedido
FROM pedidos p
LEFT JOIN itens_pedido ip ON ip.id_pedido = p.id_pedido
GROUP BY p.id_pedido, p.status
ORDER BY p.id_pedido;
