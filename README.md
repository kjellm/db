# An overly simplified relational SQL database

Inteded for learning about general concepts in how to build such a
beast.

The world database is taken from https://dev.mysql.com/doc/index-other.html

## Usage

```
bundle install
ruby db.rb 'select b from t,r where a = 1'
```

## Example Queries

```
ruby db.rb 'SELECT a, b, c FROM t,r WHERE a = 1 AND b = 2 AND c = 3'
ruby db.rb 'SELECT a, b, c FROM t,r WHERE a = 1 AND b = 2 OR c = 3'

ruby db.rb 'select * from city,country where id = 1 and population = 103000'
ruby db.rb 'select name, city_name from city,country where id = 1 and population = 103000'
ruby db.rb 'select name, city_name from country,city where id = 1 and population = 103000'
```
