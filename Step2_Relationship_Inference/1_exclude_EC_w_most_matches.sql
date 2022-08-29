

--### Exclude spouses and self 
-- create table 
insert into cell.matches_wo_spouse
select a.empi_or_mrn as mrn, l.relationship_group, a.relation_empi_or_mrn as relation_mrn, a.matched_path
from cell.x_cumc_patient_matched a --cell.pt_matches ab
join cell.relationship_lookup l on a.relationship = l.relationship
where l.relationship_group != ''
      and relationship_group != 'Spouse'
      and a.empi_or_mrn != a.relation_empi_or_mrn
;

--### Exclude emergency contacts with most matches 
create table cell.ec_exclude as
select relation_mrn, count(distinct m.mrn), demog.*
from cell.matches_wo_spouse m
join cell.pt_demog demog on (demog.mrn = relation_mrn)
group by relation_mrn
having count(distinct empi_or_mrn) >= 20
;
