-- # this script will find matches between EC and PT data. Two datasets
--   should be preprocessed by the split_names_combine.py script, and
--   input as x_ec_processed and x_pt_processed

/* Brutal, I know*/
delete from x_ec_processed x
where ec_relationship in ('Neighbor','Unknown','None Entered','In-Law','Friend','Case Worker','Other','Attorney','Employee','Legal Guardian')
      or ec_relationship is null
\p\g

create unique index on x_pt_processed(mrn)
\p\g

-- map FirstName
create table x_fn_distinct as
select distinct MRN, FirstName
from x_pt_processed\p\g

create table x_fn_cnt as
select a.FirstName, count(distinct MRN) as cnt
from x_fn_distinct a
group by a.FirstName
\p\g
create unique index xfncnt on x_fn_cnt(firstname)\p\g

create table x_fn_unique  as
select distinct a.MRN, a.FirstName
from x_pt_processed a
join x_fn_cnt b on a.FirstName = b.FirstName 
where b.cnt = 1 \p\g
create unique index xfnunique on x_fn_unique(firstname)\p\g

drop table if exists x_cumc_patient_matched\p\g
create table x_cumc_patient_matched as 
select distinct a.mrn_1::text as empi_or_mrn
       , a.ec_relationship as relationship
       , b.mrn::text as relation_empi_or_mrn
       , 'first'::text as matched_path
from x_ec_processed a
join x_fn_unique b on a.ec_firstname = b.firstname\p\g


-- map LastName
create table x_ln_distinct as
select distinct MRN, LastName
from x_pt_processed\p\g

create table x_ln_cnt  as
select a.LastName, count(distinct MRN) as cnt
from x_ln_distinct a
group by a.LastName\p\g
create unique index 
xlncnt on x_ln_cnt(lastname)\p\g

create table x_ln_unique as
select distinct a.MRN, a.LastName
from x_pt_processed a
join x_ln_cnt b on a.LastName = b.LastName
where b.cnt = 1 \p\g
create unique index on x_ln_unique(LastName)\p\g

drop table if exists lastname_peek\p\g
create table lastname_peek as 
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'last' as matched_path
from x_ec_processed a
join x_ln_unique b on a.EC_LastName = b.LastName\p\g
drop table if exists x_ln_distinct, x_ln_cnt, x_ln_unique\p\g

-- map Phone
create table x_ph_distinct as
select distinct MRN, PhoneNumber
from x_pt_processed\p\g

create table x_ph_cnt as 
select a.PhoneNumber, count(distinct MRN) as cnt
from x_ph_distinct a
group by a.PhoneNumber\p\g
create unique index on x_ph_cnt(PhoneNumber)\p\g

create table x_ph_unique  as
select distinct a.MRN, a.PhoneNumber
from x_pt_processed a
join x_ph_cnt b on a.PhoneNumber = b.PhoneNumber
where b.cnt = 1 \p\g
create unique index on x_ph_unique(PhoneNumber)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'phone'::text as matched_path
from x_ec_processed a
join x_ph_unique b on a.EC_PhoneNumber = b.PhoneNumber\p\g

drop table x_ph_distinct, x_ph_cnt, x_ph_unique\p\g

-- map Zip
create table x_zip_distinct as
select distinct MRN, Zipcode
from x_pt_processed\p\g

create table x_zip_cnt as
select a.Zipcode, count(distinct MRN) as cnt
from x_zip_distinct a
group by a.Zipcode\p\g
create unique index on x_zip_cnt(Zipcode)\p\g

create table x_zip_unique as
select distinct a.MRN, a.Zipcode
from x_pt_processed a
join x_zip_cnt b on a.Zipcode = b.Zipcode
where b.cnt = 1 \p\g
create unique index on x_zip_unique(Zipcode)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'zip'::text as matched_path
from x_ec_processed a
join x_zip_unique b on a.EC_Zipcode = b.Zipcode\p\g

drop table x_zip_distinct, x_zip_cnt, x_zip_unique\p\g

-- map FirstName, LastName
create table x_fn_ln_distinct as
select distinct MRN, FirstName, LastName
from x_pt_processed\p\g

create table x_fn_ln_cnt as
select a.FirstName, a.LastName, count(distinct MRN) as cnt
from x_fn_ln_distinct a
group by a.FirstName, a.LastName\p\g
create unique index on x_fn_ln_cnt(FirstName, LastName)\p\g

create table x_fn_ln_unique as
select distinct a.MRN, a.FirstName, a.LastName
from x_pt_processed a
join x_fn_ln_cnt b on a.FirstName = b.FirstName and a.LastName = b.LastName
where b.cnt = 1 \p\g
create unique index on x_fn_ln_unique(FirstName, LastName)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,last'::text as matched_path
from x_ec_processed a
join x_fn_ln_unique b on a.EC_FirstName = b.FirstName and a.EC_LastName = b.LastName\p\g

drop table x_fn_ln_distinct, x_fn_ln_cnt, x_fn_ln_unique\p\g

-- map FirstName, Phone
create table x_fn_ph_distinct as
select distinct MRN, FirstName, PhoneNumber
from x_pt_processed\p\g

create table x_fn_ph_cnt as
select a.FirstName, a.PhoneNumber, count(distinct MRN) as cnt
from x_fn_ph_distinct a
group by a.FirstName, a.PhoneNumber\p\g
create unique index on x_fn_ph_cnt(FirstName, PhoneNumber)\p\g

create table x_fn_ph_unique as
select distinct a.MRN, a.FirstName, a.PhoneNumber
from x_pt_processed a
join x_fn_ph_cnt b on a.FirstName = b.FirstName and a.PhoneNumber = b.PhoneNumber
where b.cnt = 1 \p\g
create unique index on x_fn_ph_unique(FirstName, PhoneNumber)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,phone'::text as matched_path
from x_ec_processed a
join x_fn_ph_unique b on a.EC_FirstName = b.FirstName and a.EC_PhoneNumber = b.PhoneNumber\p\g

drop table x_fn_ph_distinct, x_fn_ph_cnt, x_fn_ph_unique\p\g

-- map FirstName, Zip
create table x_fn_zip_distinct as
select distinct MRN, FirstName,Zipcode
from x_pt_processed\p\g

create table x_fn_zip_cnt as
select a.FirstName, a.Zipcode, count(distinct MRN) as cnt
from x_fn_zip_distinct a
group by a.FirstName, a.Zipcode\p\g
create unique index on x_fn_zip_cnt(FirstName, Zipcode)\p\g

create table x_fn_zip_unique  as
select distinct a.MRN, a.FirstName, a.Zipcode
from x_pt_processed a
join x_fn_zip_cnt b on a.FirstName = b.FirstName and a.Zipcode = b.Zipcode
where b.cnt = 1 \p\g
create unique index on x_fn_zip_unique(FirstName, Zipcode)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,zip'::text as matched_path
from x_ec_processed a
join x_fn_zip_unique b on a.EC_FirstName = b.FirstName and a.EC_Zipcode = b.Zipcode\p\g

drop table if exists x_fn_zip_distinct, x_fn_zip_cnt, x_fn_zip_unique\p\g

-- map LastName, Phone
create table x_ln_ph_distinct as
select distinct MRN, LastName, PhoneNumber
from x_pt_processed\p\g

create table x_ln_ph_cnt as
select a.LastName, a.PhoneNumber, count(distinct MRN) as cnt
from x_ln_ph_distinct a
group by a.LastName, a.PhoneNumber\p\g
create unique index on x_ln_ph_cnt(LastName, PhoneNumber)\p\g

create table x_ln_ph_unique as
select distinct a.MRN, a.LastName, a.PhoneNumber
from x_pt_processed a
join x_ln_ph_cnt b on a.LastName = b.LastName and a.PhoneNumber = b.PhoneNumber
where b.cnt = 1 \p\g
create unique index on x_ln_ph_unique(LastName, PhoneNumber)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'last,phone'::text as matched_path
from x_ec_processed a
join x_ln_ph_unique b on a.EC_LastName = b.LastName and a.EC_PhoneNumber = b.PhoneNumber\p\g

drop table x_ln_ph_distinct, x_ln_ph_cnt, x_ln_ph_unique\p\g

-- map LastName, Zipcode
create table x_ln_zip_distinct as
select distinct MRN, LastName, Zipcode
from x_pt_processed\p\g

create table x_ln_zip_cnt as
select a.LastName, a.Zipcode, count(distinct MRN) as cnt
from x_ln_zip_distinct a
group by a.LastName, a.Zipcode\p\g
create unique index on x_ln_zip_cnt(LastName, Zipcode)\p\g

create table x_ln_zip_unique as
select distinct a.MRN, a.LastName, a.Zipcode
from x_pt_processed a
join x_ln_zip_cnt b on a.LastName = b.LastName and a.Zipcode = b.Zipcode
where b.cnt = 1 \p\g
create unique index on x_ln_zip_unique(LastName, Zipcode)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'last,zip'::text as matched_path
from x_ec_processed a
join x_ln_zip_unique b on a.EC_LastName = b.LastName and a.EC_Zipcode = b.Zipcode\p\g

drop table x_ln_zip_distinct, x_ln_zip_cnt, x_ln_zip_unique\p\g

-- map Phone, Zipcode
create table x_ph_zip_distinct as
select distinct MRN, PhoneNumber, Zipcode
from x_pt_processed\p\g

create table x_ph_zip_cnt as
select a.PhoneNumber, a.Zipcode, count(distinct MRN) as cnt
from x_ph_zip_distinct a
group by a.PhoneNumber, a.Zipcode\p\g
create unique index on x_ph_zip_cnt(PhoneNumber, Zipcode)\p\g

create table x_ph_zip_unique as
select distinct a.MRN, a.PhoneNumber, a.Zipcode
from x_pt_processed a
join x_ph_zip_cnt b on a.PhoneNumber = b.PhoneNumber and a.Zipcode = b.Zipcode
where b.cnt = 1 \p\g
create unique index on x_ph_zip_unique(PhoneNumber, Zipcode)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'phone,zip'::text as matched_path
from x_ec_processed a
join x_ph_zip_unique b on a.EC_PhoneNumber = b.PhoneNumber and a.EC_Zipcode = b.Zipcode\p\g

drop table if exists x_ph_zip_distinct, x_ph_zip_cnt, x_ph_zip_unique\p\g

-- map FirstName,LastName,Phone
create table x_fn_ln_ph_distinct as
select distinct MRN, FirstName, LastName, PhoneNumber
from x_pt_processed\p\g

create table x_fn_ln_ph_cnt  as
select a.FirstName, a.LastName, a.PhoneNumber, count(distinct MRN) as cnt
from x_fn_ln_ph_distinct a
group by a.FirstName, a.LastName, a.PhoneNumber\p\g
create unique index on x_fn_ln_ph_cnt(FirstName, LastName, PhoneNumber)\p\g

create table x_fn_ln_ph_unique as
select distinct a.MRN, a.FirstName, a.LastName, a.PhoneNumber
from x_pt_processed a
join x_fn_ln_ph_cnt b on a.FirstName = b.FirstName 
                      and a.LastName = b.LastName  
                      and a.PhoneNumber = b.PhoneNumber
where b.cnt = 1 \p\g
create unique index on x_fn_ln_ph_unique(FirstName, LastName, PhoneNumber)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn
                , a.EC_Relationship as relationship
                , b.MRN as relation_empi_or_mrn
                , 'first,last,phone'::text as matched_path
from x_ec_processed a
join x_fn_ln_ph_unique b on a.EC_FirstName = b.FirstName 
                         and a.EC_LastName = b.LastName 
                         and a.EC_PhoneNumber = b.PhoneNumber\p\g

drop table x_fn_ln_ph_distinct, x_fn_ln_ph_cnt, x_fn_ln_ph_unique\p\g

-- map FirstName,LastName,Zipcode
create table x_fn_ln_zip_distinct as
select distinct MRN, FirstName, LastName, Zipcode
from x_pt_processed\p\g

create table x_fn_ln_zip_cnt as
select a.FirstName, a.LastName, a.Zipcode, count(distinct MRN) as cnt
from x_fn_ln_zip_distinct a
group by a.FirstName, a.LastName, a.Zipcode\p\g
create unique index on x_fn_ln_zip_cnt(FirstName, LastName, Zipcode)\p\g

create table x_fn_ln_zip_unique as
select distinct a.MRN, a.FirstName, a.LastName, a.Zipcode
from x_pt_processed a
join x_fn_ln_zip_cnt b on a.FirstName = b.FirstName and a.LastName = b.LastName and a.Zipcode = b.Zipcode
where b.cnt = 1 \p\g
create unique index on x_fn_ln_zip_unique(FirstName, LastName, Zipcode)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,last,zip'::text as matched_path
from x_ec_processed a
join x_fn_ln_zip_unique b on a.EC_FirstName = b.FirstName and a.EC_LastName = b.LastName and a.EC_Zipcode = b.Zipcode\p\g

drop table x_fn_ln_zip_distinct, x_fn_ln_zip_cnt, x_fn_ln_zip_unique\p\g

-- map FirstName,Phone,Zipcode
create table x_fn_ph_zip_distinct as
select distinct MRN, FirstName, PhoneNumber, Zipcode
from x_pt_processed\p\g

create table x_fn_ph_zip_cnt as
select a.FirstName, a.PhoneNumber, a.Zipcode, count(distinct MRN) as cnt
from x_fn_ph_zip_distinct a
group by a.FirstName, a.PhoneNumber, a.Zipcode\p\g
create unique index on x_fn_ph_zip_cnt(FirstName, PhoneNumber, Zipcode)\p\g

create table x_fn_ph_zip_unique as
select distinct a.MRN, a.FirstName, a.PhoneNumber, a.Zipcode
from x_pt_processed a
join x_fn_ph_zip_cnt b on a.FirstName = b.FirstName and a.PhoneNumber = b.PhoneNumber and a.Zipcode = b.Zipcode
where b.cnt = 1 \p\g
create unique index on x_fn_ph_zip_unique(FirstName, PhoneNumber, Zipcode)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,phone,zip'::text as matched_path
from x_ec_processed a
join x_fn_ph_zip_unique b on a.EC_FirstName = b.FirstName and a.EC_PhoneNumber = b.PhoneNumber and a.EC_Zipcode = b.Zipcode\p\g

drop table x_fn_ph_zip_distinct, x_fn_ph_zip_cnt, x_fn_ph_zip_unique\p\g

-- map LastName,Phone,Zipcode
create table x_ln_ph_zip_distinct as
select distinct MRN, LastName, PhoneNumber, Zipcode
from x_pt_processed\p\g

create table x_ln_ph_zip_cnt as
select a.LastName, a.PhoneNumber, a.Zipcode, count(distinct MRN) as cnt
from x_ln_ph_zip_distinct a
group by a.LastName, a.PhoneNumber, a.Zipcode\p\g
create unique index on x_ln_ph_zip_cnt(LastName, PhoneNumber, Zipcode)\p\g

create table x_ln_ph_zip_unique as
select distinct a.MRN, a.LastName, a.PhoneNumber, a.Zipcode
from x_pt_processed a
join x_ln_ph_zip_cnt b on a.LastName = b.LastName and a.PhoneNumber = b.PhoneNumber and a.Zipcode = b.Zipcode
where b.cnt = 1 \p\g
create unique index on x_ln_ph_zip_unique(LastName, PhoneNumber, Zipcode)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'last,phone,zip'::text matched_path
from x_ec_processed a
join x_ln_ph_zip_unique b on a.EC_LastName = b.LastName and a.EC_PhoneNumber = b.PhoneNumber and a.EC_Zipcode = b.Zipcode\p\g

drop table x_ln_ph_zip_distinct, x_ln_ph_zip_cnt, x_ln_ph_zip_unique\p\g

-- map FirstName,LastName,Phone,Zipcode
create table x_fn_ln_ph_zip_distinct as
select distinct MRN, FirstName, LastName, PhoneNumber, Zipcode
from x_pt_processed\p\g

create table x_fn_ln_ph_zip_cnt as
select a.FirstName, a.LastName, a.PhoneNumber, a.Zipcode, count(distinct MRN) as cnt
from x_fn_ln_ph_zip_distinct a
group by a.FirstName, a.LastName, a.PhoneNumber, a.Zipcode\p\g
create unique index on x_fn_ln_ph_zip_cnt(FirstName, LastName, PhoneNumber, Zipcode)\p\g

create table x_fn_ln_ph_zip_unique as
select distinct a.MRN, a.FirstName, a.LastName, a.PhoneNumber, a.Zipcode
from x_pt_processed a
join x_fn_ln_ph_zip_cnt b on a.FirstName = b.FirstName and a.LastName = b.LastName and a.PhoneNumber = b.PhoneNumber and a.Zipcode = b.Zipcode
where b.cnt = 1 \p\g
create unique index on x_fn_ln_ph_zip_unique(FirstName, LastName, PhoneNumber, Zipcode)\p\g

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,last,phone,zip'::text as matched_path
from x_ec_processed a
join x_fn_ln_ph_zip_unique b on a.EC_FirstName = b.FirstName and a.EC_LastName = b.LastName and a.EC_PhoneNumber = b.PhoneNumber and a.EC_Zipcode = b.Zipcode\p\g

drop table if exists x_fn_ln_ph_zip_distinct, x_fn_ln_ph_zip_cnt, x_fn_ln_ph_zip_unique\p\g

