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
