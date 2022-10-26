/* 
 * showing relationships which should not have same-age members
 * could include aunt/uncle in excludes?
 */
with distro as (
select a.relation,
       case when m.year < r.year then 'older'
            when m.year > r.year then 'younger'
            else 'equal'
            end as direction,
       count(*) as tally
from all_relationship_s7 a 
     join pt_demog m on a.mrn = m.mrn
     join pt_demog r on a.relation_mrn = r.mrn
group by a.relation, direction
)
select * from distro
where direction = 'equal' 
      and relation not in ('Cousin', 'Brother', 'Sister', 'Sibling')
      and relation !~ '^N.*e'
\p\g      

/* PARENT out of age range */
select (r.year - m.year)/5 + 1 as years_mod5
       , count(*) as n
from  all_relationship_s7 a
      join pt_demog m on a.mrn = m.mrn
      join pt_demog r on a.relation_mrn = r.mrn
where  a.relation = 'Child'
       and m.mrn != r.mrn
       and r.year - m.year not between 15 and 50
group by (r.year - m.year)/5 + 1
order by years_mod5
\p\g
