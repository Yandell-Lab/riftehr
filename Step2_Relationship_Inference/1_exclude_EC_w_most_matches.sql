-- get back to what step 0 should have made.
--insert into pt_matches, convert list of matchings into an array (postgres-ism)

drop table if exists pt_matches\p\g
create table pt_matches as
select x.empi_or_mrn::text as mrn,
       x.relationship,
       x.relation_empi_or_mrn::text as relation_mrn,
       array_agg(x.matched_path) as matched_path
from x_cumc_patient_matched x
group by mrn, relation_mrn, relationship
\p\g

--### Exclude spouses and self 
-- create table 
drop table if exists matches_wo_spouse\p\g
create table matches_wo_spouse as
select a.mrn
       , l.relationship_group
       , a.relation_mrn
       , a.matched_path
from pt_matches a
join relationship_lookup l on trim(a.relationship) = trim(l.relationship)
where l.relationship_group != ''
      and trim(l.relationship_group) != 'Spouse'
      and a.mrn != a.relation_mrn
\p\g

--### Exclude emergency contacts with most matches 
drop table if exists ec_exclude\p\g
create table ec_exclude as
select relation_mrn
       , count(distinct m.mrn) as tally
from matches_wo_spouse m
join pt_demog demog on demog.mrn = relation_mrn
group by relation_mrn
having count(distinct m.mrn) >= 20
\p\g
