-- ### Identify conflicting relationships
drop table if exists actual_and_inf_rel_clean_final_count_rels\p\g
create table actual_and_inf_rel_clean_final_count_rels as
select f.id, a.mrn, relation_mrn, count(distinct relationship) as num_uniq_rels
from family_ids f
join actual_and_inf_rel_clean_final a on f.id = a.mrn
group by a.mrn, a.relation_mrn, f.id\p\g
​
drop table if exists family_ids_count_conflicted\p\g

create table family_ids_count_conflicted as
       select id
       , count(distinct mrn) as num_individuals
--       , sum(num_uniq_rels > 1 ) as num_rels_conflicted
       , sum(num_uniq_rels) as num_rels_conflicted
from actual_and_inf_rel_clean_final_count_rels
group by id\p\g
