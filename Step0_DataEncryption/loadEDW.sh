#!/usr/bin/bash -e
if [[ $@ < 3 ]]
then
    printf "Need data dir and git root dir and dbname\n"
    printf "usage: %s <datadir> <gitdir>\n" $(basename $0)
fi

DATADIR=$1; shift
STEPDIR=$1; shift
DBNAME=$1; shift

## We'll symlink EDW files to these names. Else explicit filenames needed on cmd line
ptfile=${DATADIR}/patient_edw.csv; 
ecfile=${DATADIR}/emcon_edw.csv;
dgfile=${DATADIR}/demog_edw.csv;
rlfile=${DATADIR}/localMatchedRelTypes ## our take on "relationship_lookup"
mofile=${DATADIR}/matchTypeOrder.csv ## our take on "match_path" value
rdfile=${DATADIR}/relationship_degree.csv  ## degree of relationship from relationship types used
for f in $ptfile $ecfile $dgfile $rlfile $mofile; do
    if [[ ! -e $f ]]; then echo cannot find data file $f; exit 2; fi
done

for f in $ptfile $ecfile $dgfile $rlfile $mofile; do
    wc -l $f
done

psql --user=cell --host=csgsdb --dbname=postgres <<EOF
select session_user;
select current_user;

drop database if exists $DBNAME;
create database $DBNAME tablespace = 'coon_d1';
\c $DBNAME

create schema cell;
create schema run;
set search_path = cell, run, public;

\i $STEPDIR/Step0_DataEncryption/clinical_relationships_v3_2022-08-11.sql3.sql
\i $STEPDIR/Step0_DataEncryption/baseDDL.sql

\copy  x_pt_processed       from  $ptfile   csv  delimiter  '|'  header
\copy  x_ec_processed       from  $ecfile   csv  delimiter  '|'  header
\copy  pt_demog             from  $dgfile   csv  delimiter  '|'  header
\copy  relationship_lookup  from  $rlfile   csv  delimiter  '|'  header
\copy  x_match_priority     from  $mofile   csv  delimiter  '|'
\copy  relationship_degree  from  $rdfile   csv  delimiter  ','  header

\i $STEPDIR/Step0_DataEncryption/1.initialCounts.sql

EOF
