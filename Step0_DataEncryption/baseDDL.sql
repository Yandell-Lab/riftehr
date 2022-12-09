create schema if not exists cell;

drop table if exists x_ec_processed;
create table x_ec_processed (
 mrn_1 text, ec_firstname text, ec_lastname text, ec_phonenumber text, ec_zipcode text, ec_relationship text
);

drop table if exists x_pt_processed;
create table x_pt_processed (
mrn text, firstname text, lastname text, phonenumber text, zipcode text
);

drop table if exists match_priority;
create table x_match_priority (
match text, ordinal int
);

/* used in pedigree filling, post Step6*/
create or replace function fakename() 
returns text 
as $$ 
declare 
    nm text; 
begin 
    select '__' || nextval('namer')::text into nm; 
    return nm;
end;
$$ language plpgsql;
