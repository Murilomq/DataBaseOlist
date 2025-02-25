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
