
-- ### Import output_patient_relations_w_opposites_part2 as actual_and_inf_rel_part2 into the database
-- UT: move the copy to external script to parameterize the working directory
copy actual_and_inf_rel_part2 from ~/gits/github/ds-ehr/data/output_patient_relations_w_opposites_part2.csv csv

-- ### Creating table with unique pairs and relationships
drop table if exists actual_and_inf_rel_part2_unique\p\g
create table actual_and_inf_rel_part2_unique as
select distinct a.mrn
        , a.relationship
        , a.relation_mrn
        , case when b.mrn is null then cast(null as int)
               when b.mrn is not null then cast(1 as int)
               end as provided_relationship
from actual_and_inf_rel_part2 a 
     left join patient_relations_w_opposites_clean b on a.mrn = b.mrn 
          and a.relationship = b.relationship 
          and a.relation_mrn = b.relation_mrn
\p\g


-- ### Add new field to "actual_and_inf_rel_part2_unique" called provided_relationship (INT)
update actual_and_inf_rel_part2_unique a
set provided_relationship = 1
from patient_relations_w_opposites_clean b
where a.mrn = b.mrn 
      and a.relationship = b.relationship
      and a.relation_mrn = b.relation_mrn
\p\g


-- ### Duplicate table actual_and_inf_rel_part2_unique and name it actual_and_inf_rel_part2_unique_clean
-- ### Add indexes
-- ### Identifying mrn = to relation_mrn (Self) <--- 0 cases! 

-- select count(*) as self_referencial_count
-- from actual_and_inf_rel_part2_unique_clean
-- where mrn = relation_mrn
-- \p\g
/*
 UT: making the "clean" table here, from scratch
*/
drop table if exists actual_and_inf_rel_part2_unique_clean\p\g
create table actual_and_inf_rel_part2_unique_clean as
select u.*, null::int as conflicting_provided_relationship, null::text as relationship_specific 
from actual_and_inf_rel_part2_unique u
\p\g
create index on actual_and_inf_rel_part2_unique_clean(mrn, relation_mrn);

-- ### Create new column conflicting_provided_relationship at actual_and_inf_rel_part2_unique_clean
-- UT this has been done in the global DDL but we have to diddle with uniqueness constraint
-- UT alter table actual_and_inf_rel_part2_unique_clean drop constraint if exists actual_and_inf_rel_part2_unique_clean_mrn_key\p\g
-- UT the DDL has been updated
-- UT alter table actual_and_inf_rel_part2_unique_clean add unique (mrn, relation_mrn)\p\g
-- UT had to get rid of some dupes that survived this far

### UT: showing odd duplication of relationship per mrn/relmrn\p\r
create table reltype_duplicate_ut as
select a.mrn, a.relationship, b.relationship as duprel, b.relation_mrn 
from actual_and_inf_rel_part2_unique a 
     join actual_and_inf_rel_part2_unique b on a.mrn = b.mrn 
          and a.relation_mrn = b.relation_mrn and a.relationship < b.relationship\p\g

delete from  actual_and_inf_rel_part2_unique a
using reltype_duplicate_ut r
where a.mrn = r.mrn and a.relation_mrn = r.relation_mrn and a.relationship = r.duprel;

--    mrn   | relationship |     relationship     | relation_mrn 
-- ---------+--------------+----------------------+--------------
--  8982931 | Parent       | Parent/Aunt/Uncle    | 889221
--  8982931 | Sibling      | Sibling/Cousin       | 1580945
--  889221  | Child        | Child/Nephew/Niece   | 1580945
--  889221  | Child        | Child/Nephew/Niece   | 8982931
--  889221  | Parent       | Parent/Parent-in-law | 125775
--  3082877 | Parent       | Parent/Parent-in-law | 2691335
--  3082877 | Child        | Child/Nephew/Niece   | 3803901
--  2691335 | Child        | Child/Child-in-law   | 3082877
--  1580945 | Parent       | Parent/Aunt/Uncle    | 889221
--  1580945 | Sibling      | Sibling/Cousin       | 8982931
--  3803901 | Parent       | Parent/Aunt/Uncle    | 3082877
--  125775  | Child        | Child/Child-in-law   | 889221
-- (12 rows)

insert into actual_and_inf_rel_part2_unique_clean
(mrn, relationship, relation_mrn, provided_relationship, conflicting_provided_relationship, relationship_specific)
select distinct a.*, null::int, null::text from actual_and_inf_rel_part2_unique a
\p\g

select count(*) as self_referencial_count
from actual_and_inf_rel_part2_unique_clean
where mrn = relation_mrn
\p\g


-- ### Tagging conflicting provided relationships
-- UT zero data in 'provided_relationships_conflicting', first seen in Step2.4
update actual_and_inf_rel_part2_unique_clean a
set conflicting_provided_relationship = 1
from provided_relationships_conflicting b
where (a.mrn = b. mrn) and (a.relation_mrn = b.relation_mrn) and provided_relationship = 1\p\g

-- ### Create new column relationship_specific at actual_and_inf_rel_part2_unique_clean

-- ### Identifying and updating PROVIDED mothers for not conflicting cases
-- UT
-- alter table actual_and_inf_rel_part2_unique_clean add column relationship_specific int null\p\g
/* 
 * These set specific relationship only when the more specific relationship exists.
 * We'll use the late-to-the-party "pt_demog" table to assign gender specific roles
 *
update actual_and_inf_rel_part2_unique_clean a
set relationship_specific = 'Mother'
from pt_matches b, relationship_lookup c
where a.mrn = b.mrn 
      and a.relation_mrn = b.relation_mrn
      and b.relationship = c.relationship
      and a.relationship = 'Parent' 
      and c.relationship_name = 'Mother' 
      and a.provided_relationship = 1 
      and a.conflicting_provided_relationship is NULL 
      and a.relationship_specific is NULL
\p\g
### Identifying and updating PROVIDED fathers for not conflicting cases
\p\r

update actual_and_inf_rel_part2_unique_clean a
set relationship_specific = 'Father'
from pt_matches b, relationship_lookup c
where a.mrn = b.mrn 
      and a.relation_mrn = b.relation_mrn
      and b.relationship = c.relationship
      and a.relationship = 'Parent' 
      and c.relationship_name = 'Father' 
      and a.provided_relationship = 1 
      and a.conflicting_provided_relationship is NULL 
      and a.relationship_specific is NULL
\p\g

-- ### Identifying and updating PROVIDED fathers for not conflicting cases
-- UT: one fell swoop
-- update actual_and_inf_rel_part2_unique_clean a
-- join database.pt_matches b on a.mrn = b.mrn and a.relation_mrn = b.relation_mrn
-- join relationship_lookup c on b.relationship = c.relationship
-- SET a.relationship_specific = 'Father'
-- where a.relationship = 'Parent' 
-- and c.relationship_name = "Father" 
-- and a.provided_relationship = 1 
-- and a.conflicting_provided_relationship is NULL 
-- and a.relationship_specific is NULL\p\g


-- ### Identifying and updating PROVIDED aunts for not conflicting cases
-- UT "Uncle" was not done in original??
update actual_and_inf_rel_part2_unique_clean a
SET relationship_specific = case when d.sex = 'M' then 'Uncle' when d.sex = 'F' then 'Aunt' end
from pt_matches b, pt_demog d
where a.mrn = b.mrn 
      and a.relation_mrn = b.relation_mrn
      and b.relationship = c.relationship
      and a.relationship = 'Aunt/Uncle'
      and a.provided_relationship = 1
      and a.conflicting_provided_relationship is NULL
      and a.relationship_specific is NULL\p\g


-- ### Identifying all "Parent" that are = MOTHER by gender 



/*-- UT re-write specifics as if it matters*/
-- UT There remains the confusion of having both id1 is parent of id2 and id2 is child of id1
update actual_and_inf_rel_part2_unique_clean x
set relationship_specific = case when d.sex = 'F' and x.relationship = 'Parent'      then 'Mother'
                                 when d.sex = 'F' and x.relationship = 'Grandparent' then 'Grandmother'
                                 when d.sex = 'F' and x.relationship = 'Aunt/Uncle'  then 'Aunt'
                                 when d.sex = 'M' and x.relationship = 'Parent'      then 'Father'
                                 when d.sex = 'M' and x.relationship = 'Grandparent' then 'Grandfather'
                                 when d.sex = 'M' and x.relationship = 'Aunt/Uncle'  then 'Uncle'
                            end
from pt_demog d
where x.relationship = 'Parent' and x.relationship_specific is null and x.mrn = d.mrn
\p\g

delete from actual_and_inf_rel_part2_unique_clean where relationship = 'Parent/Aunt/Uncle'\p\g

-- ### Removing Child/Nephew/Niece from pairs that have Child or Nephew/Niece or both 
drop table if exists delete_part2_child_nephew_niece_cases\p\g
create table delete_part2_child_nephew_niece_cases as
select b.mrn, b.relation_mrn, c.relationship
from( select mrn, relation_mrn, count(relationship)
      from ( select distinct mrn, relationship, relation_mrn
             from actual_and_inf_rel_part2_unique_clean
             where relationship like 'Child' or relationship like '%Nephew/Niece'
           ) a
      group by  mrn, relation_mrn
      having count(relationship)>1
     ) b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Child/Nephew/Niece'
\p\g

delete from actual_and_inf_rel_part2_unique_clean where relationship ~* 'in-law'\p\g
-- ### Removing Grandaunt/Granduncle/Grandaunt-in-law/Granduncle-in-law from pairs that have Grandaunt/Granduncle

/*-- ### Creating final table */
drop table if exists actual_and_inf_rel_clean_final\p\g
create table actual_and_inf_rel_clean_final as
select distinct mrn
                , relationship
                , relation_mrn
                , provided_relationship
                , conflicting_provided_relationship
                , relationship_specific
from actual_and_inf_rel_part2_unique_clean
union
select distinct a.relation_mrn as mrn
                , b.relationship_opposite as relationship
                , a.mrn as relation_mrn
                , provided_relationship
                , conflicting_provided_relationship
                , relationship_specific
from actual_and_inf_rel_part2_unique_clean a
join relationships_and_opposites b on a.relationship = b.relationship
\p\g

create index on actual_and_inf_rel_part2_unique_clean(mrn)\p\g
create index on actual_and_inf_rel_part2_unique_clean(relation_mrn)\p\g

/* Testing.  Maybe move this to Step2/7_ */

/* 1: grandparents not parents nor spouses */
select a.relation_mrn, d.sex 
from actual_and_inf_rel_part2_unique_clean a
     join pt_demog d on a.relation_mrn = d.mrn
where a.relationship = 'Grandparent'
      and not exists(select 1 from actual_and_inf_rel_part2_unique_clean b 
                     where a.relation_mrn = b.relation_mrn and b.relationship in ( 'Parent', 'Spouse'))
\p\g                     
                     

/* 1.b with derivatives*/
select a.relation_mrn as grand, a.relationship, a.mrn as g2, d.sex, b.relationship, b.mrn 
from actual_and_inf_rel_part2_unique_clean a
     join pt_demog d on a.relation_mrn = d.mrn
     join actual_and_inf_rel_part2_unique_clean b on b.relation_mrn = d.mrn
where a.relationship = 'Grandparent'
      and b.relationship in ( 'Parent', 'Spouse')\p\g

/*
 * DANGER, DANGER, DANGER
 */
/*2: the Parent is right to left, the Child is left to right\p\g Unify that (right to left) */
drop table if exists forward_rtl\p\g
create table forward_rtl as 
select mrn, relationship, relation_mrn 
from actual_and_inf_rel_part2_unique_clean 
where relationship != 'Child'\p\g
insert into forward_rtl (mrn, relationship, relation_mrn) 
select relation_mrn, 'Parent', mrn 
from actual_and_inf_rel_part2_unique_clean 
where relationship = 'Child'\p\g
delete from forward_rtl where relationship = 'Grandchild'\p\g

/* 2.a two grandparents one child*/
select g.*
from forward_rtl f
join forward_rtl g on f.mrn = g.mrn and f.relation_mrn != g.relation_mrn
where f.relationship = 'Grandparent' and g.relationship = 'Grandparent'
\p\g
-- zero rows

/* 2.b two parents one child */
select f.mrn as child, f.relation_mrn as mom, g.relation_mrn as dad
from forward_rtl f
join pt_demog fd on f.relation_mrn = fd.mrn
join forward_rtl g on f.mrn = g.mrn and f.relation_mrn != g.relation_mrn
join pt_demog gd on g.relation_mrn = gd.mrn
where gd.sex = 'M' and fd.sex ='F'
\p\g
/* 2.c single parents */
select f.*, d.sex
from forward_rtl f
join pt_demog d on f.relation_mrn = d.mrn
where relationship = 'Parent'
      and not exists (select 1 from forward_rtl g where g.mrn = f.mrn and g.relation_mrn != f.relation_mrn)
\p\g      


/* PAYLOAD generated in runSteps.sh*/

