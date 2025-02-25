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


