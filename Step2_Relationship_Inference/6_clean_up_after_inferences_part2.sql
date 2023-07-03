
-- ### Import output_patient_relations_w_opposites_part2 as actual_and_inf_rel_part2 into the database
-- UT: move the copy to external script to parameterize the working directory
-- \copy actual_and_inf_rel_part2 from ~/gits/github/ds-ehr/data/output_patient_relations_w_opposites_part2.csv csv

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

-- ### Create new column conflicting_provided_relationship at actual_and_inf_rel_part2_unique_clean
-- UT this has been done in the global DDL but we have to diddle with uniqueness constraint
-- UT alter table actual_and_inf_rel_part2_unique_clean drop constraint if exists actual_and_inf_rel_part2_unique_clean_mrn_key\p\g
-- UT the DDL has been updated
-- UT alter table actual_and_inf_rel_part2_unique_clean add unique (mrn, relation_mrn)\p\g
-- UT had to get rid of some dupes that survived this far

### UT: showing odd duplication of relationship per mrn/relmrn\p\r
drop table if exists reltype_duplicate_ut
\p\g
create table reltype_duplicate_ut as
select a.mrn, a.relationship, b.relationship as duprel, b.relation_mrn 
from actual_and_inf_rel_part2_unique a 
     join actual_and_inf_rel_part2_unique b on a.mrn = b.mrn 
          and a.relation_mrn = b.relation_mrn and a.relationship < b.relationship
\p\g
select relationship, duprel, count(*) 
from reltype_duplicate_ut 
group by relationship, duprel 
order by count(*) desc
\p\g

delete from actual_and_inf_rel_part2_unique a
using reltype_duplicate_ut r
where a.mrn = r.mrn and a.relation_mrn = r.relation_mrn and a.relationship = r.duprel
\p\g

drop table if exists actual_and_inf_rel_part2_unique_clean\p\g
create table actual_and_inf_rel_part2_unique_clean as
select u.*, null::int as conflicting_provided_relationship, null::text as relationship_specific 
from actual_and_inf_rel_part2_unique u
\p\g

create index on actual_and_inf_rel_part2_unique_clean(mrn)
\p\g

create index on actual_and_inf_rel_part2_unique_clean(relation_mrn);
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
where (a.mrn = b. mrn) and (a.relation_mrn = b.relation_mrn) and provided_relationship = 1
\p\g


-- ### Create new column relationship_specific at actual_and_inf_rel_part2_unique_clean

-- ### Identifying and updating PROVIDED mothers for not conflicting cases
-- UT
-- alter table actual_and_inf_rel_part2_unique_clean add column relationship_specific int null\p\g
/* 
 * These set specific relationship only when the more specific relationship exists.
 * We'll use the late-to-the-party "pt_demog" table to assign gender specific roles
 */
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
where x.relationship_specific is null 
      and x.mrn = d.mrn
\p\g

-- UT

-- Now we try the Child Niece/Nephew relations, but this risks
-- confusing which side of the relationship is which.  We believe the
-- relationships are ordered such that mrn is not younger than
-- relation_mrn (which doesn't hold in previous sql)

update actual_and_inf_rel_part2_unique_clean x
set relationship_specific = case when d.sex = 'F' and x.relationship = 'Child'        then 'Mother'
                                 when d.sex = 'F' and x.relationship = 'Nephew/Niece' then 'Aunt'
                                 when d.sex = 'M' and x.relationship = 'Child'        then 'Father'
                                 when d.sex = 'M' and x.relationship = 'Nephew/Niece' then 'Uncle'
                            end
from pt_demog d
where x.relationship_specific is null 
      and x.conflicting_provided_relationship is null
      and x.mrn = d.mrn
\p\g

-- UT: count specific type just loaded
select relationship_specific, count(*) as tally from actual_and_inf_rel_part2_unique_clean group by relationship_specific
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
create table actual_and_inf_rel_clean_final
as
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


/* PAYLOAD generated in runSteps.sh*/

