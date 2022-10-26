

/*
 * What can we get from only using "Child" relations?
 */


/* ON HOLD
begin;
with stepma as (
select a.*
from all_relationship_s7 a join all_relationship_s7 b on a.mrn = b.mrn and a.relation_mrn = b.relation_mrn
where a. relation = 'Child' and b.relation = 'Step Child'
      and exists (select 1 from all_relationship_s7 d where d.relation_mrn = a.relation_mrn and d.relation = 'Child' and d.mrn != a.mrn)
)
delete from all_relationship_s7 c
using stepma s where c.mrn = s.mrn
\p\g
*/
/* FAM ZERO for testing: leaf generation */
with leaf(fam, mrn, ma, pa, sex, gen)as (
     select f.family_id as fam
            , a.relation_mrn as mrn
            , case when e.sex = 'F' then e.mrn end as ma
            , case when e.sex = 'M' then e.mrn end as pa
            , d.sex
            , 1 as gen
     from all_relationship_s7 a
          join family_ids f on a.mrn = f.individual_id
          join pt_demog e on a.mrn = e.mrn /*parent*/
          join pt_demog d on a.relation_mrn = d.mrn /*child*/
     where a.relation = 'Child' 
           and not exists (select 1 from all_relationship_s7 b where a.relation_mrn = b.mrn and b.relation = 'Child')
           and f.family_id = 0
)
select d.fam, d.mrn, m.ma, d.pa, d.sex
from leaf d join leaf m on d.mrn = m.mrn and d.fam = m.fam
where d.ma is null and m.pa is null
limit 100
\p\g

/* 
 * try top down, because bottom up does not (can not) get the ultimate parent as an ego 
 */
drop table if exists mother_desc;
create table mother_desc as 
with recursive mafind(fam, ego, ma, pa, sex, gen) as (
     select distinct f.family_id as fam
            , a.mrn as ego
            , null::text as ma
            , null::text as pa
            , d.sex
            , 1 as gen
     from all_relationship_s7 a
          join family_ids f on a.mrn = f.individual_id
          join pt_demog d on a.mrn = d.mrn
     where a.relation = 'Child' 
           and not exists (select 1 from all_relationship_s7 b where a.mrn = b.relation_mrn and b.relation = 'Child')
           and d.sex = 'F' /* mother's only */           
           and f.family_id = 0
union
     select f.family_id as fam
            , a.relation_mrn as ego
            , r.ego 
            , null::text
            , d.sex
            , r.gen+1
     from mafind r 
          join all_relationship_s7 a on r.ego = a.mrn
          join pt_demog d on a.relation_mrn = d.mrn /*child*/
          join pt_demog e on r.ego = e.mrn /*mothers only*/
          join family_ids f on  d.mrn = f.individual_id
     where f.family_id = 0 
           and a.relation = 'Child'
           and e.sex = 'F' /* pick up mothers only */
           and r.gen <= 7  /* force it to stop */
)
select * from mafind
\p\g


drop table if exists father_desc
\p\g

create table father_desc as 
with recursive pafind(fam, ego, ma, pa, sex, gen) as (
     select distinct f.family_id as fam
            , a.mrn as ego
            , null::text as ma
            , null::text as pa
            , d.sex
            , 1 as gen
     from all_relationship_s7 a
          join family_ids f on a.mrn = f.individual_id
          join pt_demog d on a.mrn = d.mrn
     where a.relation = 'Child' 
           and not exists (select 1 from all_relationship_s7 b where a.mrn = b.relation_mrn and b.relation = 'Child')
           and d.sex = 'M' /* father's only */           
           and f.family_id = 0
union
     select r.fam
            , a.relation_mrn
            , null::text
            , r.ego 
            , d.sex
            , r.gen+1
     from pafind r 
          join all_relationship_s7 a on r.ego = a.mrn
          join pt_demog d on a.relation_mrn = d.mrn /*child*/
          join pt_demog e on r.ego = e.mrn /*fathers only*/
          join family_ids f on  d.mrn = f.individual_id
     where f.family_id = 0 
           and a.relation = 'Child'
           and e.sex = 'M' /* pick up fathers only */
           and r.gen <= 7
)
select * from pafind
\p\g


/* ad hoc 
select m.ego, r.firstname cfirst, r.lastname clast, r.phonenumber cph, c.year as chyr
       , m.ma, p.firstname mfirst, p.lastname mlast, p.phonenumber mph, d.year as mayr
       , m.pa, e.year, q.firstname dfirst, q.lastname dlast, q.phonenumber as dph
from mother_desc m join pt_demog c on m.ego = c.mrn join x_pt_processed r on c.mrn = r.mrn
join pt_demog d on m.ma = d.mrn join x_pt_processed p on d.mrn = p.mrn
join pt_demog e on m.pa = e.mrn join x_pt_processed q on e.mrn = q.mrn
order by ego, ma, pa
;

*/
