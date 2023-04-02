CREATE SEQUENCE id_seq
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

CREATE TABLE products (
  id INT NOT NULL DEFAULT NEXTVAL('id_seq'),
  name VARCHAR(255) NOT NULL,
  description VARCHAR(512),
  dt VARCHAR(10),
  CONSTRAINT products_pkey PRIMARY KEY (id)
);

INSERT INTO products(name,description,dt)
VALUES ('scooter','Small 2-wheel scooter','20201214'),
       ('car battery','12V car battery','20201214'),
       ('12-pack drill bits','12-pack of drill bits with sizes ranging from #40 to #3','20201214'),
       ('hammer','12oz carpenter''s hammer','20211214'),
       ('hammer','14oz carpenter''s hammer','20211214'),
       ('hammer','16oz carpenter''s hammer','20211214'),
       ('rocks','box of assorted rocks','20221214'),
       ('jacket','water resistent black wind breaker','20221214'),
       ('spare tire','24 inch spare tire','20221214');

CREATE TABLE orders (
  id INT NOT NULL DEFAULT NEXTVAL('id_seq'),
  order_date TIMESTAMP NOT NULL,
  customer_name VARCHAR(255) NOT NULL,
  price DECIMAL(10, 5) NOT NULL,
  product_id INT NOT NULL,
  order_status BOOLEAN NOT NULL,
  CONSTRAINT orders_pkey PRIMARY KEY (id)
);

INSERT INTO orders(order_date,customer_name,price,product_id,order_status)
VALUES ('2020-07-30 10:08:22', 'Jark', 50.50, 102, FALSE),
       ('2020-07-30 10:11:09', 'Sally', 15.00, 105, FALSE),
       ('2020-07-30 12:00:30', 'Edward', 25.25, 106, FALSE);
