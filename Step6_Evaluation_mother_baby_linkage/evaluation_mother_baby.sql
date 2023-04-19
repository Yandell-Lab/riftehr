/* #-- #-- # Evaluation of maternal relationships using the mother-baby linkage from EHR*/
/* #-- # Overall performance query for relationship = mother*/

/***
        UTAH: no supplied definition of mother_child_linkage.  I edited the header line of
        the input data to match column names in the RIFTEHR Step6 SQL
**/
drop table if exists mother_child_linkage;
create table cell.mother_child_linkage (
       child_mrn text,
       mother_mrn text
);
\copy mother_child_linkage from /uufs/chpc.utah.edu/common/HIPAA/u0138544/gits/github/ds-ehr/data/verify/updb_clarity_RIFTEHR_baby_mom_links_all_with_distid_12152022.txt csv delimiter '|' header


/***
        UTAH: three bad mother/child records
   select m.mother_mrn, p.firstname mfirst, p.lastname mlast, d.year myr,
          m.child_mrn, q.firstname cfirst, q.lastname clast, e.year cyr
   from mother_child_linkage m join pt_demog d on m.mother_mrn = d.mrn 
        join x_pt_processed p on d.mrn = p.mrn 
        join pt_demog e on e.mrn = m.child_mrn 
        join x_pt_processed q on e.mrn = q.mrn 
   where (d.year+12) > e.year;

    mother_mrn | mfirst  | mlast | myr  | child_mrn | cfirst  | clast | cyr  
   ------------+---------+-------+------+-----------+---------+-------+------
    974700     | KYRA    | LARM  | 2003 | 590788    | JENNA   | LARM  | 2001
    2441891    | AMELIA  | ROMO  | 1991 | 2441891   | AMELIA  | ROMO  | 1991
    2425683    | KIRSTEN | FRESH | 2011 | 2425683   | KIRSTEN | FRESH | 2011
   (3 rows)
***/

delete from mother_child_linkage where child_mrn in ('590788','2441891','2425683');
\p\g

/* 

We delete four nativity records which are contradicted by contact information to avoid
having to use 'Mother' relationship.  These are the only four nativity records which
didn't have 'Mother' as specific relationship value.  All where 'Aunt's.
*/
delete from mother_child_linkage where mother_mrn in ('3189002','1494956','2512154','2951334')
\p\g



select count(*) as total_mother_child_n from mother_child_linkage
\p\g

select tp.tp as "True Pos(tp)" 
       , fp.fp as "False Pos(fp)"
       , fn.fn as "False Neg(fn)"
       , 1.0*tp/(tp+fn) as "sensitivity: tp/(tp+fn)"
       , 1.0*tp/(tp+fp) as "ppv: tp/(tp+fp)"
from
(
	/* # True Positives (TP)*/      
	select count(distinct (mrn, relation_mrn)) as tp
	from actual_and_inf_rel_clean_final
	join mother_child_linkage on (relation_mrn = child_mrn and mrn = mother_mrn)
	where relationship_specific = 'Mother'
) tp 
cross join (
	/* # False Positives (FP)*/
	select sum(mismatch) as fp
	from 
	(
		select child_mrn, 
                       case when sum(case when m.mother_mrn = a.mrn then 1 else 0 end) = 0 then 1 else 0 end as mismatch
		from actual_and_inf_rel_clean_final as a
 		join mother_child_linkage as m on (a.relation_mrn = m.child_mrn)
		where relationship_specific = 'Mother'
		group by child_mrn
	) a
) fp 
cross join
(
	/* # False Negatives (FN)*/
select count(*) as fn
	from mother_child_linkage c
        where not exists (select 1 from actual_and_inf_rel_clean_final p where c.child_mrn = p.relation_mrn)
) fn
order by "ppv: tp/(tp+fp)" desc
\p\g



/* #-- #-- # Create table to include matched path*/

-- drop table if exists actual_and_inf_rel_clean_final_w_matched_path\p\g
-- create table actual_and_inf_rel_clean_final_w_matched_path
-- as 
-- select distinct a.mrn, a.relationship, a.relation_mrn, a.relationship_specific, b.matched_path
-- from actual_and_inf_rel_clean_final a
-- join relations_matched_clean b on (a.mrn = b.mrn and a.relationship = b.relationship and a.relation_mrn = b.relation_mrn)\p\g

/* #-- # Based on number of distinct paths*/
-- # False Negatives (FN) - zero since there is no match, zero paths therefore we are calculationg only PPV

select *, tp/(tp+fp) as ppv
from
(
	/* # True Positives (TP)*/
	select npath, count(*) as tp
	from
	(
		select mrn, relation_mrn, array_length(matched_path,1) as npath
		from pt_matches
		join mother_child_linkage on (relation_mrn = child_mrn and mrn = mother_mrn)
		-- where relationship_specific = 'Mother'
	) a
	group by npath
) tp 
cross join
(
	/* # False Positives (FP)*/
	select npath, sum(mismatch) as fp
	from
	(
		select mrn, npath, sum(case when mother_mrn = mrn then 0 else 1 end) as mismatch
		from (
			select mrn, relation_mrn, array_length(matched_path,1) as npath
			from pt_matches
			-- where relationship_specific = 'Mother'
		) a 
		join mother_child_linkage on (relation_mrn = child_mrn)
		group by mrn, npath
	) b
	group by npath
) fp --on tp.npath = fp.npath
order by ppv desc\p\g


/* #-- # Calculate TP, FP, FN, sensitivity and PPV by path for mother */
-- select *, tp/(tp+fn) as sensitivity, tp/(tp+fp) as ppv 
drop table if exists run.path_sensitivity
\p\g
create table run.path_sensitivity
as
select distinct tp.singlepath, tp.tp, fp.fp, fn.fn,
                to_char(1.0*tp/(tp+fn), '9.9999') as sensitivity,
                to_char(tp/(tp+fp) , '9.9999') as ppv
from
(
	-- # True Positives (TP)
	select unnest(a.matched_path) as singlepath, 
               count(distinct (a.mrn, a.relation_mrn)) as tp
	from pt_matches a
	join mother_child_linkage m on (a.mrn = m.child_mrn and a.relation_mrn = m.mother_mrn)
	-- where a.relationship_specific = 'Mother'
	group by singlepath
) tp 
join
(
	-- # False Positives (FP)
	select singlepath, sum(mismatch) as fp
	from 
	(
		select a.mrn, 
                       unnest(a.matched_path) as singlepath, 
                       sum(case when mother_mrn = relation_mrn then 0 else 1 end) as mismatch
		from pt_matches a
		join mother_child_linkage m  on (a.mrn = m.child_mrn)
		-- where a.relationship_specific = 'Mother'
		group by mrn, singlepath
	) s
	group by singlepath
) fp on tp.singlepath = fp.singlepath
join
(
	-- # False Negatives (FN)
	select 'first' as singlepath, count(*) as fn
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{first}')
	union
	select 'first,last', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{"first,last"}')
	union
	select 'first,last,phone', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{"first,last,phone"}')
	union
	select 'first,last,phone,zip', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{"first,last,phone,zip"}')
	union
	select 'first,last,zip', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{"first,last,zip"}')
	union
	select 'first,phone', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{"first,phone"}')
	union
	select 'first,phone,zip', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{"first,phone,zip"}')
	union
	select 'first,zip', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{"first,zip"}')
	union
	select 'last', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{last}')
	union
	select 'last,phone', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{"last,phone"}')
	union
	select 'last,phone,zip', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{"last,phone,zip"}')
	union
	select 'last,zip', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{"last,zip"}')
	union
	select 'phone', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{phone}')
	union
	select 'phone,zip', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{"phone,zip"}')
	union
	select 'zip', count(*)
	from mother_child_linkage
	where child_mrn not in (select mrn from pt_matches where matched_path @> '{zip}')
) fn on fp.singlepath = fn.singlepath
\p\g
select * from run.path_sensitivity order by ppv desc
\p\g

drop table if exists run.path_sensitivity_utah
\p\g
create table run.path_sensitivity_utah as
select distinct tp.matched_path, tp.tp, fp.fp, fn.fn,
       to_char(1.0*tp/(tp.tp+fn.fn), '0.9999') as sensitivity, 
       to_char(1.0*tp/(tp.tp+fp.fp), '0.9999') as ppv
from
(
	/* # True Positives (TP)*/
	select a.matched_path, count(*) as tp
	from pt_matches a
	join mother_child_linkage m on (a.mrn = m.child_mrn and a.relation_mrn = m.mother_mrn)
        group by a.matched_path
	-- where a.relationship_specific = 'Mother'
) tp 
join 
(       /* # False Positives (FP)*/
	select a.matched_path, count(*) as fp
        from pt_matches a join pt_demog d on a.mrn = d.mrn join pt_demog o on a.relation_mrn = o.mrn
        where a.relationship = 'Mother' and d.year < o.year
        and not exists(select * from mother_child_linkage m where a.mrn = m.child_mrn and a.relation_mrn = m.mother_mrn)
        group by a.matched_path
) fp on tp.matched_path = fp.matched_path       
join
(       /* # False Negatives (FN)*/
	select a.matched_path, count(*) as fn
	from pt_matches a join pt_demog d on a.mrn = d.mrn join pt_demog o on a.relation_mrn = o.mrn
        where a.relationship = 'Mother' and d.year < o.year
        and not exists (select 1 from mother_child_linkage m where m.mother_mrn = a.relation_mrn)
        group by a.matched_path
) fn on fp.matched_path = fn.matched_path
\p\g
select array_length(matched_path,1) as npath, * from run.path_sensitivity_utah order by npath desc, ppv desc
\p\g
