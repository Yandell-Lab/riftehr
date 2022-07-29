#!/bin/bash -e
dbuser=$1; shift
dbhost=$1; shift
gitdir=$1; shift
datadir=$1; shift


psql --user $dbuser --host $dbhost --dbname=riftehr <<EOF
drop schema cell cascade;
\i $gitdir/Step0_DataEncryption/baseDDL.sql
set search_path = cell,public;
\copy cell.x_ec_processed from $datadir/emcon.data header csv
\copy cell.x_pt_processed from $datadir/patient.data header csv
\i $gitdir/Step1_MatchECtoDemog/find_matches.sql
EOF
