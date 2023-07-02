--### Having imported output_actual_and_inferred_relationships.csv into database as actual_and_inf_rel_part1

select infer, count(*) from  actual_and_inf_rel_part1 group by infer
\p\g
--### Creating table with unique pairs and relationships
drop table if exists actual_and_inf_rel_part1_unique\p\g
create table actual_and_inf_rel_part1_unique as
select distinct mrn, relationship, relation_mrn, cast(null as int)as provided_relationship
from actual_and_inf_rel_part1\p\g


--### Add new field to "actual_and_inf_rel_part1_unique" called provided_relationship (INT)
update actual_and_inf_rel_part1_unique a
set provided_relationship = 1
from patient_relations_w_opposites_clean b
where a.mrn = b.mrn and a.relationship = b.relationship and a.relation_mrn = b.relation_mrn\p\g



--### Duplicate table actual_and_inf_rel_part1_unique and name it actual_and_inf_rel_part1_unique_clean
drop table if exists actual_and_inf_rel_part1_unique_clean\p\g
create table actual_and_inf_rel_part1_unique_clean as
select distinct *, 
       cast(null as int) as conflicting_provided_relationship,
       cast(null as varchar(25)) as relationship_specific
from actual_and_inf_rel_part1_unique\p\g

--### Add indexes
create index on actual_and_inf_rel_part1_unique_clean(mrn,relation_mrn)\p\g

--### Identifying mrn = to relation_mrn (Self) <--- 0 cases! If not = 0, exclude those
-- select *
-- from actual_and_inf_rel_part1_unique_clean
-- where mrn = relation_mrn\p\g
-- 
-- rjs original THIS SHOULD BE DONE MUCH EARLIER
delete from actual_and_inf_rel_part1_unique_clean where mrn = relation_mrn\p\g

/*
--### Creating conflicting provided relationships table 
create table provided_relationships_conflicting as
select mrn, relation_mrn, count(relationship)
from (select *
     from actual_and_inf_rel_part1_unique_clean
     where provided_relationship = 1
)a
group by mrn, relation_mrn
having count(relationship)>1\p\g

--### Create new column conflicting_provided_relationship at actual_and_inf_rel_part1_unique_clean

--### Tagging conflicting provided relationships
*/

drop table provided_relationships_conflicting\p\g
create table provided_relationships_conflicting as
select mrn, relation_mrn, array_agg(relationship order by relationship ) as ships
from actual_and_inf_rel_part1_unique_clean a
where provided_relationship = 1
group by mrn, relation_mrn
having count(relationship) > 1
\p\g

update actual_and_inf_rel_part1_unique_clean a
set conflicting_provided_relationship = 1
from  provided_relationships_conflicting b
where (a.mrn = b. mrn) 
      and (a.relation_mrn = b.relation_mrn)
      and a.provided_relationship = 1
\p\g

--### Create new column relationship_specific at actual_and_inf_rel_part1_unique_clean

--### Identifying and updating PROVIDED mothers for not conflicting cases
update actual_and_inf_rel_part1_unique_clean as a
SET relationship_specific = case when a.relationship = 'Parent' and d.sex =  'F' then 'Mother'
                                 when a.relationship = 'Parent' and d.sex =  'M' then 'Father'
                                 when a.relationship = 'Aunt/Uncle' and d.sex =  'F' then 'Aunt'
                                 when a.relationship = 'Aunt/Uncle' and d.sex =  'M' then 'Uncle'
                                 end
from pt_demog d
where a.relation_mrn = d.mrn
      and a.conflicting_provided_relationship is NULL 
      and a.relationship_specific is NULL
\p\g

--### Removing Parent/Aunt/Uncle from pairs that have Parent or Aunt/Uncle (count = 2) 
--    and cases that have Parent/Aunt/Uncle and Parent and Aunt/Uncle (count = 3)
--
-- we don't have any of these (100K)
drop table if exists delete_part1_parent_aunt_uncle_cases\p\g
create table delete_part1_parent_aunt_uncle_cases as 
select b.mrn, b.relation_mrn, c.relationship 
from ( select mrn, relation_mrn, count(relationship)
       from ( select distinct mrn, relationship, relation_mrn
              from actual_and_inf_rel_part1_unique_clean
              where relationship like 'Parent' or relationship like '%Aunt/Uncle'
            )a
       group by  mrn, relation_mrn
       having count(relationship)>1
     ) b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Parent/Aunt/Uncle'
\p\g
--### Delete "Parent/Aunt/Uncle that can be excluded from the table unique_clean
delete from actual_and_inf_rel_part1_unique_clean a
using delete_part1_parent_aunt_uncle_cases b 
where a.mrn = b.mrn 
      and a.relation_mrn = b.relation_mrn 
      and a.relationship = b.relationship\p\g


--### Removing Child/Nephew/Niece from pairs that have Child or Nephew/Niece or both 
--
-- none of these either
drop table if exists delete_part1_child_nephew_niece_cases\p\g
create table delete_part1_child_nephew_niece_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, relation_mrn
from actual_and_inf_rel_part1_unique_clean
where relationship like 'Child' or relationship like '%Nephew/Niece'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Child/Nephew/Niece'
\p\g



--### Delete Child/Nephew/Niece that can be excluded from the table unique_clean
delete from actual_and_inf_rel_part1_unique_clean a
using delete_part1_child_nephew_niece_cases b
where a.mrn = b.mrn and a.relation_mrn = b.relation_mrn and a.relationship = b.relationship\p\g


--### Removing Sibling/Cousin from pairs that have Child or Nephew/Niece or both
drop table if exists delete_part1_sibling_cousin_cases\p\g
create table delete_part1_sibling_cousin_cases as
select b.mrn, b.relation_mrn, c.relationship
from ( select mrn, relation_mrn, count(relationship)
       from ( select distinct mrn, relationship, relation_mrn
              from actual_and_inf_rel_part1_unique_clean
              where relationship like 'Sibling' or relationship like '%Cousin'
            ) a
       group by  mrn, relation_mrn
       having count(relationship)>1
     ) b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Sibling/Cousin'
\p\g

--### Delete Sibling/Cousin that can be excluded from the table unique_clean
delete --a
from actual_and_inf_rel_part1_unique_clean a
using delete_part1_sibling_cousin_cases b
where (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship)\p\g

--### Removing Parent/Parent-in-law from pairs that have Parent 
drop table if exists delete_part1_parent_in_law_cases\p\g
create table delete_part1_parent_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from ( select mrn, relation_mrn, count(relationship)
       from ( select distinct mrn, relationship, relation_mrn
              from actual_and_inf_rel_part1_unique_clean
              where relationship ='Parent' or relationship like 'Parent/Parent%'
            ) a
       group by  mrn, relation_mrn
       having count(relationship)>1
     ) b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Parent/Parent%'
\p\g

--### Delete Parent/Parent-in-law that can be excluded from the table unique_clean
delete from actual_and_inf_rel_part1_unique_clean a
using delete_part1_parent_in_law_cases b
where (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship)\p\g

--### Removing Child/Child-in-law from pairs that have Child
drop table if exists delete_part1_child_in_law_cases\p\g
create table delete_part1_child_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from ( select mrn, relation_mrn, count(relationship)
       from ( select distinct mrn, relationship, relation_mrn
              from actual_and_inf_rel_part1_unique_clean
              where relationship ='Child' or relationship like 'Child/Child%'
            ) a
       group by  mrn, relation_mrn
       having count(relationship)>1
       ) b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Child/Child%'
\p\g

--### Delete Child/Child-in-law that can be excluded from the table unique_clean
delete from actual_and_inf_rel_part1_unique_clean a
using delete_part1_child_in_law_cases b
where (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship)\p\g
 

--### Removing Grandaunt/Granduncle/Grandaunt-in-law/Granduncle-in-law from pairs that have Grandaunt/Granduncle
drop table if exists delete_part1_grandaunt_in_law_cases\p\g
create table delete_part1_grandaunt_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from ( select mrn, relation_mrn, count(relationship)
       from ( select distinct mrn, relationship, relation_mrn
              from actual_and_inf_rel_part1_unique_clean
              where relationship ='Grandaunt/Granduncle' or relationship like 'Grandaunt/Granduncle/Grandaunt%'
            ) a
       group by  mrn, relation_mrn
       having count(relationship)>1
     ) b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Grandaunt/Granduncle/Grandaunt%'
\p\g

--### Delete Grandaunt/Granduncle/Grandaunt-in-law/Granduncle-in-law that can be excluded from the table unique_clean
delete from actual_and_inf_rel_part1_unique_clean a
using delete_part1_grandaunt_in_law_cases b 
where a.mrn = b.mrn 
      and a.relation_mrn = b.relation_mrn 
      and a.relationship = b.relationship\p\g

--### Removing Grandchild/Grandchild-in-law from pairs that have Grandchild
drop table if exists delete_part1_grandchild_in_law_cases\p\g
create table delete_part1_grandchild_in_law_cases as 
select b.mrn, b.relation_mrn, c.relationship
from ( select mrn, relation_mrn, count(relationship)
       from ( select distinct mrn, relationship, relation_mrn
              from actual_and_inf_rel_part1_unique_clean
              where relationship ='Grandchild' or relationship like 'Grandchild/Grandchild%'
            ) a
       group by  mrn, relation_mrn
       having count(relationship)>1
     ) b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Grandchild/Grandchild%'
\p\g

--### Delete Grandchild/Grandchild-in-law that can be excluded from the table unique_clean
delete from actual_and_inf_rel_part1_unique_clean a
using delete_part1_grandchild_in_law_cases b
where (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship)\p\g


--### Removing Grandnephew/Grandniece/Grandnephew-in-law/Grandniece-in-law from pairs that have Grandnephew/Grandniece
drop table if exists delete_part1_grandnephew_in_law_cases\p\g
create table delete_part1_grandnephew_in_law_cases as 
select b.mrn, b.relation_mrn, c.relationship
from ( select mrn, relation_mrn, count(relationship)
       from ( select distinct mrn, relationship, relation_mrn 
              from actual_and_inf_rel_part1_unique_clean
              where relationship ='Grandnephew/Grandniece' or relationship like 'Grandnephew/Grandniece/Grandnephew%'
            ) a
       group by  mrn, relation_mrn
       having count(relationship)>1
     ) b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Grandnephew/Grandniece/Grandnephew%'
\p\g

--### Delete Grandnephew/Grandniece/Grandnephew-in-law/Grandniece-in-law that can be excluded from the table unique_clean
delete from actual_and_inf_rel_part1_unique_clean a
using delete_part1_grandnephew_in_law_cases b
where (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship)\p\g


--### Removing Grandparent/Grandparent-in-law from pairs that have Grandparent
drop table if exists delete_part1_grandparent_in_law_cases\p\g
create table delete_part1_grandparent_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from ( select mrn, relation_mrn, count(relationship)
     from ( select distinct mrn, relationship, relation_mrn
            from actual_and_inf_rel_part1_unique_clean
            where relationship ='Grandparent' or relationship like 'Grandparent/Grandparent%'
          ) a
     group by  mrn, relation_mrn
     having count(relationship)>1
) b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Grandparent/Grandparent%'
\p\g

--### Delete Grandparent/Grandparent-in-law that can be excluded from the table unique_clean
delete from actual_and_inf_rel_part1_unique_clean a
using delete_part1_grandparent_in_law_cases b
where (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship)\p\g


--### Removing Great-grandchild/Great-grandchild-in-law from pairs that have Great-grandchild
drop table if exists delete_part1_greatgrandchild_in_law_cases\p\g
create table delete_part1_greatgrandchild_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from ( select mrn, relation_mrn, count(relationship)
       from ( select distinct mrn, relationship, relation_mrn
              from actual_and_inf_rel_part1_unique_clean
              where relationship ='Great-grandchild' or relationship like 'Great-grandchild/Great-grandchild%'
            )a
       group by  mrn, relation_mrn
       having count(relationship)>1
     ) b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Great-grandchild/Great-grandchild%'
\p\g

--### Delete Great-grandchild/Great-grandchild-in-law that can be excluded from the table unique_clean
delete from actual_and_inf_rel_part1_unique_clean a
using delete_part1_greatgrandchild_in_law_cases b
where (a.mrn = b.mrn) 
     and (a.relation_mrn = b.relation_mrn) 
     and (a.relationship = b.relationship)
\p\g

--# Great-grandparent/Great-grandparent-in-law

--### Removing Great-grandparent/Great-grandparent-in-law from pairs that have Great-grandparent
drop table if exists delete_part1_greatgrandparent_in_law_cases
\p\g
create table delete_part1_greatgrandparent_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from (select mrn, relation_mrn, count(relationship)
      from ( select distinct mrn, relationship, relation_mrn
             from actual_and_inf_rel_part1_unique_clean
             where relationship ='Great-grandparent' or relationship like 'Great-grandparent/Great-grandparent%'
           ) a
      group by  mrn, relation_mrn
      having count(relationship)>1
     ) b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Great-grandparent/Great-grandparent%'
\p\g

--### Delete Great-grandparent/Great-grandparent-in-law that can be excluded from the table unique_clean
delete from actual_and_inf_rel_part1_unique_clean a
using delete_part1_greatgrandparent_in_law_cases b
where (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship)
\p\g


-- # Nephew/Niece/Nephew-in-law/Niece-in-law

-- ### Removing Nephew/Niece/Nephew-in-law/Niece-in-law from pairs that have Nephew/Niece
drop table if exists delete_part1_nephew_in_law_cases\p\g
create table delete_part1_nephew_in_law_cases as 
select b.mrn, b.relation_mrn, c.relationship
       from ( select mrn, relation_mrn, count(relationship)
              from ( select distinct mrn, relationship, relation_mrn
                     from actual_and_inf_rel_part1_unique_clean
                     where relationship ='Nephew/Niece' or relationship like 'Nephew/Niece/Nephew%'
                   ) a
       group by  mrn, relation_mrn
       having count(relationship)>1
)b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Nephew/Niece/Nephew%'
\p\g

--### Delete Nephew/Niece/Nephew-in-law/Niece-in-law that can be excluded from the table unique_clean
delete from actual_and_inf_rel_part1_unique_clean a
using delete_part1_nephew_in_law_cases b
where (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship)\p\g


--# Sibling/Sibling-in-law
--### Removing Sibling/Sibling-in-law from pairs that have Sibling
drop table if exists delete_part1_sibling_in_law_cases\p\g
create table delete_part1_sibling_in_law_cases as 
select b.mrn, b.relation_mrn, c.relationship
       from ( select mrn, relation_mrn, count(relationship)
              from ( select distinct mrn, relationship, relation_mrn
                     from actual_and_inf_rel_part1_unique_clean
                     where relationship ='Sibling' or relationship like 'Sibling/Sibling%'
                   ) a
       group by  mrn, relation_mrn
       having count(relationship)>1
)b
join actual_and_inf_rel_part1_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Sibling/Sibling%'
\p\g

--### Delete Sibling/Sibling-in-law that can be excluded from the table unique_clean
delete from actual_and_inf_rel_part1_unique_clean a
using delete_part1_sibling_in_law_cases b
where (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship)\p\g

--### Table 1 ref
select provided_relationship, count(*) from actual_and_inf_rel_part1_unique_clean group by provided_relationship
\p\g


--### Creating table to run new script
--UT: What "new script"?
drop table if exists patient_relations_w_opposites_part2\p\g
create table patient_relations_w_opposites_part2 as 
select distinct mrn, relationship, relation_mrn
from actual_and_inf_rel_part1_unique_clean
union
select distinct a.relation_mrn as mrn
                , b.relationship_opposite as relationship
                , a.mrn as relation_mrn
from actual_and_inf_rel_part1_unique_clean a
join relationships_and_opposites b on a.relationship = b.relationship
\p\g

-- copy-out done in wrapper to allow re-locating file
