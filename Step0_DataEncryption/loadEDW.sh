#!/usr/bin/bash -e
if [[ $@ < 2 ]]
then
    printf "Need data dir and git root dir\n"
    printf "usage: %s <datadir> <gitdir>\n" $(basename $0)
fi

DATADIR=$1; shift
STEPDIR=$1; shift

## We'll symlink EDW files to these names. Else explicit filenames needed on cmd line
ptfile=${DATADIR}/patient_edw.csv; 
ecfile=${DATADIR}/emcon_edw.csv;
dgfile=${DATADIR}/demog_edw.csv;
rlfile=${DATADIR}/localMatchedRelTypes ## our take on "relationship_lookup"

for f in $ptfile $ecfile $dgfile $rlfile; do
    if [[ ! -e $f ]]; then echo cannot find patient file $f; exit 2; fi
done

psql --user=postgres --host=csgsdb --dbname=postgres <<EOF
drop database riftehr;
create database riftehr;
\c riftehr
set search_path = cell, public;
\i $STEPDIR/Step0_DataEncryption/clinical_relationships_v3_2022-08-11.sql3.sql
\i $STEPDIR/Step0_DataEncryption/baseDDL.sql

set search_path = cell,run,public;
\copy  x_pt_processed       from  $ptfile   csv  delimiter  '|'  header
\copy  x_ec_processed       from  $ecfile   csv  delimiter  '|'  header
\copy  pt_demog             from  $dgfile   csv  delimiter  '|'  header
\copy  relationship_lookup  from  $rlfile   csv  delimiter  '|'  header
EOF

