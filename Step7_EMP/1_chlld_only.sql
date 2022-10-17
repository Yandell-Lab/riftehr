/*
 * What can we from only using "Child" relations?
 */
select (r.year - m.year)/5 + 1 as years_mod5, count(*)
from  all_relationship_s5 a
      join pt_demog m on a.mrn = m.mrn
      join pt_demog r on a.relation_mrn = r.mrn
where  a.relation = 'Child'
       and m.mrn != r.mrn
       and r.year - m.year not between 12 and 50
group by (r.year - m.year)/5 + 1
order by years_mod5
\p\g

with recursive pedfind(fam, ego, mrn, ma, pa, sex, gen)as (
     select f.id as fam
            , uuid_generate_v4() as ego
            , a.relation_mrn as mrn
            , case when e.sex = 'F' then e.mrn end as ma
            , case when e.sex = 'M' then e.mrn end as pa
            , d.sex
            , 1 as gen
     from all_relationship_s5 a
          join family f on a.mrn = f.ego
          join pt_demog e on a.mrn = e.mrn /*parent*/
          join pt_demog d on a.relation_mrn = d.mrn /*child*/
     where a.relation = 'Child' 
           and not exists (select 1 from all_relationship_s5 b where a.relation_mrn = b.mrn and b.relation = 'Child')
           and f.id =0
union
     select r.fam
            , uuid_generate_v4() as ego
            , a.mrn
            , case when r.sex = 'F' then r.mrn end as ma
            , case when r.sex = 'M' then r.mrn end as pa
            , d.sex
            , r.gen+1
     from pedfind r 
          join all_relationship_s5 a on r.pa = a.mrn or r.ma = a.mrn
          join pt_demog d on a.mrn = d.mrn
          join family f on  a.mrn = f.ego
      where f.id = 0
)
select f.* from pedfind f
\p\g


with lastgen(fam, ego, mrn, ma, pa, sex, gen)as (
     select f.id as fam
            , uuid_generate_v4() as ego
            , a.relation_mrn as mrn
            , case when e.sex = 'F' then e.mrn end as ma
            , case when e.sex = 'M' then e.mrn end as pa
            , d.sex
            , 1 as gen
     from all_relationship_s5 a
          join family f on a.mrn = f.ego
          join pt_demog e on a.mrn = e.mrn /*parent*/
          join pt_demog d on a.relation_mrn = d.mrn /*child*/
     where a.relation = 'Child' 
           and not exists (select 1 from all_relationship_s5 b where a.relation_mrn = b.mrn and b.relation = 'Child')
           and f.id =0
),
parent_sex as(
select f.mrn, array_agg(d.sex) as parsex, count(*)
from lastgen f join pt_demog d on d.mrn in (f.ma, f.pa)group by f.mrn
)
select parsex, count(*) as occurs from parent_sex group by parsex order by occurs desc;
