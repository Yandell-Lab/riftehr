
-- ### Import output_patient_relations_w_opposites_part2 as actual_and_inf_rel_part2 into the database
-- UT
\copy actual_and_inf_rel_part2 from ~/gits/github/ds-ehr/data/output_patient_relations_w_opposites_part2.csv csv

-- ### Creating table with unique pairs and relationships
drop table if exists actual_and_inf_rel_part2_unique;
create table actual_and_inf_rel_part2_unique as
select  a.mrn
        , a.relationship
        , a.relation_mrn
        , case when b.mrn is null then cast(null as int)
               when b.mrn is not null then cast(1 as int)
               end as provided_relationship
from actual_and_inf_rel_part2 a 
     left join patient_relations_w_opposites_clean b on a.mrn = b.mrn 
          and a.relationship = b.relationship 
          and a.relation_mrn = b.relation_mrn
;


-- ### Add new field to "actual_and_inf_rel_part2_unique" called provided_relationship (INT)
update actual_and_inf_rel_part2_unique a
join patient_relations_w_opposites_clean b on a.mrn = b.mrn and a.relationship = b.relationship and a.relation_mrn = b.relation_mrn
set provided_relationship = 1;


-- ### Duplicate table actual_and_inf_rel_part2_unique and name it actual_and_inf_rel_part2_unique_clean


-- ### Add indexes


-- ### Identifying mrn = to relation_mrn (Self) <--- 0 cases! 
select count(*) --*
from actual_and_inf_rel_part2_unique_clean
where mrn = relation_mrn;


-- ### Create new column conflicting_provided_relationship at actual_and_inf_rel_part2_unique_clean
-- UT this has been done in the global DDL but we have to diddle with uniqueness constraint
alter table actual_and_inf_rel_part2_unique_clean drop constraint actual_and_inf_rel_part2_unique_clean_mrn_key;
-- UT the DDL has been updated
alter table actual_and_inf_rel_part2_unique_clean add unique (mrn, relation_mrn);

-- UT had to get rid of some dupes that survived this far
-- select a.mrn, a.relationship, b.relationship, b.relation_mrn 
-- from actual_and_inf_rel_part2_unique a 
--      join actual_and_inf_rel_part2_unique b on a.mrn = b.mrn 
--           and a.relation_mrn = b.relation_mrn and a.relationship < b.relationship;
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
select a.*, null, null from actual_and_inf_rel_part2_unique a
;


-- ### Tagging conflicting provided relationships
-- UT zero data in 'provided_relationships_conflicting', first seen in Step2.4
update actual_and_inf_rel_part2_unique_clean a
set conflicting_provided_relationship = 1
from provided_relationships_conflicting b
where (a.mrn = b. mrn) and (a.relation_mrn = b.relation_mrn) and provided_relationship = 1;

-- ### Create new column relationship_specific at actual_and_inf_rel_part2_unique_clean

-- ### Identifying and updating PROVIDED mothers for not conflicting cases
-- UT
-- alter table actual_and_inf_rel_part2_unique_clean add column relationship_specific int null;


update actual_and_inf_rel_part2_unique_clean a
set relationship_specific = c.relationship_name --'Mother' or 'Father'
from pt_matches b,relationship_lookup c
where a.mrn = b.mrn 
      and a.relation_mrn = b.relation_mrn
      and b.relationship = c.relationship
      and a.relationship = 'Parent' 
      and a.provided_relationship = 1 
      and a.conflicting_provided_relationship is NULL 
      and a.relationship_specific is NULL
;

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
-- and a.relationship_specific is NULL;


-- ### Identifying and updating PROVIDED aunts for not conflicting cases
-- UT "Uncle" was not done??
update actual_and_inf_rel_part2_unique_clean a
SET a.relationship_specific = c.relationship_name
from pt_matches b, relationship_lookup c
where a.mrn = b.mrn 
      and a.relation_mrn = b.relation_mrn
      and b.relationship = c.relationship
      and a.relationship = 'Aunt/Uncle' 
      and a.provided_relationship = 1 
      and a.conflicting_provided_relationship is NULL 
      and a.relationship_specific is NULL;


-- ### Identifying all "Parent" that are = MOTHER by gender 
/*
Give me a break;
update actual_and_inf_rel_part2_unique_clean x
join (
select d.relation_mrn
from (
select c.relation_mrn, count(c.relation_mrn)
from (
select distinct a.relation_mrn, b.SEX
from actual_and_inf_rel_part2_unique_clean a
join database.pt_demog b on (a.relation_mrn = b.mrn)
where a.relationship = "Parent" and a.relationship_specific is NULL
) c
group by c.relation_mrn
having count(c.relation_mrn) =1 
) d
join database.pt_demog e on d.relation_mrn = e.mrn
where e.SEX = 'F'
)y on x.relation_mrn = y.relation_mrn
SET x.relationship_specific = 'Mother' 
where x.relationship = 'Parent' and x.relationship_specific is NULL;
*/

-- UT There remains the confusion of having both id1 is parent of id2 and id2 is child of id1
update actual_and_inf_rel_part2_unique_clean x
set relationship_specific = case when d.sex = 'F' then 'Mother'
                                 when d.sex = 'M' then 'Father'
                            end
from pt_demog d
where x.relationship = 'Parent' and x.relationship_specific is null and x.mrn = d.mrn
;

-- ### Identifying all "Parent" that are = FATHER by gender 
/*
see above
update actual_and_inf_rel_part2_unique_clean x
join (
select d.relation_mrn
from (
select c.relation_mrn, count(c.relation_mrn)
from (
select distinct a.relation_mrn, b.SEX
from actual_and_inf_rel_part2_unique_clean a
join database.pt_demog b on (a.relation_mrn = b.mrn)
where a.relationship = "Parent" and a.relationship_specific is NULL
) c
group by c.relation_mrn
having count(c.relation_mrn) =1 
) d
join database.pt_demog e on d.relation_mrn = e.mrn
where e.SEX = 'M'
)y on x.relation_mrn = y.relation_mrn
SET x.relationship_specific = 'Father' 
where x.relationship = "Parent" and x.relationship_specific is NULL;
*/

-- UT There remains the confusion of having both id1 is parent of id2 and id2 is child of id1
update actual_and_inf_rel_part2_unique_clean x
set relationship_specific = case when d.sex = 'F' then 'Aunt'
                                 when d.sex = 'M' then 'Uncle'
                            end
from pt_demog d
where x.relationship = 'Aunt/Uncle' and x.relationship_specific is null and x.mrn = d.mrn
;


-- ### Identifying all "Aunt/Uncle" that are = Aunt by gender 
/* as above
update actual_and_inf_rel_part2_unique_clean x
join (
select d.relation_mrn
from (
select c.relation_mrn, count(c.relation_mrn)
from (
select distinct a.relation_mrn, b.SEX
from actual_and_inf_rel_part2_unique_clean a
join database.pt_demog b on (a.relation_mrn = b.mrn)
where a.relationship = "Aunt/Uncle" and a.relationship_specific is NULL
) c
group by c.relation_mrn
having count(c.relation_mrn) =1 
) d
join database.pt_demog e on d.relation_mrn = e.mrn
where e.SEX = 'F'
)y on x.relation_mrn = y.relation_mrn
SET x.relationship_specific = 'Aunt' 
where x.relationship = "Aunt/Uncle" and x.relationship_specific is NULL;

-- ### Identifying all "Aunt/Uncle" that are = Uncle by gender 

update actual_and_inf_rel_part2_unique_clean x
join (
select d.relation_mrn
from (
select c.relation_mrn, count(c.relation_mrn)
from (
select distinct a.relation_mrn, b.SEX
from actual_and_inf_rel_part2_unique_clean a
join database.pt_demog b on (a.relation_mrn = b.mrn)
where a.relationship = "Aunt/Uncle" and a.relationship_specific is NULL
) c
group by c.relation_mrn
having count(c.relation_mrn) =1 
) d
join database.pt_demog e on d.relation_mrn = e.mrn
where e.SEX = 'M'
)y on x.relation_mrn = y.relation_mrn
SET x.relationship_specific = 'Uncle' 
where x.relationship = "Aunt/Uncle" and x.relationship_specific is NULL;
*/

-- ### Removing Parent/Aunt/Uncle from pairs that have Parent or
-- ### Aunt/Uncle (count = 2) and cases that have Parent/Aunt/Uncle
-- ### and Parent and Aunt/Uncle (count = 3)

/* We don't have and 'Parent/Aunt/Uncle' at this point but still this is an overly complex way to delete any such record

drop table if exists delete_part2_parent_aunt_uncle_cases;
create table delete_part2_parent_aunt_uncle_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, relation_mrn
from actual_and_inf_rel_part2_unique_clean
where relationship like 'Parent' or relationship like '%Aunt/Uncle'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Parent/Aunt/Uncle'
;


-- ### Delete "Parent/Aunt/Uncle that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_parent_aunt_uncle_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);
*/
delete from actual_and_inf_rel_part2_unique_clean where relationship = 'Parent/Aunt/Uncle';

-- ### Removing Child/Nephew/Niece from pairs that have Child or Nephew/Niece or both 
drop table if exists delete_part2_child_nephew_niece_cases;
create table delete_part2_child_nephew_niece_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, `relation_mrn`
from actual_and_inf_rel_part2_unique_clean
where relationship like 'Child' or relationship like '%Nephew/Niece'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Child/Nephew/Niece'
;


/*
as above
-- ### Delete Child/Nephew/Niece that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_child_nephew_niece_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);


-- ### Removing Sibling/Cousin from pairs that have Child or Nephew/Niece or both
drop table if exists delete_part2_sibling_cousin_cases;
create table delete_part2_sibling_cousin_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, `relation_mrn`
from actual_and_inf_rel_part2_unique_clean
where relationship like 'Sibling' or relationship like '%Cousin'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Sibling/Cousin'
;

-- ### Delete Sibling/Cousin that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_sibling_cousin_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);
*/


-- ### Removing Parent/Parent-in-law from pairs that have Parent 
drop table if exists delete_part2_parent_in_law_cases;
create table delete_part2_parent_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, `relation_mrn`
from actual_and_inf_rel_part2_unique_clean
where relationship ='Parent' or relationship like 'Parent/Parent%'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Parent/Parent%'
;

-- ### Delete Parent/Parent-in-law that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_parent_in_law_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);

-- ### Removing Child/Child-in-law from pairs that have Child
/*
drop table if exists delete_part2_child_in_law_cases;
create table delete_part2_child_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, `relation_mrn`
from actual_and_inf_rel_part2_unique_clean
where relationship ='Child' or relationship like 'Child/Child%'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Child/Child%'
;

-- ### Delete Child/Child-in-law that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_child_in_law_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);
*/

-- UT select * from actual_and_inf_rel_part2_unique_clean where mrn in ('3697602', '3803901', '3803901', '2691335','3082877');
-- UT    mrn   |     relationship     | relation_mrn | provided_relationship | conflicting_provided_relationship | relationship_specific 
-- UT ---------+----------------------+--------------+-----------------------+-----------------------------------+-----------------------
-- UT  3697602 | Child                | 3803901      |                     1 |                                   | 
-- UT  3697602 | Parent/Parent-in-law | 2691335      |                       |                                   | 
-- UT  3697602 | Spouse               | 3082877      |                       |                                   | 
-- UT  3697602 | Spouse               | 3736962      |                       |                                   | 
-- UT  3082877 | Child                | 3803901      |                     1 |                                   | 
-- UT  3082877 | Spouse               | 3697602      |                       |                                   | 
-- UT  3082877 | Spouse               | 3736962      |                       |                                   | 
-- UT  2691335 | Grandchild           | 3803901      |                       |                                   | 
-- UT  2691335 | Child                | 3082877      |                     1 |                                   | 
-- UT  2691335 | Child/Child-in-law   | 3697602      |                       |                                   | 
-- UT  2691335 | Child/Child-in-law   | 3736962      |                       |                                   | 
-- UT  3803901 | Grandparent          | 2691335      |                       |                                   | 
-- UT  3082877 | Parent               | 2691335      |                       |                                   | Mother
-- UT  3803901 | Parent               | 3697602      |                       |                                   | Father
-- UT  3803901 | Parent               | 3082877      |                       |                                   | Father
-- UT  3803901 | Parent               | 3736962      |                       |                                   | Father
-- UT (16 rows)
-- UT 
-- UT It's unclear what parent-in-law means but we get rid of them anyway
-- UT
-- UT
-- UT select * from actual_and_inf_rel_part2_unique_clean where relationship  ~* 'in-law';
-- UT    mrn   |     relationship     | relation_mrn | provided_relationship | conflicting_provided_relationship | relationship_specific 
-- UT ---------+----------------------+--------------+-----------------------+-----------------------------------+-----------------------
-- UT  3697602 | Parent/Parent-in-law | 2691335      |                       |                                   | 
-- UT  2691335 | Child/Child-in-law   | 3697602      |                       |                                   | 
-- UT  2691335 | Child/Child-in-law   | 3736962      |                       |                                   | 
-- UT  3736962 | Parent/Parent-in-law | 2691335      |                       |                                   | 
-- UT (4 rows)
-- UT
delete from actual_and_inf_rel_part2_unique_clean where relationship ~* 'in-law';

-- UT We have only these 'grand' relationships
-- UT select distinct relationship from actual_and_inf_rel_part2_unique_clean where relationship ~* 'grand';
-- UT  relationship 
-- UT --------------
-- UT  Grandparent
-- UT  Grandchild
-- UT (2 rows)
-- UT 

-- ### Removing Grandaunt/Granduncle/Grandaunt-in-law/Granduncle-in-law from pairs that have Grandaunt/Granduncle
/*drop table if exists delete_part2_grandaunt_in_law_cases;
create table delete_part2_grandaunt_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, `relation_mrn`
from actual_and_inf_rel_part2_unique_clean
where relationship ='Grandaunt/Granduncle' or relationship like 'Grandaunt/Granduncle/Grandaunt%'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Grandaunt/Granduncle/Grandaunt%'
;

-- ### Delete Grandaunt/Granduncle/Grandaunt-in-law/Granduncle-in-law that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_grandaunt_in_law_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);

-- ### Removing Grandchild/Grandchild-in-law from pairs that have Grandchild
drop table if exists delete_part2_grandchild_in_law_cases;
create table delete_part2_grandchild_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, `relation_mrn`
from actual_and_inf_rel_part2_unique_clean
where relationship ='Grandchild' or relationship like 'Grandchild/Grandchild%'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Grandchild/Grandchild%'
;

-- ### Delete Grandchild/Grandchild-in-law that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_grandchild_in_law_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);


-- ### Removing Grandnephew/Grandniece/Grandnephew-in-law/Grandniece-in-law from pairs that have Grandnephew/Grandniece
drop table if exists delete_part2_grandnephew_in_law_cases;
create table delete_part2_grandnephew_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, `relation_mrn`
from actual_and_inf_rel_part2_unique_clean
where relationship ='Grandnephew/Grandniece' or relationship like 'Grandnephew/Grandniece/Grandnephew%'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Grandnephew/Grandniece/Grandnephew%'
;

-- ### Delete Grandnephew/Grandniece/Grandnephew-in-law/Grandniece-in-law that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_grandnephew_in_law_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);



-- ### Removing Grandparent/Grandparent-in-law from pairs that have Grandparent
drop table if exists delete_part2_grandparent_in_law_cases;
create table delete_part2_grandparent_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, `relation_mrn`
from actual_and_inf_rel_part2_unique_clean
where relationship ='Grandparent' or relationship like 'Grandparent/Grandparent%'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Grandparent/Grandparent%'
;

-- ### Delete Grandparent/Grandparent-in-law that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_grandparent_in_law_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);


-- ### Removing Great-grandchild/Great-grandchild-in-law from pairs that have Great-grandchild
drop table if exists delete_part2_greatgrandchild_in_law_cases;
create table delete_part2_greatgrandchild_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, `relation_mrn`
from actual_and_inf_rel_part2_unique_clean
where relationship ='Great-grandchild' or relationship like 'Great-grandchild/Great-grandchild%'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Great-grandchild/Great-grandchild%'
;

-- ### Delete Great-grandchild/Great-grandchild-in-law that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_greatgrandchild_in_law_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);


# Great-grandparent/Great-grandparent-in-law

-- ### Removing Great-grandparent/Great-grandparent-in-law from pairs that have Great-grandparent
drop table if exists delete_part2_greatgrandparent_in_law_cases;
create table delete_part2_greatgrandparent_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, `relation_mrn`
from actual_and_inf_rel_part2_unique_clean
where relationship ='Great-grandparent' or relationship like 'Great-grandparent/Great-grandparent%'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Great-grandparent/Great-grandparent%'
;

-- ### Delete Great-grandparent/Great-grandparent-in-law that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_greatgrandparent_in_law_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);


# Nephew/Niece/Nephew-in-law/Niece-in-law

-- ### Removing Nephew/Niece/Nephew-in-law/Niece-in-law from pairs that have Nephew/Niece
drop table if exists delete_part2_nephew_in_law_cases;
create table delete_part2_nephew_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, `relation_mrn`
from actual_and_inf_rel_part2_unique_clean
where relationship ='Nephew/Niece' or relationship like 'Nephew/Niece/Nephew%'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Nephew/Niece/Nephew%'
;

-- ### Delete Nephew/Niece/Nephew-in-law/Niece-in-law that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_nephew_in_law_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);


# Sibling/Sibling-in-law

-- ### Removing Sibling/Sibling-in-law from pairs that have Sibling
drop table if exists delete_part2_sibling_in_law_cases;
create table delete_part2_sibling_in_law_cases as
select b.mrn, b.relation_mrn, c.relationship
from(
select mrn, relation_mrn, count(relationship)
from (
select distinct mrn, relationship, `relation_mrn`
from actual_and_inf_rel_part2_unique_clean
where relationship ='Sibling' or relationship like 'Sibling/Sibling%'
)a
group by  mrn, relation_mrn
having count(relationship)>1
)b
join actual_and_inf_rel_part2_unique_clean c on (b.mrn = c.mrn) and (b.relation_mrn = c.relation_mrn)
where c.relationship like 'Sibling/Sibling%'
;

-- ### Delete Sibling/Sibling-in-law that can be excluded from the table unique_clean
delete a
from actual_and_inf_rel_part2_unique_clean a
join delete_part2_sibling_in_law_cases b on (a.mrn = b.mrn) and (a.relation_mrn = b.relation_mrn) and (a.relationship = b.relationship);
*/


-- ### Creating final table 
drop table if exists actual_and_inf_rel_clean_final;
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
;

create index on actual_and_inf_rel_part2_unique_clean(mrn);
create index on actual_and_inf_rel_part2_unique_clean(relation_mrn);

/* testing */

/* 1: grandparents not parents nor spouses */
select a.relation_mrn, d.sex 
from actual_and_inf_rel_part2_unique_clean a
     join pt_demog d on a.relation_mrn = d.mrn
where a.relationship = 'Grandparent'
      and not exists(select 1 from actual_and_inf_rel_part2_unique_clean b 
                     where a.relation_mrn = b.relation_mrn and b.relationship in ( 'Parent', 'Spouse'))

/* 1.b with derivatives*/
select a.relation_mrn as grand, a.relationship, a.mrn as g2, d.sex, b.relationship, b.mrn 
from actual_and_inf_rel_part2_unique_clean a
     join pt_demog d on a.relation_mrn = d.mrn
     join actual_and_inf_rel_part2_unique_clean b on b.relation_mrn = d.mrn
where a.relationship = 'Grandparent'
      and b.relationship in ( 'Parent', 'Spouse');

/*2: the Parent is right to left, the Child is left to right; Unify that (right to left) */
drop table if exists forward_rtl;
create table forward_rtl as 
select mrn, relationship, relation_mrn 
from actual_and_inf_rel_part2_unique_clean 
where relationship != 'Child';
insert into forward_rtl (mrn, relationship, relation_mrn) 
select relation_mrn, 'Parent', mrn 
from actual_and_inf_rel_part2_unique_clean 
where relationship = 'Child';
delete from forward_rtl where relationship = 'Grandchild';

/* 2.a two grandparents one child*/
select g.*
from forward_rtl f
join forward_rtl g on f.mrn = g.mrn and f.relation_mrn != g.relation_mrn
where f.relationship = 'Grandparent' and g.relationship = 'Grandparent'
-- zero rows

/* 2.b two parents one child */
select f.mrn as child, f.relation_mrn as mom, g.relation_mrn as dad
from forward_rtl f
join pt_demog fd on f.relation_mrn = fd.mrn
join forward_rtl g on f.mrn = g.mrn and f.relation_mrn != g.relation_mrn
join pt_demog gd on g.relation_mrn = gd.mrn
where gd.sex = 'M' and fd.sex ='F'
;
-- 29 rows
/* 2.c single parents */

select f.*, d.sex
from forward_rtl f
join pt_demog d on f.relation_mrn = d.mrn
where relationship = 'Parent'
      and not exists (select 1 from forward_rtl g where g.mrn = f.mrn and g.relation_mrn != f.relation_mrn)
;      
--235 rows


with recursive tree (ego, ma, pa, sex, gen) as
( 
/*singleton founder*/
(select distinct a1.mrn as ego
         , a1.relation_mrn as ma
         , null::text -- a2.relation_mrn as pa
         ,e.sex
         ,0 as gen
  from pt_demog d
  join forward_rtl a1 on a1.relation_mrn = d.mrn
  join pt_demog e on a1.mrn = e.mrn
  where d.sex = 'F'
        and a1.relationship= 'Parent'
        and not exists( select 1 from forward_rtl b 
                        where a1.relation_mrn = b.mrn and b.relationship = 'Parent')
        and not exists( select 1 from forward_rtl c where a1.mrn = c.mrn 
                                                    and a1.relation_mrn != c.relation_mrn 
                                                    and c.relationship = 'Parent')
  union
  select distinct a1.mrn as ego
         , null::text -- a2.relation_mrn as ma
         , a1.relation_mrn as pa
         ,e.sex
         ,0 as gen
  from pt_demog d
  join forward_rtl a1 on a1.relation_mrn = d.mrn
  join pt_demog e on a1.mrn = e.mrn
  where d.sex = 'M'
        and a1.relationship= 'Parent'
        and not exists( select 1 from forward_rtl b 
                        where a1.relation_mrn = b.mrn and b.relationship = 'Parent')
        and not exists( select 1 from forward_rtl c where a1.mrn = c.mrn 
                                                    and a1.relation_mrn != c.relation_mrn 
                                                    and c.relationship = 'Parent')
-- TODO: account for possible founder pairs
)
union all
 (select h.mrn, t.ego, null as pa, d.sex, t.gen + 1
 from tree t
      join forward_rtl h on t.ego = h.relation_mrn 
      join pt_demog d on h.mrn = d.mrn
 )
)
select * from tree order by gen;






select distinct a1.mrn as ego
         , a1.relation_mrn as ma
         , null::text -- a2.relation_mrn as pa
         ,e.sex
         ,0 as gen
  from pt_demog d
  join forward_rtl a1 on a1.relation_mrn = d.mrn
  join pt_demog e on a1.mrn = e.mrn
  where d.sex = 'F'
  and not exists(select 1 from forward_rtl b 
                     where a1.relation_mrn = b.mrn and b.relationship = 'Parent');

  union
  select distinct a1.mrn as ego
         , null::text -- a2.relation_mrn as pa
         , a1.relation_mrn as pa
         ,e.sex
         ,0 as gen
  from pt_demog d
  join forward_rtl a1 on a1.relation_mrn = d.mrn
  join pt_demog e on a1.mrn = e.mrn
  where d.sex = 'M'
  and not exists(select 1 from forward_rtl b 
                     where a1.relation_mrn = b.mrn and b.relationship = 'Parent');
;


  left join forward_rtl a2 on a1.mrn = a2.mrn and a1.relation_mrn != a2.relation_mrn
  left join pt_demog f on a2.relation_mrn = f.mrn 
  where a1.relationship = 'Parent'
      and e.sex = 'F'
      and e.sex = 'M'
      and not exists(select 1 from forward_rtl b 
                     where a1.relation_mrn = b.mrn and b.relationship = 'Parent');



  union
select distinct a.mrn as ego
         , a.relation_mrn as ma
         , null as pa
         ,e.sex
         ,0 as gen
  from forward_rtl a
  join pt_demog d on a.relation_mrn = d.mrn
  join forward_rtl b on d.mrn = b.relation_mrn
  join pt_demog e on b.relation_mrn = e.mrn
  where a.relationship = 'Parent'
      and e.sex = 'M'
      and not exists(select 1 from forward_rtl b 
                     where a.relation_mrn = b.mrn and b.relationship = 'Parent');
  
select a.mrn::int as ego, a.relation_mrn::int as ma, null::int as pa, 1::int as gen
  from actual_and_inf_rel_part2_unique_clean a 
  join pt_demog d on a.relation_mrn = d.mrn
  join actual_and_inf_rel_part2_unique_clean b and d.mrn = b.relation_mrn
  where a.relationship = 'Parent' 
        and b.relationship = 'Spouse'
        and d.sex = 'F'
        and not exists (select 1 from actual_and_inf_rel_part2_unique_clean b where b.mrn = a.relation_mrn and b.relationship = 'Parent')
;


 union all
  select c.mrn, c.relationship, c.relation_mrn, t.gen+1
  from tree t join actual_and_inf_rel_part2_unique_clean c
       on t.mrn = c.relation_mrn
       where c.relationship = 'Parent'
)       
select * from tree order by gen desc 
;



