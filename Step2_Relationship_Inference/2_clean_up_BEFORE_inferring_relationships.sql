-- ###Flip and clean up step
-- # Create table to be updated 

drop table if exists relations_matched_mrn_with_age_dif\p\g
create table relations_matched_mrn_with_age_dif
as
select distinct
       a.mrn,
       b.relationship_group,
       a.relation_mrn,
       a.matched_path,
       child.year as DOB_empi,
       parent.year as DOB_matched,
       child.year - parent.year as age_dif,
       cast(null as int) as exclude
from pt_matches a
join relationship_lookup b on a.relationship = b.relationship
join pt_demog child on child.mrn = a.mrn
join pt_demog parent on parent.mrn = a.relation_mrn
\p\g
/* should get to here*/
-- ##### exclude: 1 = delete / 2 = flip relationship

-- # exclude annotated cases with relationships that match multiple people (20+)
-- update relations_matched_mrn_with_age_dif a
-- set exclude = "1"
-- from exclude_MRNs_before_inferences b
-- where a.relation_mrn = b.relation_mrn
-- \p\g
  
-- update relations_matched_mrn_with_age_dif a
-- set exclude = "1"
-- from exclude_MRNs_before_inferences b
-- where a.mrn = b.relation_mrn
-- \p\g
  
-- # exclude patients with conflicting year of birth 
-- update relations_matched_mrn_with_age_dif a
-- set exclude = 1
-- from ((select distinct t1.mrn, t1.relation_mrn, count(t1.age_dif) as cnt
--      from (select distinct mrn, relation_mrn, age_dif
--           from relations_matched_mrn_with_age_dif
--           group by mrn, relation_mrn, age_dif
--           ) t1
--      group by t1.mrn, t1.relation_mrn)
-- having count(t1.age_dif) >1
-- ) b
-- where a.mrn = b.mrn and a.relation_mrn = b.relation_mrn and 
\p\g


-- # exclude SELF
update relations_matched_mrn_with_age_dif a
set exclude = 1
where a.mrn = a.relation_mrn\p\g


-- # exclude PARENTS with age difference BETWEEN -10 AND 10 years
update relations_matched_mrn_with_age_dif a
set exclude = 1
where a.relationship_group = 'Parent' and a.age_dif between -10 and 10\p\g

-- # exclude GRANDPARENTS with age difference BETWEEN -20 AND 20 years
update relations_matched_mrn_with_age_dif a
set exclude = 1
where a.relationship_group = 'Grandparent' and a.age_dif between -20 and 20\p\g

-- # exclude CHILD with age difference BETWEEN -10 AND 10 years
update relations_matched_mrn_with_age_dif a
set exclude =  1
where a.relationship_group = 'Child' and a.age_dif between -10 and 10\p\g

-- # exclude GRANDCHILD with age difference BETWEEN -20 AND 20 years
update relations_matched_mrn_with_age_dif a
set exclude = 1
where a.relationship_group = 'Grandchild' and a.age_dif between -20 and 20\p\g

-- #exclude cases with year of birth <1900
update relations_matched_mrn_with_age_dif a
set exclude = 1
where DOB_empi < 1900 or DOB_matched <1900\p\g

-- # only consider matches that match on at least 2 items (first name, last name, phone, ZIP code)
drop table if exists pt_matches_clean\p\g
create table pt_matches_clean as
select mrn, relationship, relation_mrn, array_remove(array_remove(matched_path, 'phone'), 'zip') as matched_path
from pt_matches
where array_length(matched_path,1) > 1\p\g

-- # create final table of matched relations
drop table if exists patient_relations_w_opposites\p\g
create table patient_relations_w_opposites as
select distinct mrn, relationship, relation_mrn
from pt_matches_clean
union
select distinct relation_mrn as mrn, b.opposite_relationship_group as relationship, mrn as relation_mrn
from pt_matches_clean a
join relationship_lookup b on a.relationship = b.relationship_group\p\g


-- # flip PARENTS with age difference <-10
update relations_matched_mrn_with_age_dif a
set exclude = 2
where a.relationship_group = 'Parent' and a.age_dif <-10 and a.exclude is NULL\p\g

-- # flip GRANDPARENTS with age difference <-20
update relations_matched_mrn_with_age_dif a
set exclude = 2
where a.relationship_group = 'Grandparent' and a.age_dif <-20 and a.exclude is NULL\p\g

-- # flip CHILD with age difference >10
update relations_matched_mrn_with_age_dif a
set exclude = 2
where a.relationship_group = 'Child' and a.age_dif >10 and a.exclude is NULL\p\g

-- # flip GRANDCHILD with age difference >20
update relations_matched_mrn_with_age_dif a
set exclude = 2
where a.relationship_group = 'Grandchild' and a.age_dif >20 and a.exclude is NULL\p\g

-- ### Creating clean relations_matched_empi

-- # Flipping relationships 
drop table if exists relations_matched_mrn_fixed_flipped_rel\p\g
create table relations_matched_mrn_fixed_flipped_rel as
select distinct a.mrn, b.opposite_relationship_group as relationship, relation_mrn, matched_path, DOB_empi, DOB_matched, age_dif
from relations_matched_mrn_with_age_dif a
join relationship_lookup b on a.relationship_group = b.relationship_group
where a.exclude = 2\p\g

-- # Creating relations_matched_clean
drop table if exists relations_matched_clean\p\g
create table relations_matched_clean as
select distinct a.mrn, a.relationship_group as relationship, relation_mrn, matched_path, DOB_empi, DOB_matched, age_dif
from relations_matched_mrn_with_age_dif a
where a.exclude is NULL
union
select distinct b.mrn, b.relationship, b.relation_mrn, b.matched_path, b.DOB_empi, b.DOB_matched, b.age_dif
from relations_matched_mrn_fixed_flipped_rel b
\p\g

-- # Creating patient_relations_w_opposites_clean
drop table if exists patient_relations_w_opposites_clean\p\g
create table patient_relations_w_opposites_clean as 
select distinct mrn, relationship, relation_mrn
from relations_matched_clean where dob_empi <= dob_matched
union
select distinct a.relation_mrn as mrn, b.opposite_relationship_group as relationship, a.mrn as relation_mrn
from relations_matched_clean a
join relationship_lookup b on a.relationship = b.relationship_group and a.dob_empi > a.dob_matched
\p\g
