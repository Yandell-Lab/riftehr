-- get back to what step 0 should have made.
--insert into pt_matches
create table pt_matches as
select x.empi_or_mrn as mrn,
       x.relationship,
       x.relation_empi_or_mrn as relation_mrn,
       array_agg(x.matched_path) as matched_path
from x_cumc_patient_matched x
group by mrn, relation_mrn, relationship
;

--### Exclude spouses and self 
-- create table 
insert into cell.matches_wo_spouse
select a.mrn
       , l.relationship_group
       , a.relation_mrn
       , array_agg(a.matched_path) as matched_path
from cell.pt_matches a
join cell.relationship_lookup l on trim(a.relationship) = trim(l.relationship)
where l.relationship_group != ''
      and trim(l.relationship_group) != 'Spouse'
      and a.mrn != a.relation_mrn
group by a.mrn,a.relation_mrn, l.relationship_group
;

--### Exclude emergency contacts with most matches 
drop table if exists cell.ec_exclude;
create table cell.ec_exclude as
select relation_mrn, count(distinct m.mrn) , demog.*
from cell.matches_wo_spouse m
join cell.pt_demog demog on (demog.mrn = relation_mrn)
group by relation_mrn
having count(distinct m.mrn) >= 2
;
