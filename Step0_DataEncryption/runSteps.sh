#!/usr/bin/bash -e
if [[ $@ < 2 ]]
then
    printf "Need data dir and git root dir\n"
    printf "(This is exected to be called after \"%s/loadEDW.sh\")\n" $(dirname $0)
    printf "usage: %s <datadir> <gitdir>\n" $(basename $0)
    exit 2
fi

ml julia/1.7
ml gcc/4.8.5

function stager() {
    printf "Step %d.%d: %s\n" $1 $2 "$3"
}

DATADIR=/uufs/chpc.utah.edu/common/HIPAA/u0138544/gits/github/ds-ehr/data
RIFTDIR=/uufs/chpc.utah.edu/common/HIPAA/u0138544/gits/github/ds-ehr/riftehr
if [[ $# -gt 0 ]]; then DATADIR=$1; shift; fi ## have to name gitdir to set datadir
if [[ $# -gt 0 ]]; then RIFTDIR=$1; shift; fi

stager 1 1 "load data, find match"
STEPDIR=$RIFTDIR/Step1_MatchECtoDemog
psql --user postgres --dbname postgres --host csgsdb <<EOF
\timing on
\c riftehr
set search_path = cell, run, public;
\i $STEPDIR/find_matches.sql
EOF



stager 2 1 "generate opposites"
STEPDIR=$RIFTDIR/Step2_Relationship_Inference
psql --user postgres --dbname postgres --host csgsdb <<EOF
\timing on
\c riftehr
set search_path = cell, run, public;
\i $STEPDIR/1_exclude_EC_w_most_matches.sql
\i $STEPDIR/2_clean_up_BEFORE_inferring_relationships.sql
\copy patient_relations_w_opposites_clean to $DATADIR/patient_relations_w_opposites_clean.csv csv header
EOF

stager 2 3 "infer relationships (julia)"
time julia $STEPDIR/3_Infer_Relationships.jl $DATADIR
wc -l $DATADIR/output_actual_and_inferred_relationships.csv

stager 2 4 "clean-up post julia"
psql --user postgres --dbname postgres --host csgsdb <<EOF
\timing on
\c riftehr
set search_path = cell, run, public;
\copy actual_and_inf_rel_part1 from $DATADIR/output_actual_and_inferred_relationships.csv csv
\i $STEPDIR/4_clean_up_after_inferences_part1.sql
\copy patient_relations_w_opposites_part2 to $DATADIR/patient_relations_w_opposites_part2.csv csv;
EOF

stager 2 5  "families (julia)"
julia $STEPDIR/5_Infer_Relationships_part2.jl $DATADIR

stager 2 6 "clean up again"
psql --user postgres --dbname postgres --host csgsdb <<EOF
\timing on
\c riftehr
set search_path = cell, run, public;
\copy actual_and_inf_rel_part2 from $DATADIR/output_patient_relations_w_opposites_part2.csv csv
\i $STEPDIR/6_clean_up_after_inferences_part2.sql
EOF

ml gcc/10.2.0
ml python/3.9.7

STEPDIR=$RIFTDIR/Step3_AssignFamilyIDs
stager 3 1 "generate family"
psql --user postgres --dbname postgres --host csgsdb <<EOF
\timing on
\c riftehr
set search_path = cell, run, public;
\i $STEPDIR/create_table_to_generate_family_id.sql
\copy all_relationships_to_generate_family_id to $DATADIR/all_relationship.csv csv
EOF

stager 3 2 "python family id generator"
python3 $STEPDIR/All_relationships_family_ID.py $DATADIR/all_relationship.csv $DATADIR/all_families.csv

psql --user postgres --dbname postgres --host csgsdb <<EOF
\timing on
\c riftehr
set search_path = cell, run, public;
-- I don't see this table def, import anywhere...
drop table if exists family_ids\p\g
create table family_ids(id text, mrn text)\p\g
\copy family_ids from $DATADIR/all_families.csv csv
EOF

STEPDIR=$RIFTDIR/Step4_ConflictingRelationships
stager 4 1 "Conflict resolution"
psql --user postgres --dbname postgres --host csgsdb <<EOF
\timing on
\c riftehr
set search_path = cell, run, public;
\i $STEPDIR/identify_conflicting_relationships_with_family_id.sql
EOF

STEPDIR=$RIFTDIR/Step5_IdentifyTwins
stager 5 1 "Twins"

psql --user postgres --dbname postgres --host csgsdb <<EOF
\timing on
\c riftehr
set search_path = cell, run, public;
\i $STEPDIR/Twins.sql
EOF