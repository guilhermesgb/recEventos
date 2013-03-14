CREATE TABLE IF NOT EXISTS venues
(
id integer NOT NULL, 
lon VARCHAR(255) NOT NULL, 
lat VARCHAR(255) NOT NULL, 
name VARCHAR(255) DEFAULT NULL, 
address_1 VARCHAR(255) DEFAULT NULL, 
address_2 VARCHAR(255) DEFAULT NULL, 
address_3 VARCHAR(255) DEFAULT NULL, 
city VARCHAR(255) DEFAULT NULL, 
country VARCHAR(255) DEFAULT NULL, 
rating_count integer NOT NULL, 
rating integer NOT NULL
, PRIMARY KEY (id) 
);

COPY venues FROM 'C:\venues.csv' DELIMITERS ',' CSV HEADER;