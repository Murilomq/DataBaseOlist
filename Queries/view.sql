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

SELECT * FROM total_vendas_vendedor;

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

SELECT * FROM media_avaliacoes_loja;



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


CALL pedidos_periodo('2017-01-01', '2018-12-31');


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

CALL top5_produtos('2017-01-01', '2018-12-31');

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

CALL top10_mais_atraso('2017-01-01', '2018-12-31');


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

CALL top10_maior_valor();


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

CALL tempo_medio_estado();


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

