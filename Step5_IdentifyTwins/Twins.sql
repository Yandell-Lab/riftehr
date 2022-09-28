-- #Table with siblings and their date of birth
drop table if exists siblings_with_dob\p\g
create table siblings_with_dob as
select distinct 
       rel.mrn
       , rel.relation_mrn
       , rel.relationship
       , demog.year as mrn_dob
       , demog2.year as relation_dob
from actual_and_inf_rel_clean_final rel
join pt_demog demog on rel.mrn = demog.mrn
join pt_demog demog2 on rel.relation_mrn = demog2.mrn
where rel.relationship = 'Sibling'
\p\g

create index on actual_and_inf_rel_clean_final(mrn)\p\g

-- # select siblings with the same DOB 
select distinct *
from siblings_with_dob
where mrn_dob = relation_dob\p\g

-- UT: find sibs without parents or children
-- UT: in the 100K test suite, zero sibs are parents or children
Siblings with no other connection\p\r

select s.* 
from actual_and_inf_rel_clean_final s
where s.relationship = 'Sibling' 
      and not exists (select 1 from actual_and_inf_rel_clean_final p 
                      where p.relationship = 'Child' and (s.mrn = p.mrn or s.mrn = p.relation_mrn))
      and not exists (select 1 from actual_and_inf_rel_clean_final p 
                     where p.relationship = 'Child' and (s.relation_mrn = p.mrn or s.relation_mrn = p.relation_mrn))
\p\g                     

