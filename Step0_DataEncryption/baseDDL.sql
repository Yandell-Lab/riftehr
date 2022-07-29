create schema if not exists cell;
create table if not exists cell.x_ec_processed (
 mrn_1 int, ec_firstname text, ec_lastname text, ec_phonenumber text, ec_zipcode text, ec_relationship text
);
create table if not exists cell.x_pt_processed (
mrn int, firstname text, lastname text, phonenumber text, zipcode text
);



