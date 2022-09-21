

DROP TABLE IF EXISTS ACTUAL_AND_INF_REL_CLEAN_FINAL;

CREATE TABLE ACTUAL_AND_INF_REL_CLEAN_FINAL (
  mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  provided_relationship int DEFAULT NULL,
  conflicting_provided_relationship int DEFAULT NULL,
  relationship_specific varchar(25) DEFAULT NULL,
  unique(mrn),
  unique(relation_mrn)
) ;




DROP TABLE IF EXISTS ACTUAL_AND_INF_REL_CLEAN_FINAL_count_rels;

CREATE TABLE ACTUAL_AND_INF_REL_CLEAN_FINAL_count_rels (
  family_id varchar(20) DEFAULT NULL,
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  num_uniq_rels bigint NOT NULL DEFAULT '0'
); 




DROP TABLE IF EXISTS actual_and_inf_rel_part1;

CREATE TABLE actual_and_inf_rel_part1 (
  mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  infer int DEFAULT NULL
); 




DROP TABLE IF EXISTS actual_and_inf_rel_part1_unique;

CREATE TABLE actual_and_inf_rel_part1_unique (
  mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  provided_relationship int DEFAULT NULL,
  unique(mrn,relation_mrn)
); 




DROP TABLE IF EXISTS actual_and_inf_rel_part1_unique_clean;

CREATE TABLE actual_and_inf_rel_part1_unique_clean (
  mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  provided_relationship int DEFAULT NULL,
  conflicting_provided_relationship int DEFAULT NULL,
  relationship_specific varchar(25) DEFAULT NULL,
  unique(mrn),
  unique(relation_mrn)
); 




DROP TABLE IF EXISTS actual_and_inf_rel_part2;

CREATE TABLE actual_and_inf_rel_part2 (
  mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  infer int DEFAULT NULL
); 




DROP TABLE IF EXISTS actual_and_inf_rel_part2_unique;

CREATE TABLE actual_and_inf_rel_part2_unique (
  mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  provided_relationship int DEFAULT NULL,
  unique(mrn),
  unique(relation_mrn)
); 




DROP TABLE IF EXISTS actual_and_inf_rel_part2_unique_clean;

CREATE TABLE actual_and_inf_rel_part2_unique_clean (
  mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  provided_relationship int DEFAULT NULL,
  conflicting_provided_relationship int DEFAULT NULL,
  relationship_specific varchar(25) DEFAULT NULL,
  unique(mrn),
  unique(relation_mrn)
); 




DROP TABLE IF EXISTS all_relationships_to_generate_family_id;

CREATE TABLE all_relationships_to_generate_family_id (
  mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL
); 




DROP TABLE IF EXISTS all_relationships_to_generate_pedigree_file;

CREATE TABLE all_relationships_to_generate_pedigree_file (
  mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  provided_relationship int DEFAULT NULL,
  unique(mrn),
  unique(relation_mrn)
); 




DROP TABLE IF EXISTS columbia_pedigree;

CREATE TABLE columbia_pedigree (
  family_id int NOT NULL,
  individual_id varchar(20) DEFAULT NULL,
  father_id varchar(20) DEFAULT NULL,
  mother_id varchar(20) DEFAULT NULL,
  own_ancestor int DEFAULT NULL,
  unique(individual_id),
  unique(family_id, individual_id)
); 




DROP TABLE IF EXISTS delete_part1_child_in_law_cases;

CREATE TABLE delete_part1_child_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part1_child_nephew_niece_cases;

CREATE TABLE delete_part1_child_nephew_niece_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part1_grandaunt_in_law_cases;

CREATE TABLE delete_part1_grandaunt_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part1_grandchild_in_law_cases;

CREATE TABLE delete_part1_grandchild_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part1_grandnephew_in_law_cases;

CREATE TABLE delete_part1_grandnephew_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part1_grandparent_in_law_cases;

CREATE TABLE delete_part1_grandparent_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part1_greatgrandchild_in_law_cases;

CREATE TABLE delete_part1_greatgrandchild_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part1_greatgrandparent_in_law_cases;

CREATE TABLE delete_part1_greatgrandparent_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part1_nephew_in_law_cases;

CREATE TABLE delete_part1_nephew_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part1_parent_aunt_uncle_cases;

CREATE TABLE delete_part1_parent_aunt_uncle_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part1_parent_in_law_cases;

CREATE TABLE delete_part1_parent_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part1_sibling_cousin_cases;

CREATE TABLE delete_part1_sibling_cousin_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part1_sibling_in_law_cases;

CREATE TABLE delete_part1_sibling_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_child_in_law_cases;

CREATE TABLE delete_part2_child_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_child_nephew_niece_cases;

CREATE TABLE delete_part2_child_nephew_niece_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_grandaunt_in_law_cases;

CREATE TABLE delete_part2_grandaunt_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_grandchild_in_law_cases;

CREATE TABLE delete_part2_grandchild_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_grandnephew_in_law_cases;

CREATE TABLE delete_part2_grandnephew_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_grandparent_in_law_cases;

CREATE TABLE delete_part2_grandparent_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_greatgrandchild_in_law_cases;

CREATE TABLE delete_part2_greatgrandchild_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_greatgrandparent_in_law_cases;

CREATE TABLE delete_part2_greatgrandparent_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_nephew_in_law_cases;

CREATE TABLE delete_part2_nephew_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_parent_aunt_uncle_cases;

CREATE TABLE delete_part2_parent_aunt_uncle_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_parent_in_law_cases;

CREATE TABLE delete_part2_parent_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_sibling_cousin_cases;

CREATE TABLE delete_part2_sibling_cousin_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS delete_part2_sibling_in_law_cases;

CREATE TABLE delete_part2_sibling_in_law_cases (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS ec_clean;

CREATE TABLE ec_clean (
  MRN_1 varchar(20) DEFAULT NULL,
  EC_FirstName varchar(255) DEFAULT NULL,
  EC_LastName varchar(255) DEFAULT NULL,
  EC_PhoneNumber varchar(20) DEFAULT NULL,
  EC_Zipcode varchar(20) DEFAULT NULL,
  EC_Relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS ec_exclude;

CREATE TABLE ec_exclude (
  relation_mrn varchar(25) DEFAULT NULL,
--  count(distinct m.mrn) bigint NOT NULL DEFAULT '0',
  MRN varchar(20) DEFAULT NULL,
  FirstName varchar(255) DEFAULT NULL,
  LastName varchar(255) DEFAULT NULL,
  PhoneNumber varchar(20) DEFAULT NULL,
  Zipcode varchar(20) DEFAULT NULL
); 




DROP TABLE IF EXISTS epic_relationshipcodes_fromBen;

CREATE TABLE epic_relationshipcodes_fromBen (
  rel_code varchar(4) DEFAULT NULL,
  relationship varchar(30) DEFAULT NULL
); 




DROP TABLE IF EXISTS family_IDs;

CREATE TABLE family_IDs (
  family_id varchar(20) DEFAULT NULL,
  individual_id varchar(20) DEFAULT NULL,
  unique(individual_id),
  unique(family_id, individual_id)
); 




DROP TABLE IF EXISTS family_ids_count_conflicted;

CREATE TABLE family_ids_count_conflicted (
  family_id varchar(20) DEFAULT NULL,
  num_individuals bigint NOT NULL DEFAULT '0',
  num_rels_conflicted decimal(23,0) DEFAULT NULL,
  unique(family_id)
); 




DROP TABLE IF EXISTS family_ids_forpedigree;

CREATE TABLE family_ids_forpedigree (
  family_id varchar(20) DEFAULT NULL,
  individual_id varchar(20) DEFAULT NULL,
  unique(individual_id)
); 




DROP TABLE IF EXISTS matches_wo_spouse;

CREATE TABLE matches_wo_spouse (
  mrn varchar(25) DEFAULT NULL,
  relationship_group varchar(255) DEFAULT NULL,
  relation_mrn varchar(25) DEFAULT NULL,
  matched_paths varchar(255)[] DEFAULT NULL,
  unique(relation_mrn)
); 




DROP TABLE IF EXISTS patient_relations_w_opposites_clean;

CREATE TABLE patient_relations_w_opposites_clean (
  mrn varchar(25) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(25) DEFAULT NULL,
  unique(mrn),
  unique(relation_mrn)
); 




DROP TABLE IF EXISTS patient_relations_w_opposites_part2;

CREATE TABLE patient_relations_w_opposites_part2 (
  mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL
); 




DROP TABLE IF EXISTS provided_relationships_conflicting;

CREATE TABLE provided_relationships_conflicting (
  mrn varchar(20) DEFAULT NULL,
  relation_mrn varchar(20) DEFAULT NULL--,
  -- count(relationship) bigint NOT NULL DEFAULT '0'
); 




DROP TABLE IF EXISTS pt_demog;

CREATE TABLE pt_demog (
  mrn varchar(20) DEFAULT NULL,
  year int DEFAULT NULL,
  sex varchar(1) DEFAULT NULL,
  unique(mrn)
); 




DROP TABLE IF EXISTS pt_matches;

CREATE TABLE pt_matches (
  mrn varchar(25) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(25) DEFAULT NULL,
  matched_path varchar(255)[] DEFAULT NULL,
  -- unique(mrn),
  -- unique(relation_mrn)
  -- unique(mrn, relation_mrn)
); 




DROP TABLE IF EXISTS relations_matched_clean;

CREATE TABLE relations_matched_clean (
  mrn varchar(25) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(25) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL,
  DOB_empi varchar(4) DEFAULT NULL,
  DOB_matched varchar(4) DEFAULT NULL,
  age_dif float DEFAULT NULL
); 




DROP TABLE IF EXISTS relations_matched_mrn_fixed_flipped_rel;

CREATE TABLE relations_matched_mrn_fixed_flipped_rel (
  mrn varchar(25) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_mrn varchar(25) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL,
  DOB_empi varchar(4) DEFAULT NULL,
  DOB_matched varchar(4) DEFAULT NULL,
  age_dif float DEFAULT NULL
); 




DROP TABLE IF EXISTS relations_matched_mrn_with_age_dif;

CREATE TABLE relations_matched_mrn_with_age_dif (
  mrn varchar(25) DEFAULT NULL,
  relationship_group varchar(255) DEFAULT NULL,
  relation_mrn varchar(25) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL,
  DOB_empi varchar(4) DEFAULT NULL,
  DOB_matched varchar(4) DEFAULT NULL,
  age_dif float DEFAULT NULL,
  exclude varchar(3) DEFAULT NULL
); 




DROP TABLE IF EXISTS relationship_lookup;

CREATE TABLE relationship_lookup (
  relationship varchar(50) NOT NULL,
  relationship_name varchar(255) DEFAULT NULL,
  relationship_group varchar(255) DEFAULT NULL,
  opposite_relationship_group varchar(255) DEFAULT NULL,
  PRIMARY key(relationship)
); 




DROP TABLE IF EXISTS relationships_and_opposites;

CREATE TABLE relationships_and_opposites (
  relationship varchar(255) NOT NULL,
  relationship_opposite varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_ec_processed;

CREATE TABLE x_ec_processed (
  MRN_1 varchar(20) DEFAULT NULL,
  EC_FirstName varchar(255) DEFAULT NULL,
  EC_LastName varchar(255) DEFAULT NULL,
  EC_PhoneNumber varchar(20) DEFAULT NULL,
  EC_Zipcode varchar(20) DEFAULT NULL,
  EC_Relationship varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_fn_ln_matched;

CREATE TABLE x_fn_ln_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_fn_ln_ph_matched;

CREATE TABLE x_fn_ln_ph_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_fn_ln_ph_zip_matched;

CREATE TABLE x_fn_ln_ph_zip_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_fn_ln_zip_matched;

CREATE TABLE x_fn_ln_zip_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_fn_matched;

CREATE TABLE x_fn_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_fn_ph_matched;

CREATE TABLE x_fn_ph_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_fn_ph_zip_matched;

CREATE TABLE x_fn_ph_zip_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_fn_zip_matched;

CREATE TABLE x_fn_zip_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_ln_matched;

CREATE TABLE x_ln_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_ln_ph_matched;

CREATE TABLE x_ln_ph_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_ln_ph_zip_matched;

CREATE TABLE x_ln_ph_zip_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_ln_zip_matched;

CREATE TABLE x_ln_zip_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_ph_matched;

CREATE TABLE x_ph_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_ph_zip_matched;

CREATE TABLE x_ph_zip_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 




DROP TABLE IF EXISTS x_pt_processed;

CREATE TABLE x_pt_processed (
  MRN varchar(20) DEFAULT NULL,
  FirstName varchar(255) DEFAULT NULL,
  LastName varchar(255) DEFAULT NULL,
  PhoneNumber varchar(20) DEFAULT NULL,
  Zipcode varchar(20) DEFAULT NULL,
  unique(MRN)
); 




DROP TABLE IF EXISTS x_zip_matched;

CREATE TABLE x_zip_matched (
  empi_or_mrn varchar(20) DEFAULT NULL,
  relationship varchar(255) DEFAULT NULL,
  relation_empi_or_mrn varchar(20) DEFAULT NULL,
  matched_path varchar(255) DEFAULT NULL
); 
