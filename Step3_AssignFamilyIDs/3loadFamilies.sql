drop table if exists family;
create table family (id int, member text);
\copy family from ~/gits/github/ds-ehr/data/family.ids csv header
