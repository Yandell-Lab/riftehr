-- ### Create table to identify families
/* Starting material */

select count(*) "Total Rels pre family" from actual_and_inf_rel_clean_final
\p\g
select count(*) "Total MRN pre family"
from (select mrn from actual_and_inf_rel_clean_final 
      union 
      select relation_mrn from actual_and_inf_rel_clean_final) a 
\p\g

drop table if exists all_relationships_to_generate_family_id\p\g
create table all_relationships_to_generate_family_id as 
select mrn, relationship, relation_mrn
from actual_and_inf_rel_clean_final
where relationship != 'Spouse' 
      and relationship != 'Child-in-law' 
      and relationship != 'Parent-in-law'
      and relationship != 'Aunt/Uncle/Aunt-in-law/Uncle-in-law' 
      and relationship != 'Parent/Parent-in-law' 
      and relationship != 'Child/Child-in-law' 
      and relationship != 'Greataunt/Greatuncle/Greataunt-in-law/Greatuncle-in-law' 
      and relationship != 'Grandchild/Greatchild-in-law' 
      and relationship != 'Grandnephew/Grandniece/Grandnephew-in-law/Grandniece-in-law' 
      and relationship != 'Grandparent/Grandparent-in-law' 
      and relationship != 'Great-grandchild/Great-grandchild-in-law' 
      and relationship != 'Great-grparent/Great-grandparent-in-law' 
      and relationship != 'Nephew/Niece/Nephew-in-law/Niece-in-law' 
      and relationship != 'Sibling/Sibling-in-law'
\p\g
/*
 * all_relationships_to_generate_family_id is copied to file in runStep.sh
 */
