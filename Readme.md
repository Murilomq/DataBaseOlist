# Relatorio, restauração do banco de dados Olist.


# 2. Criar um usuário para o pessoal de Business Intelligence

```sql
CREATE USER 'userBi'@'%' IDENTIFIED BY 'admin';

GRANT SELECT ON olist.order TO 'userBi'@'%';
GRANT SELECT ON olist.product TO 'userBi'@'%';
GRANT SELECT ON olist.customer TO 'userBi'@'%';
GRANT SELECT ON olist.order_payment TO 'userBi'@'%';
GRANT SELECT ON olist.seller TO 'userBi'@'%';
GRANT SELECT ON olist.geo_location TO 'userBi'@'%';

REVOKE INSERT, UPDATE, DELETE ON olist.order FROM 'userBi'@'%';
REVOKE INSERT, UPDATE, DELETE ON olist.product FROM 'userBi'@'%';
REVOKE INSERT, UPDATE, DELETE ON olist.customer FROM 'userBi'@'%';
REVOKE INSERT, UPDATE, DELETE ON olist.order_payment FROM 'userBi'@'%';
REVOKE INSERT, UPDATE, DELETE ON olist.seller FROM 'userBi'@'%';
REVOKE INSERT, UPDATE, DELETE ON olist.geo_location FROM 'userBi'@'%';
```

# 3. Chaves e Restrições

## Remoção de  duplicatas.

```sql
CREATE TABLE customer2 LIKE customer;

INSERT INTO customer2
SELECT DISTINCT * FROM customer;

DROP TABLE customer;

RENAME TABLE customer2 TO customer;


CREATE TABLE order2 LIKE `order`;

INSERT INTO order2
SELECT DISTINCT * FROM `order`;

DROP TABLE `order`;

RENAME TABLE order2 TO `order`;


CREATE TABLE product2 LIKE product;

INSERT INTO product2
SELECT DISTINCT * FROM product;

DROP TABLE product;

RENAME TABLE product2 TO product;


CREATE TABLE olist.order_payment2 LIKE olist.order_payment;

INSERT INTO olist.order_payment2
SELECT DISTINCT * FROM olist.order_payment;

DROP TABLE olist.order_payment;

RENAME TABLE olist.order_payment2 TO olist.order_payment;


CREATE TABLE seller2 LIKE seller;

INSERT INTO seller2
SELECT DISTINCT * FROM seller;

DROP TABLE seller;

RENAME TABLE seller2 TO seller;


CREATE TABLE order_review2 LIKE order_review;

INSERT INTO order_review2
SELECT DISTINCT * FROM order_review;

DROP TABLE order_review;

RENAME TABLE order_review2 TO order_review;

CREATE TABLE geo_location2 LIKE geo_location;

INSERT INTO geo_location2
SELECT DISTINCT * FROM geo_location;

DROP TABLE geo_location;

RENAME TABLE geo_location2 TO geo_location;


CREATE TABLE order_item2 LIKE order_item;

INSERT INTO order_item2
SELECT DISTINCT * FROM order_item;

DROP TABLE order_item;

RENAME TABLE order_item2 TO order_item;


CREATE TABLE order_payment2 LIKE order_payment;

INSERT INTO order_payment2
SELECT DISTINCT * FROM order_payment;

DROP TABLE order_payment;

RENAME TABLE order_payment2 TO order_payment;


CREATE TABLE order_review2 LIKE order_review;

INSERT INTO order_review2
SELECT DISTINCT * FROM order_review;

DROP TABLE order_review;

RENAME TABLE order_review2 TO order_review;


DELETE FROM order_review2
WHERE review_id IN (
    SELECT review_id
    FROM order_review
    GROUP BY review_id
    HAVING COUNT(*) > 1
);
```

## Criação da chaves primarias e estrangeiras.

```sql

ALTER TABLE customer ADD PRIMARY KEY (customer_id);

ALTER TABLE `order` ADD PRIMARY key (order_id);

ALTER TABLE seller ADD PRIMARY KEY (seller_id);

ALTER TABLE product ADD PRIMARY KEY (product_id);

ALTER TABLE order_item
    ADD CONSTRAINT pk_order_item PRIMARY KEY (order_id, order_item_id);

ALTER TABLE order_payment
    ADD CONSTRAINT pk_order_payment PRIMARY KEY (order_id, payment_sequential);

CREATE INDEX idx_geo_location_zip_code_prefix ON geo_location(geolocation_zip_code_prefix);

alter table geo_location
    add column geolocation_id int auto_increment primary key;

ALTER TABLE order_review ADD PRIMARY KEY (review_id);


-- chave estrangeira

ALTER TABLE order_item ADD CONSTRAINT fk_order_item_order FOREIGN KEY (order_id)
    REFERENCES `order`(order_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE order_item ADD CONSTRAINT fk_order_item_product FOREIGN KEY (product_id)
REFERENCES product(product_id) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE order_item ADD CONSTRAINT fk_order_item_seller FOREIGN KEY (seller_id)
    REFERENCES seller(seller_id) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE seller ADD CONSTRAINT fk_seller_geo FOREIGN KEY (seller_zip_code_prefix)
REFERENCES geo_location(geolocation_zip_code_prefix) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE customer ADD CONSTRAINT fk_customer_geo FOREIGN KEY (customer_zip_code_prefix)
REFERENCES geo_location(geolocation_zip_code_prefix) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE order_review ADD CONSTRAINT fk_order_review_order FOREIGN KEY (order_id)
    REFERENCES `order`(order_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `order` ADD CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
    REFERENCES customer(customer_id) ON DELETE CASCADE ON UPDATE CASCADE;

```
```sql
# 4. Consultas SQL Avançadas

## 4.1 Criar uma consulta que exiba o total de vendas por vendedor (seller).

  CREATE VIEW total_vendas_vendedor AS
SELECT
    seller_id,
    SUM(price) AS total_vendas
FROM
    order_item
GROUP BY
    seller_id
ORDER BY
    total_vendas DESC;

  
## 4.2 Identificar os clientes que mais compraram na plataforma (top 10), por período.

DELIMITER $$

CREATE PROCEDURE top10_clientes(IN data_inicio DATE, IN data_fim DATE)
BEGIN
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    SUM(oi.price) AS total_gasto
FROM
    `order` o
        JOIN
    customer c ON o.customer_id = c.customer_id
        JOIN
    order_item oi ON o.order_id = oi.order_id
WHERE
    o.order_purchase_timestamp BETWEEN data_inicio AND data_fim
GROUP BY
    c.customer_unique_id
ORDER BY
    total_gasto DESC, total_pedidos DESC
    LIMIT 10;
END$$

DELIMITER ;
  
## 4.3 Calcular a média das avaliações por loja (seller).

  CREATE VIEW media_avaliacoes_loja AS
SELECT
    oi.seller_id,
    AVG(r.review_score) AS media_avaliacoes
FROM
    order_review r
        JOIN
    order_item oi ON r.order_id = oi.order_id
GROUP BY
    oi.seller_id
ORDER BY
    media_avaliacoes DESC;
  
## 4.4 Consulta que retorna todos os pedidos realizados entre duas datas

DELIMITER $$

CREATE PROCEDURE pedidos_periodo(IN data_inicio DATE, IN data_fim DATE)
BEGIN
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    SUM(p.payment_value) AS total_pago
FROM
    `order` o
        JOIN
    customer c ON o.customer_id = c.customer_id
        LEFT JOIN
    order_payment p ON o.order_id = p.order_id
WHERE
    o.order_purchase_timestamp BETWEEN data_inicio AND data_fim
GROUP BY
    o.order_id, o.order_status, o.order_purchase_timestamp, c.customer_unique_id, c.customer_city, c.customer_state
ORDER BY
    o.order_purchase_timestamp;
END$$

DELIMITER ;
  
## 4.5 Produtos Mais Vendidos no Período (Top 5)

  DELIMITER $$

CREATE PROCEDURE top5_produtos(IN data_inicio DATE, IN data_fim DATE)
BEGIN
SELECT
    oi.product_id,
    COUNT(oi.product_id) AS total_vendido
FROM
    order_item oi
        JOIN
    `order` o ON oi.order_id = o.order_id
        LEFT JOIN
    product p ON oi.product_id = p.product_id
WHERE
    o.order_purchase_timestamp BETWEEN data_inicio AND data_fim
GROUP BY
    oi.product_id
ORDER BY
    total_vendido DESC
    LIMIT 5;
END$$

DELIMITER ;
  
## 4.6 Pedidos com mais atrasos por período (Top 10)

  DELIMITER $$

CREATE PROCEDURE top10_mais_atraso(IN data_inicio DATE, IN data_fim DATE)
BEGIN
SELECT
    o.order_id,
    o.order_estimated_delivery_date AS data_estimada,
    o.order_delivered_customer_date AS data_real,
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS dias_de_atraso
FROM
    `order` o
WHERE
    o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_delivered_customer_date > o.order_estimated_delivery_date
  AND o.order_purchase_timestamp BETWEEN data_inicio AND data_fim
ORDER BY
    dias_de_atraso DESC
    LIMIT 10;
END$$

DELIMITER ;
  
## 4.7 Clientes com Maior Valor em Compras (Top 10)

DELIMITER $$

CREATE PROCEDURE top10_maior_valor()
BEGIN
SELECT
    c.customer_unique_id,
    SUM(p.payment_value) AS total_gasto
FROM
    `order` o
        JOIN
    customer c ON o.customer_id = c.customer_id
        JOIN
    order_payment p ON o.order_id = p.order_id
GROUP BY
    c.customer_unique_id
ORDER BY
    total_gasto DESC
    LIMIT 10;
END$$

DELIMITER ;
  
## 4.8 Tempo Médio de Entrega por Estado
  
  DELIMITER $$

CREATE PROCEDURE tempo_medio_estado()
BEGIN
SELECT
    c.customer_state AS estado,
    AVG(DATEDIFF(o.order_delivered_customer_date, o.order_delivered_carrier_date)) AS tempo_medio_entrega
FROM
    `order` o
        JOIN
    customer c ON o.customer_id = c.customer_id
WHERE
    o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_carrier_date IS NOT NULL
GROUP BY
    c.customer_state
ORDER BY
    tempo_medio_entrega DESC;
END$$

DELIMITER ;
  
## 4.9 Filtrar Vendedores Dentro de um Raio Específico (Desafio)
   
DELIMITER $$

CREATE FUNCTION haversine_distance(
    lat1 DECIMAL(10, 8),
    lon1 DECIMAL(10, 8),
    lat2 DECIMAL(10, 8),
    lon2 DECIMAL(10, 8))
    RETURNS DECIMAL(10, 2)
    DETERMINISTIC
BEGIN
        DECLARE R DECIMAL(10, 2);
DECLARE dlat DECIMAL(10, 8);
DECLARE dlon DECIMAL(10, 8);
DECLARE a DECIMAL(10, 8);
DECLARE c DECIMAL(10, 8);
DECLARE d DECIMAL(10, 2);

SET R = 6371;
SET lat1 = RADIANS(lat1);
SET lon1 = RADIANS(lon1);
SET lat2 = RADIANS(lat2);
SET lon2 = RADIANS(lon2);

SET dlat = lat2 - lat1;
SET dlon = lon2 - lon1;

SET a = SIN(dlat / 2) * SIN(dlat / 2) + COS(lat1) * COS(lat2) * SIN(dlon / 2) * SIN(dlon / 2);
SET c = 2 * ATAN2(SQRT(a), SQRT(1 - a));
SET d = R * c;

RETURN d;

END$$

DELIMITER ;

```

# 5. Otimização de Consultas


## Identificar consultas que podem ser otimizadas.

### 
    Consultas que filtram por datas (order_purchase_timestamp). 
    Consultas que agrupam por customer_unique_id ou seller_id.

```sql
    
    # view total_vendas_vendedor
      
-> Sort: total_vendas DESC  (actual time=518..519 rows=3095 loops=1)
    -> Stream results  (cost=22619 rows=3081) (actual time=0.708..514 rows=3095 loops=1)
        -> Group aggregate: sum(order_item.price)  (cost=22619 rows=3081) (actual time=0.704..510 rows=3095 loops=1)
            -> Index scan on order_item using fk_order_item_seller  (cost=11450 rows=111690) (actual time=0.692..428 rows=112650 loops=1)
    
    
    # PROCEDURE top10_clientes
      
    -> Limit: 10 row(s)  (actual time=1517..1517 rows=10 loops=1)
    -> Sort: total_gasto DESC, total_pedidos DESC, limit input to 10 row(s) per chunk  (actual time=1517..1517 rows=10 loops=1)
        -> Stream results  (actual time=1374..1493 rows=43529 loops=1)
            -> Group aggregate: count(distinct `order`.order_id), sum(order_item.price)  (actual time=1374..1455 rows=43529 loops=1)
                -> Sort: c.customer_unique_id  (actual time=1374..1387 rows=51234 loops=1)
                    -> Stream results  (cost=17927 rows=12688) (actual time=0.43..1252 rows=51234 loops=1)
                        -> Nested loop inner join  (cost=17927 rows=12688) (actual time=0.427..1185 rows=51234 loops=1)
                            -> Nested loop inner join  (cost=13916 rows=10971) (actual time=0.401..499 rows=45430 loops=1)
                                -> Filter: ((o.order_purchase_timestamp between '2016-01-01' and '2018-01-01') and (o.customer_id is not null))  (cost=10076 rows=10971) (actual time=0.112..216 rows=45430 loops=1)
                                    -> Table scan on o  (cost=10076 rows=98750) (actual time=0.103..81.6 rows=99441 loops=1)
                                -> Single-row index lookup on c using PRIMARY (customer_id=o.customer_id)  (cost=0.25 rows=1) (actual time=0.00576..0.00582 rows=1 loops=45430)
                            -> Filter: (o.order_id = oi.order_id)  (cost=0.25 rows=1.16) (actual time=0.012..0.0145 rows=1.13 loops=45430)
                                -> Index lookup on oi using PRIMARY (order_id=o.order_id)  (cost=0.25 rows=1.16) (actual time=0.0106..0.0129 rows=1.13 loops=45430)

    # VIEW media_avaliacoes_loja  
    
    -> Sort: media_avaliacoes DESC  (actual time=1962..1963 rows=3080 loops=1)
    -> Table scan on <temporary>  (actual time=1955..1956 rows=3080 loops=1)
        -> Aggregate using temporary table  (actual time=1955..1955 rows=3080 loops=1)
            -> Nested loop inner join  (cost=45388 rows=112146) (actual time=6.03..1638 rows=110553 loops=1)
                -> Filter: (r.order_id is not null)  (cost=9930 rows=96973) (actual time=5.99..357 rows=97621 loops=1)
                    -> Table scan on r  (cost=9930 rows=96973) (actual time=5.98..331 rows=97621 loops=1)
                -> Index lookup on oi using PRIMARY (order_id=r.order_id)  (cost=0.25 rows=1.16) (actual time=0.0106..0.0125 rows=1.13 loops=97621)

    
    # PROCEDURE pedidos_periodo
      
    -> Sort: o.order_purchase_timestamp  (actual time=5580..5638 rows=99112 loops=1)
    -> Table scan on <temporary>  (actual time=5248..5358 rows=99112 loops=1)
        -> Aggregate using temporary table  (actual time=5248..5248 rows=99111 loops=1)
            -> Nested loop left join  (cost=26017 rows=11437) (actual time=3.62..2649 rows=103540 loops=1)
                -> Nested loop inner join  (cost=13916 rows=10971) (actual time=0.107..1254 rows=99112 loops=1)
                    -> Filter: ((o.order_purchase_timestamp between '2017-01-01' and '2018-12-31') and (o.customer_id is not null))  (cost=10076 rows=10971) (actual time=0.0885..465 rows=99112 loops=1)
                        -> Table scan on o  (cost=10076 rows=98750) (actual time=0.0828..253 rows=99441 loops=1)
                    -> Single-row index lookup on c using PRIMARY (customer_id=o.customer_id)  (cost=0.25 rows=1) (actual time=0.00741..0.00747 rows=1 loops=99112)
                -> Filter: (o.order_id = p.order_id)  (cost=0.999 rows=1.04) (actual time=0.0107..0.0133 rows=1.04 loops=99112)
                    -> Index lookup on p using PRIMARY (order_id=o.order_id)  (cost=0.999 rows=1.04) (actual time=0.0093..0.0117 rows=1.04 loops=99112)

      
    # PROCEDURE top5_produtos
    
    -> Limit: 5 row(s)  (actual time=2586..2586 rows=5 loops=1)
    -> Sort: total_vendido DESC, limit input to 5 row(s) per chunk  (actual time=2586..2586 rows=5 loops=1)
        -> Table scan on <temporary>  (actual time=2565..2577 rows=32787 loops=1)
            -> Aggregate using temporary table  (actual time=2565..2565 rows=32787 loops=1)
                -> Nested loop left join  (cost=28009 rows=12688) (actual time=0.102..2235 rows=112280 loops=1)
                    -> Nested loop inner join  (cost=14088 rows=12688) (actual time=0.0806..1658 rows=112280 loops=1)
                        -> Filter: (o.order_purchase_timestamp between '2017-01-01' and '2018-12-31')  (cost=10076 rows=10971) (actual time=0.0632..230 rows=99112 loops=1)
                            -> Table scan on o  (cost=10076 rows=98750) (actual time=0.059..82.2 rows=99441 loops=1)
                        -> Filter: (oi.order_id = o.order_id)  (cost=0.25 rows=1.16) (actual time=0.0114..0.0139 rows=1.13 loops=99112)
                            -> Index lookup on oi using PRIMARY (order_id=o.order_id)  (cost=0.25 rows=1.16) (actual time=0.0103..0.0125 rows=1.13 loops=99112)
                    -> Single-row covering index lookup on p using PRIMARY (product_id=oi.product_id)  (cost=0.997 rows=1) (actual time=0.00462..0.00468 rows=1 loops=112280)

      
    # PROCEDURE top10_mais_atraso
    
    -> Limit: 10 row(s)  (cost=10076 rows=10) (actual time=27.4..27.4 rows=10 loops=1)
    -> Sort: dias_de_atraso DESC, limit input to 10 row(s) per chunk  (cost=10076 rows=98750) (actual time=27.4..27.4 rows=10 loops=1)
        -> Filter: ((o.order_delivered_customer_date is not null) and (o.order_estimated_delivery_date is not null) and (o.order_delivered_customer_date > o.order_estimated_delivery_date) and (o.order_purchase_timestamp between '2017-01-01' and '2018-12-31'))  (cost=10076 rows=98750) (actual time=0.0822..26.1 rows=7823 loops=1)
            -> Table scan on o  (cost=10076 rows=98750) (actual time=0.0757..19.3 rows=99441 loops=1)

      
    # PROCEDURE top10_maior_valor

    -> Limit: 10 row(s)  (actual time=3381..3381 rows=10 loops=1)
    -> Sort: total_gasto DESC, limit input to 10 row(s) per chunk  (actual time=3381..3381 rows=10 loops=1)
        -> Table scan on <temporary>  (actual time=3283..3337 rows=96095 loops=1)
            -> Aggregate using temporary table  (actual time=3283..3283 rows=96094 loops=1)
                -> Nested loop inner join  (cost=83478 rows=103424) (actual time=16.3..1747 rows=103886 loops=1)
                    -> Nested loop inner join  (cost=47280 rows=103424) (actual time=16.3..1067 rows=103886 loops=1)
                        -> Table scan on p  (cost=11081 rows=103424) (actual time=0.109..128 rows=103886 loops=1)
                        -> Filter: ((o.order_id = p.order_id) and (o.customer_id is not null))  (cost=0.25 rows=1) (actual time=0.0083..0.0085 rows=1 loops=103886)
                            -> Single-row index lookup on o using PRIMARY (order_id=p.order_id)  (cost=0.25 rows=1) (actual time=0.00638..0.00645 rows=1 loops=103886)
                    -> Single-row index lookup on c using PRIMARY (customer_id=o.customer_id)  (cost=0.25 rows=1) (actual time=0.00595..0.00602 rows=1 loops=103886)

    # PROCEDURE tempo_medio_estado  
      
     -> Sort: tempo_medio_entrega DESC  (actual time=868..868 rows=27 loops=1)
    -> Table scan on <temporary>  (actual time=867..867 rows=27 loops=1)
        -> Aggregate using temporary table  (actual time=867..867 rows=27 loops=1)
            -> Nested loop inner join  (cost=38072 rows=79987) (actual time=0.119..633 rows=96475 loops=1)
                -> Filter: ((o.order_delivered_customer_date is not null) and (o.order_delivered_carrier_date is not null) and (o.customer_id is not null))  (cost=10076 rows=79987) (actual time=0.1..153 rows=96475 loops=1)
                    -> Table scan on o  (cost=10076 rows=98750) (actual time=0.099..105 rows=99441 loops=1)
                -> Single-row index lookup on c using PRIMARY (customer_id=o.customer_id)  (cost=0.25 rows=1) (actual time=0.00447..0.00452 rows=1 loops=96475)

```

## Criar índices (quando necessário) para melhorar a performance das consultas

```sql
CREATE INDEX idx_customer_id ON customer(customer_id);
CREATE INDEX idx_order_id ON order_payment(order_id);
CREATE INDEX idx_order_customer ON `order`(customer_id);
```

## Executar cada consulta novamente e medir o tempo de execução com EXPLAIN ANALYZE . Depois comparar com o resultado inicial

```sql

    # PROCEDURE top10_clientes
    
    -> Limit: 10 row(s)  (actual time=3754..3754 rows=10 loops=1)
    -> Sort: total_gasto DESC, total_pedidos DESC, limit input to 10 row(s) per chunk  (actual time=3754..3754 rows=10 loops=1)
        -> Stream results  (actual time=3384..3695 rows=95121 loops=1)
            -> Group aggregate: count(distinct `order`.order_id), sum(order_item.price)  (actual time=3384..3595 rows=95121 loops=1)
                -> Sort: c.customer_unique_id  (actual time=3384..3418 rows=112280 loops=1)
                    -> Stream results  (cost=17927 rows=12688) (actual time=0.567..3095 rows=112280 loops=1)
                        -> Nested loop inner join  (cost=17927 rows=12688) (actual time=0.562..2925 rows=112280 loops=1)
                            -> Nested loop inner join  (cost=13916 rows=10971) (actual time=0.145..1027 rows=99112 loops=1)
                                -> Filter: ((o.order_purchase_timestamp between '2017-01-01' and '2018-12-31') and (o.customer_id is not null))  (cost=10076 rows=10971) (actual time=0.12..339 rows=99112 loops=1)
                                    -> Table scan on o  (cost=10076 rows=98750) (actual time=0.112..112 rows=99441 loops=1)
                                -> Single-row index lookup on c using PRIMARY (customer_id=o.customer_id)  (cost=0.25 rows=1) (actual time=0.0064..0.00646 rows=1 loops=99112)
                            -> Filter: (o.order_id = oi.order_id)  (cost=0.25 rows=1.16) (actual time=0.0155..0.0184 rows=1.13 loops=99112)
                                -> Index lookup on oi using PRIMARY (order_id=o.order_id)  (cost=0.25 rows=1.16) (actual time=0.014..0.0166 rows=1.13 loops=99112)

    # PROCEDURE pedidos_periodo
      
    -> Sort: o.order_purchase_timestamp  (actual time=6313..6360 rows=99112 loops=1)
    -> Table scan on <temporary>  (actual time=5975..6086 rows=99112 loops=1)
        -> Aggregate using temporary table  (actual time=5975..5975 rows=99111 loops=1)
            -> Nested loop left join  (cost=26017 rows=11437) (actual time=1.22..3086 rows=103540 loops=1)
                -> Nested loop inner join  (cost=13916 rows=10971) (actual time=0.322..1446 rows=99112 loops=1)
                    -> Filter: ((o.order_purchase_timestamp between '2017-01-01' and '2018-12-31') and (o.customer_id is not null))  (cost=10076 rows=10971) (actual time=0.251..449 rows=99112 loops=1)
                        -> Table scan on o  (cost=10076 rows=98750) (actual time=0.244..156 rows=99441 loops=1)
                    -> Single-row index lookup on c using PRIMARY (customer_id=o.customer_id)  (cost=0.25 rows=1) (actual time=0.00938..0.00946 rows=1 loops=99112)
                -> Filter: (o.order_id = p.order_id)  (cost=0.999 rows=1.04) (actual time=0.0119..0.0155 rows=1.04 loops=99112)
                    -> Index lookup on p using PRIMARY (order_id=o.order_id)  (cost=0.999 rows=1.04) (actual time=0.0102..0.0134 rows=1.04 loops=99112)
    
      
    # PROCEDURE top5_produtos
      
    -> Limit: 5 row(s)  (actual time=3420..3420 rows=5 loops=1)
    -> Sort: total_vendido DESC, limit input to 5 row(s) per chunk  (actual time=3420..3420 rows=5 loops=1)
        -> Table scan on <temporary>  (actual time=3400..3412 rows=32787 loops=1)
            -> Aggregate using temporary table  (actual time=3400..3400 rows=32787 loops=1)
                -> Nested loop left join  (cost=28044 rows=12688) (actual time=0.194..2961 rows=112280 loops=1)
                    -> Nested loop inner join  (cost=14088 rows=12688) (actual time=0.131..2190 rows=112280 loops=1)
                        -> Filter: (o.order_purchase_timestamp between '2017-01-01' and '2018-12-31')  (cost=10076 rows=10971) (actual time=0.0903..320 rows=99112 loops=1)
                            -> Table scan on o  (cost=10076 rows=98750) (actual time=0.085..106 rows=99441 loops=1)
                        -> Filter: (oi.order_id = o.order_id)  (cost=0.25 rows=1.16) (actual time=0.0148..0.0182 rows=1.13 loops=99112)
                            -> Index lookup on oi using PRIMARY (order_id=o.order_id)  (cost=0.25 rows=1.16) (actual time=0.0132..0.0163 rows=1.13 loops=99112)
                    -> Single-row covering index lookup on p using PRIMARY (product_id=oi.product_id)  (cost=1 rows=1) (actual time=0.00625..0.00632 rows=1 loops=112280)

      
    # PROCEDURE top10_mais_atraso  
      
    -> Limit: 10 row(s)  (cost=10076 rows=10) (actual time=29.8..29.8 rows=10 loops=1)
    -> Sort: dias_de_atraso DESC, limit input to 10 row(s) per chunk  (cost=10076 rows=98750) (actual time=29.8..29.8 rows=10 loops=1)
        -> Filter: ((o.order_delivered_customer_date is not null) and (o.order_estimated_delivery_date is not null) and (o.order_delivered_customer_date > o.order_estimated_delivery_date) and (o.order_purchase_timestamp between '2017-01-01' and '2018-12-31'))  (cost=10076 rows=98750) (actual time=0.0977..28.3 rows=7823 loops=1)
            -> Table scan on o  (cost=10076 rows=98750) (actual time=0.0902..21.1 rows=99441 loops=1)

    
    # PROCEDURE top10_maior_valor
      
    -> Limit: 10 row(s)  (actual time=3619..3619 rows=10 loops=1)
    -> Sort: total_gasto DESC, limit input to 10 row(s) per chunk  (actual time=3619..3619 rows=10 loops=1)
        -> Table scan on <temporary>  (actual time=3514..3575 rows=96095 loops=1)
            -> Aggregate using temporary table  (actual time=3514..3514 rows=96094 loops=1)
                -> Nested loop inner join  (cost=83478 rows=103424) (actual time=0.264..1876 rows=103886 loops=1)
                    -> Nested loop inner join  (cost=47280 rows=103424) (actual time=0.255..1130 rows=103886 loops=1)
                        -> Table scan on p  (cost=11081 rows=103424) (actual time=0.125..132 rows=103886 loops=1)
                        -> Filter: ((o.order_id = p.order_id) and (o.customer_id is not null))  (cost=0.25 rows=1) (actual time=0.00885..0.00906 rows=1 loops=103886)
                            -> Single-row index lookup on o using PRIMARY (order_id=p.order_id)  (cost=0.25 rows=1) (actual time=0.0068..0.00687 rows=1 loops=103886)
                    -> Single-row index lookup on c using PRIMARY (customer_id=o.customer_id)  (cost=0.25 rows=1) (actual time=0.00655..0.00663 rows=1 loops=103886)

    
    # PROCEDURE tempo_medio_estado
      
    -> Sort: tempo_medio_entrega DESC  (actual time=996..996 rows=27 loops=1)
    -> Table scan on <temporary>  (actual time=996..996 rows=27 loops=1)
        -> Aggregate using temporary table  (actual time=996..996 rows=27 loops=1)
            -> Nested loop inner join  (cost=38072 rows=79987) (actual time=0.118..718 rows=96475 loops=1)
                -> Filter: ((o.order_delivered_customer_date is not null) and (o.order_delivered_carrier_date is not null) and (o.customer_id is not null))  (cost=10076 rows=79987) (actual time=0.0941..166 rows=96475 loops=1)
                    -> Table scan on o  (cost=10076 rows=98750) (actual time=0.0929..110 rows=99441 loops=1)
                -> Single-row index lookup on c using PRIMARY (customer_id=o.customer_id)  (cost=0.25 rows=1) (actual time=0.00518..0.00524 rows=1 loops=96475)
```

# 6. Auditoria no BD

###
   Exemplo
```sql

    # Exemplo da tabela auditoria

    CREATE TABLE auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tabela_afetada VARCHAR(50) NOT NULL,
    operacao VARCHAR(10) NOT NULL, 
    id_registro_afetado VARCHAR(36) NOT NULL, 
    data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
    );

    # Exemplo de trigger para obter informações apos o isert de dados.
    
    DELIMITER //

    CREATE TRIGGER trg_auditoria_insert AFTER INSERT ON `orders`
        FOR EACH ROW
    BEGIN
        INSERT INTO auditoria (tabela_afetada, operacao, id_registro, dados_novos, usuario)
        VALUES ('orders', 'INSERT', NEW.order_id (
                'customer_id', NEW.customer_id,
                'order_status', NEW.order_status,
                'order_purchase_timestamp', NEW.order_purchase_timestamp
                ), CURRENT_USER());
    END //

    DELIMITER ;

```
