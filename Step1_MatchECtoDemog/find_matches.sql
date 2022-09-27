-- # this script will find matches between EC and PT data. Two datasets
--   should be preprocessed by the split_names_combine.py script, and
--   input as x_ec_processed and x_pt_processed

-- map FirstName
create table x_fn_distint as
select distinct MRN, FirstName
from x_pt_processed;

create table x_fn_cnt as
select a.FirstName, count(distinct MRN) as cnt
from x_fn_distint a
group by a.FirstName;
create unique index xfncnt on x_fn_cnt(firstname);

create table x_fn_unique  as
select distinct a.MRN, a.FirstName
from x_pt_processed a
join x_fn_cnt b on a.FirstName = b.FirstName 
where b.cnt = 1 ;
create unique index xfnunique on x_fn_unique(firstname);

drop table if exists x_cumc_patient_matched;
create table x_cumc_patient_matched as 
select distinct a.MRN_1::text as empi_or_mrn
       , a.EC_Relationship as relationship
       , b.MRN::text as relation_empi_or_mrn
       , 'first'::text as matched_path
from x_ec_processed a
join x_fn_unique b on a.EC_FirstName = b.FirstName;
drop table if exists x_fn_distint, x_fn_cnt, x_fn_unique;

-- map LastName
create table x_ln_distint as
select distinct MRN, LastName
from x_pt_processed;

create table x_ln_cnt  as
select a.LastName, count(distinct MRN) as cnt
from x_ln_distint a
group by a.LastName;
create unique index 
xlncnt on x_ln_cnt(lastname);

create table x_ln_unique as
select distinct a.MRN, a.LastName
from x_pt_processed a
join x_ln_cnt b on a.LastName = b.LastName
where b.cnt = 1 ;
create unique index on x_ln_unique(LastName);

drop table if exists lastname_peek;
create table lastname_peek as 
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'last' as matched_path
from x_ec_processed a
join x_ln_unique b on a.EC_LastName = b.LastName;
drop table if exists x_ln_distint, x_ln_cnt, x_ln_unique;

-- map Phone
create table x_ph_distint as
select distinct MRN, PhoneNumber
from x_pt_processed;

create table x_ph_cnt as 
select a.PhoneNumber, count(distinct MRN) as cnt
from x_ph_distint a
group by a.PhoneNumber;
create unique index on x_ph_cnt(PhoneNumber);

create table x_ph_unique  as
select distinct a.MRN, a.PhoneNumber
from x_pt_processed a
join x_ph_cnt b on a.PhoneNumber = b.PhoneNumber
where b.cnt = 1 ;
create unique index on x_ph_unique(PhoneNumber);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'phone'::text as matched_path
from x_ec_processed a
join x_ph_unique b on a.EC_PhoneNumber = b.PhoneNumber;

drop table x_ph_distint, x_ph_cnt, x_ph_unique;

-- map Zip
create table x_zip_distint as
select distinct MRN, Zipcode
from x_pt_processed;

create table x_zip_cnt as
select a.Zipcode, count(distinct MRN) as cnt
from x_zip_distint a
group by a.Zipcode;
create unique index on x_zip_cnt(Zipcode);

create table x_zip_unique as
select distinct a.MRN, a.Zipcode
from x_pt_processed a
join x_zip_cnt b on a.Zipcode = b.Zipcode
where b.cnt = 1 ;
create unique index on x_zip_unique(Zipcode);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'zip'::text as matched_path
from x_ec_processed a
join x_zip_unique b on a.EC_Zipcode = b.Zipcode;

drop table x_zip_distint, x_zip_cnt, x_zip_unique;

-- map FirstName, LastName
create table x_fn_ln_distint as
select distinct MRN, FirstName, LastName
from x_pt_processed;

create table x_fn_ln_cnt as
select a.FirstName, a.LastName, count(distinct MRN) as cnt
from x_fn_ln_distint a
group by a.FirstName, a.LastName;
create unique index on x_fn_ln_cnt(FirstName, LastName);

create table x_fn_ln_unique as
select distinct a.MRN, a.FirstName, a.LastName
from x_pt_processed a
join x_fn_ln_cnt b on a.FirstName = b.FirstName and a.LastName = b.LastName
where b.cnt = 1 ;
create unique index on x_fn_ln_unique(FirstName, LastName);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,last'::text as matched_path
from x_ec_processed a
join x_fn_ln_unique b on a.EC_FirstName = b.FirstName and a.EC_LastName = b.LastName;

drop table x_fn_ln_distint, x_fn_ln_cnt, x_fn_ln_unique;

-- map FirstName, Phone
create table x_fn_ph_distint as
select distinct MRN, FirstName, PhoneNumber
from x_pt_processed;

create table x_fn_ph_cnt as
select a.FirstName, a.PhoneNumber, count(distinct MRN) as cnt
from x_fn_ph_distint a
group by a.FirstName, a.PhoneNumber;
create unique index on x_fn_ph_cnt(FirstName, PhoneNumber);

create table x_fn_ph_unique as
select distinct a.MRN, a.FirstName, a.PhoneNumber
from x_pt_processed a
join x_fn_ph_cnt b on a.FirstName = b.FirstName and a.PhoneNumber = b.PhoneNumber
where b.cnt = 1 ;
create unique index on x_fn_ph_unique(FirstName, PhoneNumber);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,phone'::text as matched_path
from x_ec_processed a
join x_fn_ph_unique b on a.EC_FirstName = b.FirstName and a.EC_PhoneNumber = b.PhoneNumber;

drop table x_fn_ph_distint, x_fn_ph_cnt, x_fn_ph_unique;

-- map FirstName, Zip
create table x_fn_zip_distint as
select distinct MRN, FirstName,Zipcode
from x_pt_processed;

create table x_fn_zip_cnt as
select a.FirstName, a.Zipcode, count(distinct MRN) as cnt
from x_fn_zip_distint a
group by a.FirstName, a.Zipcode;
create unique index on x_fn_zip_cnt(FirstName, Zipcode);

create table x_fn_zip_unique  as
select distinct a.MRN, a.FirstName, a.Zipcode
from x_pt_processed a
join x_fn_zip_cnt b on a.FirstName = b.FirstName and a.Zipcode = b.Zipcode
where b.cnt = 1 ;
create unique index on x_fn_zip_unique(FirstName, Zipcode);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,zip'::text as matched_path
from x_ec_processed a
join x_fn_zip_unique b on a.EC_FirstName = b.FirstName and a.EC_Zipcode = b.Zipcode;

drop table if exists x_fn_zip_distint, x_fn_zip_cnt, x_fn_zip_unique;

-- map LastName, Phone
create table x_ln_ph_distint as
select distinct MRN, LastName, PhoneNumber
from x_pt_processed;

create table x_ln_ph_cnt as
select a.LastName, a.PhoneNumber, count(distinct MRN) as cnt
from x_ln_ph_distint a
group by a.LastName, a.PhoneNumber;
create unique index on x_ln_ph_cnt(LastName, PhoneNumber);

create table x_ln_ph_unique as
select distinct a.MRN, a.LastName, a.PhoneNumber
from x_pt_processed a
join x_ln_ph_cnt b on a.LastName = b.LastName and a.PhoneNumber = b.PhoneNumber
where b.cnt = 1 ;
create unique index on x_ln_ph_unique(LastName, PhoneNumber);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'last,phone'::text as matched_path
from x_ec_processed a
join x_ln_ph_unique b on a.EC_LastName = b.LastName and a.EC_PhoneNumber = b.PhoneNumber;

drop table x_ln_ph_distint, x_ln_ph_cnt, x_ln_ph_unique;

-- map LastName, Zipcode
create table x_ln_zip_distint as
select distinct MRN, LastName, Zipcode
from x_pt_processed;

create table x_ln_zip_cnt as
select a.LastName, a.Zipcode, count(distinct MRN) as cnt
from x_ln_zip_distint a
group by a.LastName, a.Zipcode;
create unique index on x_ln_zip_cnt(LastName, Zipcode);

create table x_ln_zip_unique as
select distinct a.MRN, a.LastName, a.Zipcode
from x_pt_processed a
join x_ln_zip_cnt b on a.LastName = b.LastName and a.Zipcode = b.Zipcode
where b.cnt = 1 ;
create unique index on x_ln_zip_unique(LastName, Zipcode);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'last,zip'::text as matched_path
from x_ec_processed a
join x_ln_zip_unique b on a.EC_LastName = b.LastName and a.EC_Zipcode = b.Zipcode;

drop table x_ln_zip_distint, x_ln_zip_cnt, x_ln_zip_unique;

-- map Phone, Zipcode
create table x_ph_zip_distint as
select distinct MRN, PhoneNumber, Zipcode
from x_pt_processed;

create table x_ph_zip_cnt as
select a.PhoneNumber, a.Zipcode, count(distinct MRN) as cnt
from x_ph_zip_distint a
group by a.PhoneNumber, a.Zipcode;
create unique index on x_ph_zip_cnt(PhoneNumber, Zipcode);

create table x_ph_zip_unique as
select distinct a.MRN, a.PhoneNumber, a.Zipcode
from x_pt_processed a
join x_ph_zip_cnt b on a.PhoneNumber = b.PhoneNumber and a.Zipcode = b.Zipcode
where b.cnt = 1 ;
create unique index on x_ph_zip_unique(PhoneNumber, Zipcode);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'phone,zip'::text as matched_path
from x_ec_processed a
join x_ph_zip_unique b on a.EC_PhoneNumber = b.PhoneNumber and a.EC_Zipcode = b.Zipcode;

drop table if exists x_ph_zip_distint, x_ph_zip_cnt, x_ph_zip_unique;

-- map FirstName,LastName,Phone
create table x_fn_ln_ph_distint as
select distinct MRN, FirstName, LastName, PhoneNumber
from x_pt_processed;

create table x_fn_ln_ph_cnt  as
select a.FirstName, a.LastName, a.PhoneNumber, count(distinct MRN) as cnt
from x_fn_ln_ph_distint a
group by a.FirstName, a.LastName, a.PhoneNumber;
create unique index on x_fn_ln_ph_cnt(FirstName, LastName, PhoneNumber);

create table x_fn_ln_ph_unique as
select distinct a.MRN, a.FirstName, a.LastName, a.PhoneNumber
from x_pt_processed a
join x_fn_ln_ph_cnt b on a.FirstName = b.FirstName and a.LastName = b.LastName and a.PhoneNumber = b.PhoneNumber
where b.cnt = 1 ;
create unique index on x_fn_ln_ph_unique(FirstName, LastName, PhoneNumber);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,last,zip'::text as matched_path
from x_ec_processed a
join x_fn_ln_ph_unique b on a.EC_FirstName = b.FirstName and a.EC_LastName = b.LastName and a.EC_PhoneNumber = b.PhoneNumber;

drop table x_fn_ln_ph_distint, x_fn_ln_ph_cnt, x_fn_ln_ph_unique;

-- map FirstName,LastName,Zipcode
create table x_fn_ln_zip_distint as
select distinct MRN, FirstName, LastName, Zipcode
from x_pt_processed;

create table x_fn_ln_zip_cnt as
select a.FirstName, a.LastName, a.Zipcode, count(distinct MRN) as cnt
from x_fn_ln_zip_distint a
group by a.FirstName, a.LastName, a.Zipcode;
create unique index on x_fn_ln_zip_cnt(FirstName, LastName, Zipcode);

create table x_fn_ln_zip_unique as
select distinct a.MRN, a.FirstName, a.LastName, a.Zipcode
from x_pt_processed a
join x_fn_ln_zip_cnt b on a.FirstName = b.FirstName and a.LastName = b.LastName and a.Zipcode = b.Zipcode
where b.cnt = 1 ;
create unique index on x_fn_ln_zip_unique(FirstName, LastName, Zipcode);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,last,zip'::text as matched_path
from x_ec_processed a
join x_fn_ln_zip_unique b on a.EC_FirstName = b.FirstName and a.EC_LastName = b.LastName and a.EC_Zipcode = b.Zipcode;

drop table x_fn_ln_zip_distint, x_fn_ln_zip_cnt, x_fn_ln_zip_unique;

-- map FirstName,Phone,Zipcode
create table x_fn_ph_zip_distint as
select distinct MRN, FirstName, PhoneNumber, Zipcode
from x_pt_processed;

create table x_fn_ph_zip_cnt as
select a.FirstName, a.PhoneNumber, a.Zipcode, count(distinct MRN) as cnt
from x_fn_ph_zip_distint a
group by a.FirstName, a.PhoneNumber, a.Zipcode;
create unique index on x_fn_ph_zip_cnt(FirstName, PhoneNumber, Zipcode);

create table x_fn_ph_zip_unique as
select distinct a.MRN, a.FirstName, a.PhoneNumber, a.Zipcode
from x_pt_processed a
join x_fn_ph_zip_cnt b on a.FirstName = b.FirstName and a.PhoneNumber = b.PhoneNumber and a.Zipcode = b.Zipcode
where b.cnt = 1 ;
create unique index on x_fn_ph_zip_unique(FirstName, PhoneNumber, Zipcode);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,phone,zip'::text as matched_path
from x_ec_processed a
join x_fn_ph_zip_unique b on a.EC_FirstName = b.FirstName and a.EC_PhoneNumber = b.PhoneNumber and a.EC_Zipcode = b.Zipcode;

drop table x_fn_ph_zip_distint, x_fn_ph_zip_cnt, x_fn_ph_zip_unique;

-- map LastName,Phone,Zipcode
create table x_ln_ph_zip_distint as
select distinct MRN, LastName, PhoneNumber, Zipcode
from x_pt_processed;

create table x_ln_ph_zip_cnt as
select a.LastName, a.PhoneNumber, a.Zipcode, count(distinct MRN) as cnt
from x_ln_ph_zip_distint a
group by a.LastName, a.PhoneNumber, a.Zipcode;
create unique index on x_ln_ph_zip_cnt(LastName, PhoneNumber, Zipcode);

create table x_ln_ph_zip_unique as
select distinct a.MRN, a.LastName, a.PhoneNumber, a.Zipcode
from x_pt_processed a
join x_ln_ph_zip_cnt b on a.LastName = b.LastName and a.PhoneNumber = b.PhoneNumber and a.Zipcode = b.Zipcode
where b.cnt = 1 ;
create unique index on x_ln_ph_zip_unique(LastName, PhoneNumber, Zipcode);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'last,phone,zip'::text matched_path
from x_ec_processed a
join x_ln_ph_zip_unique b on a.EC_LastName = b.LastName and a.EC_PhoneNumber = b.PhoneNumber and a.EC_Zipcode = b.Zipcode;

drop table x_ln_ph_zip_distint, x_ln_ph_zip_cnt, x_ln_ph_zip_unique;

-- map FirstName,LastName,Phone,Zipcode
create table x_fn_ln_ph_zip_distint as
select distinct MRN, FirstName, LastName, PhoneNumber, Zipcode
from x_pt_processed;

create table x_fn_ln_ph_zip_cnt as
select a.FirstName, a.LastName, a.PhoneNumber, a.Zipcode, count(distinct MRN) as cnt
from x_fn_ln_ph_zip_distint a
group by a.FirstName, a.LastName, a.PhoneNumber, a.Zipcode;
create unique index on x_fn_ln_ph_zip_cnt(FirstName, LastName, PhoneNumber, Zipcode);

create table x_fn_ln_ph_zip_unique as
select distinct a.MRN, a.FirstName, a.LastName, a.PhoneNumber, a.Zipcode
from x_pt_processed a
join x_fn_ln_ph_zip_cnt b on a.FirstName = b.FirstName and a.LastName = b.LastName and a.PhoneNumber = b.PhoneNumber and a.Zipcode = b.Zipcode
where b.cnt = 1 ;
create unique index on x_fn_ln_ph_zip_unique(FirstName, LastName, PhoneNumber, Zipcode);

insert into x_cumc_patient_matched
select distinct a.MRN_1 as empi_or_mrn, a.EC_Relationship as relationship, b.MRN as relation_empi_or_mrn, 'first,last,phone,zip'::text as matched_path
from x_ec_processed a
join x_fn_ln_ph_zip_unique b on a.EC_FirstName = b.FirstName and a.EC_LastName = b.LastName and a.EC_PhoneNumber = b.PhoneNumber and a.EC_Zipcode = b.Zipcode;

drop table if exists x_fn_ln_ph_zip_distint, x_fn_ln_ph_zip_cnt, x_fn_ln_ph_zip_unique;
