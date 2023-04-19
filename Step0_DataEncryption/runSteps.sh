#!/usr/bin/bash -e
if [[ $@ < 3 ]]
then
    printf "Need data dir and git root dir and dbname\n"
    printf "(This is exected to be called after \"%s/loadEDW.sh\")\n" $(dirname $0)
    printf "usage: %s <datadir> <gitdir> <dbname> [ STOPSTEP] \n" $(basename $0)
    printf "Also will react to evnvar STARTSTEP, as the point at which to start processing\n"
    printf "The value should be of the form n.m matching one of the stages:\n"
    printf "1.1, 1.2, 2.1, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 4.1, 5.1, 6.1, 7.1\n"
    exit 2
fi

ml julia/1.7
ml gcc/4.8.5

function stager() {
    local stp=$1
    local msg=$2
    if [[ x"$stp" == x"$STOPSTEP" ]]; then 
        printf "Stopping before %s (%s)\n" $stp "$msg"
        exit 1; 
    fi
    printf "Step %s: %s\n" $stp "$msg"
    date
}

DATADIR=/uufs/chpc.utah.edu/common/HIPAA/u0138544/gits/github/ds-ehr/data/verify
RIFTDIR=/uufs/chpc.utah.edu/common/HIPAA/u0138544/gits/github/ds-ehr/riftehr

if [[ $# -gt 0 ]]; then DATADIR=$1; echo override datadir; shift; fi ## have to name gitdir to set datadir
if [[ $# -gt 0 ]]; then RIFTDIR=$1; shift; fi
if [[ $# -gt 0 ]]; then DBNAME=$1; shift; fi
if [[ $# -gt 0 ]]; then STOPSTEP=$1; shift; fi;
if [[ $# -gt 0 ]]; then printf "WTF: %s\n" $1; shift exit 2; fi;


if [[ ! -z $STARTSTEP ]]; then echo Will start at $STARTSTEP; fi
if [[ -n $STOPSTEP ]]; then echo Will stop at $STOPSTEP; fi

STEPDIR=$RIFTDIR/Step1_MatchECtoDemog
if [[ -z $STARTSTEP || $STARTSTEP == "1.1" ]]
then
    unset STARTSTEP
    stager 1.1 "load data, find match $STEPDIR"
    psql --user cell --dbname $DBNAME --host csgsdb <<EOF
\timing on
set search_path = cell, run, public; 
\i $STEPDIR/find_matches.sql
EOF
fi

if [[ -z $STARTSTEP || $STARTSTEP == "1.2" ]]
then
    unset STARTSTEP
    stager 1.2 "UTAH-ONLY: load data, find match with ID $STEPDIR"
    psql --user cell --dbname $DBNAME --host csgsdb <<EOF
\timing on
set search_path = cell, run, public; 
\i $STEPDIR/id_matches.sql
EOF
fi

STEPDIR=$RIFTDIR/Step2_Relationship_Inference
if [[ -z $STARTSTEP || $STARTSTEP == "2.1" ]]
then
    unset STARTSTEP
    stager 2.1 "generate opposites $STEPDIR"
    psql --user cell --dbname $DBNAME --host csgsdb <<EOF
\timing on
set search_path = cell, run, public;
\i $STEPDIR/1_exclude_EC_w_most_matches.sql
\i $STEPDIR/2_clean_up_BEFORE_inferring_relationships.sql
\copy patient_relations_w_opposites_clean to $DATADIR/patient_relations_w_opposites_clean.csv csv header
EOF
fi

if [[ -z $STARTSTEP || $STARTSTEP == "2.3" ]]
then
    unset STARTSTEP
    stager 2.3 "infer relationships (julia)"
    time julia $STEPDIR/3_Infer_Relationships.jl $DATADIR
    wc -l $DATADIR/output_actual_and_inferred_relationships.csv
fi

if [[ -z $STARTSTEP || $STARTSTEP == "2.4" ]]
then
    unset STARTSTEP
    stager 2.4 "clean-up post julia"
    psql --user cell --dbname $DBNAME --host csgsdb <<EOF
\timing on
set search_path = cell, run, public;
\copy actual_and_inf_rel_part1 from $DATADIR/output_actual_and_inferred_relationships.csv csv
\i $STEPDIR/4_clean_up_after_inferences_part1.sql
\copy patient_relations_w_opposites_part2 to $DATADIR/patient_relations_w_opposites_part2.csv csv;
EOF
fi

if [[ -z $STARTSTEP || $STARTSTEP == "2.5" ]]
then
    unset STARTSTEP
    stager 2.5  "families (julia)"
    julia $STEPDIR/5_Infer_Relationships_part2.jl $DATADIR
fi


if [[ -z $STARTSTEP || $STARTSTEP == "2.6" ]]
then
    unset STARTSTEP
    stager 2.6 "clean up again"
    psql --user cell --dbname $DBNAME --host csgsdb <<EOF
\timing on
set search_path = cell, run, public;
select count(*) as n4_actual_and_inf_rel_part2 from actual_and_inf_rel_part2\p\g
\copy actual_and_inf_rel_part2 from $DATADIR/output_patient_relations_w_opposites_part2.csv csv
\i $STEPDIR/6_clean_up_after_inferences_part2.sql
EOF
fi

ml gcc/10.2.0
ml python/3.9.7

if [[ -z $STARTSTEP || $STARTSTEP == "3.1" ]]
then
    unset STARTSTEP
    STEPDIR=$RIFTDIR/Step3_AssignFamilyIDs
    stager 3.1 "generate family"
    psql --user cell --dbname $DBNAME --host csgsdb <<EOF
\timing on
set search_path = cell, run, public;
\i $STEPDIR/create_table_to_generate_family_id.sql
\copy all_relationships_to_generate_family_id to $DATADIR/all_relationship.csv csv
EOF
fi

if [[ -z $STARTSTEP || $STARTSTEP == "3.2" ]]
then
    unset STARTSTEP
    time sort -u $DATADIR/all_relationship.csv > $DATADIR/all_relationship.sorted.csv
    stager 3.2 "python family id generator"
    python3 $STEPDIR/All_relationships_family_ID.py $DATADIR/all_relationship.sorted.csv $DATADIR/all_families.csv
    psql --user cell --dbname $DBNAME --host csgsdb <<EOF
\timing on
set search_path = cell, run, public;
-- I don't see this table def, import anywhere...
drop table if exists family_ids\p\g
create table family_ids(family_id int, individual_id text)\p\g
\copy family_ids from $DATADIR/all_families.csv csv header
copy family_ids from $DATADIR/all_families.csv csv header\p\r
EOF
fi


if [[ -z $STARTSTEP || $STARTSTEP == "4.1" ]]
then
    unset STARTSTEP
    STEPDIR=$RIFTDIR/Step4_ConflictingRelationships
    stager 4.1 "Conflict resolution"
    psql --user cell --dbname $DBNAME --host csgsdb <<EOF
\timing on
set search_path = cell, run, public;
\i $STEPDIR/identify_conflicting_relationships_with_family_id.sql
EOF
fi

STEPDIR=$RIFTDIR/Step5_IdentifyTwins
if [[ -z $STARTSTEP || $STARTSTEP == "5.1" ]]
then
    unset STARTSTEP
    stager 5.1 "Twins"
    psql --user cell --dbname $DBNAME --host csgsdb <<EOF
\timing on
set search_path = cell, run, public;
\i $STEPDIR/Twins.sql
EOF
fi

STEPDIR=$RIFTDIR/Step6_Evaluation_mother_baby_linkage
if [[ -z $STARTSTEP || $STARTSTEP == "6.1" ]]
then
    unset STARTSTEP
    stager 6.1 "Mother-child"
    psql --user cell --dbname $DBNAME --host csgsdb <<EOF
\timing on
set search_path = cell, run, public;
\i $STEPDIR/evaluation_mother_baby.sql
EOF
fi
STEPDIR=$RIFTDIR/Step7_EMP
if [[ -z $STARTSTEP || $STARTSTEP == "7.1" ]]
then
    unset STARTSTEP
    stager 7.1 "UTAH extras"
    psql --user cell --dbname $DBNAME --host csgsdb <<EOF
\timing on
set search_path = cell, run, public;

drop table if exists all_relationship_s7;
create table all_relationship_s7(mrn text, relation text, relation_mrn text);
\copy all_relationship_s7 from $DATADIR/all_relationship.sorted.csv csv
copied all_relationship_s7 from $DATADIR/all_relationship.sorted.csv csv\p\r
\i $STEPDIR/0_infer.sql
\i $STEPDIR/1_reports.sql
\echo Step 7.2 multiparent.sql
\i $STEPDIR/2_multiparent.sql
\echo Step 7.3 child only
\i $STEPDIR/3_child_only.sql
EOF
fi
