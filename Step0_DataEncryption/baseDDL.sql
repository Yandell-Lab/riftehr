create schema if not exists cell
\p\g

/* Or should we move these to the point of use/ */

drop table if exists x_ec_processed;
create table x_ec_processed (
 mrn_1 text, ec_firstname text, ec_lastname text, ec_phonenumber text, ec_zipcode text, ec_relationship text
)
\p\g

drop table if exists x_pt_processed;
create table x_pt_processed (
mrn text, firstname text, lastname text, phonenumber text, zipcode text
)
\p\g

drop table if exists match_priority;
create table x_match_priority (
match text, ordinal int
)
\p\g

/* UTAH extension to match published table.  Apparently they didn't
use their database as the source for the aricle */
alter table pt_demog add paper_race_ethnicity text;

/* used in pedigree filling, post Step6*/
create or replace function fakename() 
returns text 
as $$ 
declare 
    nm text; 
begin 
    select '__' || nextval('namer')::text into nm; 
    return nm;
end
$$ language plpgsql;


/* adding relationship distance */
alter table relationship_lookup add distance int
\p\g


create table relationship_degree (
       relationship text,
       degree int
);

-- /* Utah extension to capture original relationship definitions */
-- create table run.paper_relationship_dictionary (
--        relationship text
--        ,relationship_name text
--        ,relationship_group text
--        ,opposite_relationship_group text
-- )
-- \copy :
