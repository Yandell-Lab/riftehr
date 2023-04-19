-- ### Identify conflicting relationships

create unique index on family_ids(family_id, individual_id)
\p\g
create unique index on family_ids(individual_id)
\p\g

delete from actual_and_inf_rel_clean_final where relationship is null
\p\g


/* This tallying is faulty.  The "actual_and_inf_rel_clean_final" is
 * actually, finally pretty clean but it does have extra for records
 * - spouses in twice (a.mrn = b.relation_mrn and b.mrn = a.relation_mrn)
 * - siblings in twice (a.mrn = b.relation_mrn and b.mrn = a.relation_mrn)
 * - true conflicts undetected:(a.mrn = b.relation_mrn and b.mrn = a.relation_mrn and a.relationship != b.relationship)
*/
drop table if exists actual_and_inf_rel_clean_final_count_rels\p\g
create table actual_and_inf_rel_clean_final_count_rels as
select f.family_id, a.mrn, relation_mrn, count(distinct relationship) as num_uniq_rels
from family_ids f
join actual_and_inf_rel_clean_final a on f.individual_id = a.mrn
group by a.mrn, a.relation_mrn, f.family_id
\p\g


/* The penchant for summing booleans was at play here.*/
drop table if exists family_ids_count_conflicted\p\g
create table family_ids_count_conflicted as
select family_id
       , count(distinct mrn) as num_individuals
       , sum(case when num_uniq_rels = 1 then 0 else 1 end) as num_rels_conflicted
from actual_and_inf_rel_clean_final_count_rels
group by family_id
\p\g

