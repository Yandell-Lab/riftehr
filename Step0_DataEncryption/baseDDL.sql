create schema if not exists cell\p\g

drop table if exists x_ec_processed\p\g
create table x_ec_processed (
 mrn_1 int, ec_firstname text, ec_lastname text, ec_phonenumber text, ec_zipcode text, ec_relationship text
)\p\g

drop table if exists x_pt_processed\p\g
create table x_pt_processed (
mrn text, firstname text, lastname text, phonenumber text, zipcode text
)\p\g
