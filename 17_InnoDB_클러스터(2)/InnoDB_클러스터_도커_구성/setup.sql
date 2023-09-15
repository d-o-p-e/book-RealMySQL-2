CREATE USER 'test'@'%' IDENTIFIED BY '1234';

GRANT ALL privileges ON *.* TO 'test'@'%' with grant option;

reset master;