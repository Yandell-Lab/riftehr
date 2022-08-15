"""
March 10, 2016 rewrite of code to match emergency contacts to patient demographics.

@authors Fernanda Polubriaginof and Nicholas Tatonetti

USAGE:
python find_matches.py ec_file.txt pt_file.txt results_file.txt [start:end]
"""

import os
import sys
import csv
import bisect

from tqdm import tqdm
from collections import defaultdict

ec_fn = sys.argv[1]
pt_fn = sys.argv[2]
ma_fn = sys.argv[3]

print( "Running find_matches.py with following arguments:", file=sys.stderr)
print( "\tec_fn = ", ec_fn, file=sys.stderr)
print( "\tpt_fn = ", pt_fn, file=sys.stderr)
print( "\tma_fn = ", ma_fn, file=sys.stderr)

start = 0
end = None
if len(sys.argv) == 5:
    start, end = map(int, sys.argv[4].split(':'))
    print( "\toperating on subset: %d - %d" % (start, end), file=sys.stderr)

# read in the emergency contact data
delim = '\t' if ec_fn.endswith('txt') else ','
reader = csv.reader(open(ec_fn, 'rU'), delimiter=delim)
h = reader.next()
exp_header = ['MRN_1', 'EC_FirstName', 'EC_LastName', 'EC_PhoneNumber', 'EC_Zipcode', 'EC_Relationship']
if not h == exp_header:
    raise Exception("Emergency contact data file (%s) doesn't have the header expected: %s" % (ec_fn, exp_header))

ec_data = list()
for mrn, fn, ln, phone, zipcode, rel in reader:
    fn = fn.strip().lower()
    ln = ln.strip().lower()
    
    first_names = [fn]
    if fn.replace('-', ' ').find(' ') != -1:
        first_names += fn.replace('-',' ').split(' ')
    
    last_names = [ln]
    if ln.replace('-', ' ').find(' ') != -1:
        last_names += ln.replace('-', ' ').split(' ')
            
    for fn_comp in first_names:
        for ln_comp in last_names:
            ec_data.append([mrn, fn_comp, ln_comp, phone, zipcode, rel])

# read in the patient demographics data
delim = '\t' if pt_fn.endswith('txt') else ','
reader = csv.reader(open(pt_fn, 'rU'), delimiter=delim)
h = reader.next()
exp_header = ['MRN', 'FirstName', 'LastName', 'PhoneNumber', 'Zipcode']
if not h == exp_header:
    raise Exception("Patient demographic data file (%s) doesn't have the header expected:%s" % (pt_fn, exp_header))
pt_data = list()
try:
    for i, (mrn, fn, ln, phone, zipcode) in enumerate(reader):
        fn = fn.strip().lower()
        ln = ln.strip().lower()

# This splitting does not deal with any input name containing a space or any other delimiter.
        first_names = [fn]
        if fn.replace('-', ' ').find(' ') != -1:
            first_names += fn.replace('-',' ').split(' ')
    
        last_names = [ln]
        if ln.replace('-', ' ').find(' ') != -1:
            last_names += ln.replace('-',' ').split(' ')

# Potentially multiple data records per input
        for fn_comp in first_names:
            for ln_comp in last_names:
                pt_data.append([mrn, fn_comp, ln_comp, phone, zipcode])
except Exception as e:
    #print( "Failed with error: %s" % csv.Error), (file=sys.stderr)
    print( "Failed in %s at line: %d with error: %s" % (pt_fn, i+2, e), file=sys.stderr)
    sys.exit(20)
    

print( "Parsed %d entries for EC and %d entries for PT" % (len(ec_data), len(pt_data)), file=sys.stderr)

# Using hashing to reduce the search space heuristically
print( "Building hash libraries...", file=sys.stderr)

first_hash = defaultdict( list )
last_hash = defaultdict(list)
phone_hash = defaultdict(list)
zip_hash = defaultdict(list)

num_char = 13
print( "\thashing num = %d" % num_char, file=sys.stderr)

# now we build the hashes, but we skip any blank entries
for pt in pt_data:
    mrn, fn, ln, phone, zipcode = pt
    if fn[:num_char] != '':
        first_hash[fn[:num_char]].append( pt )
    if ln[:num_char] != '':
        last_hash[ln[:num_char]].append( pt )
    if phone[:num_char] != '':
        phone_hash[phone[:num_char]].append( pt )
    if zipcode[:num_char] != '':
        zip_hash[zipcode[:num_char]].append( pt )

print( "\tfirst name hash has %d keys with an average of %.2f patients." % (len(first_hash), sum([len(v) for v in first_hash.values()])/float(len(first_hash))), file=sys.stderr)
print( "\tlast name hash has %d keys with an average of %.2f patients." % (len(last_hash), sum([len(v) for v in last_hash.values()])/float(len(last_hash))), file=sys.stderr)
print( "\tphone hash has %d keys with an average of %.2f patients." % (len(phone_hash), sum([len(v) for v in phone_hash.values()])/float(len(phone_hash))), file=sys.stderr)
print( "\tzipcode hash has %d keys with an average of %.2f patients." % (len(zip_hash), sum([len(v) for v in zip_hash.values()])/float(len(zip_hash))), file=sys.stderr)

# lets start with a brute force implementation
if end is None:
    end = len(ec_data)

ec_data_subet = ec_data[start:end]

#relationship_results = list()

ofh = open(ma_fn, 'w')
delim = '\t' if ma_fn.endswith('txt') else ','
writer = csv.writer(ofh, delimiter=delim)
#writer.writerow(['patient_mrn', 'relationship', 'matched_relation_mrn', 'matched_path'])

for pt_mrn, ec_first, ec_last, ec_phone, ec_zip, relationship in tqdm(ec_data_subet):
    
    # we match on each of the four datatypes: first name, last name, phone number, and zipcode
    # brute force approach
    #first_matches = set([pt[0] for pt in pt_data if pt[1] == ec_first])
    #last_matches = set([pt[0] for pt in pt_data if pt[2] == ec_last])
    #phone_matches = set([pt[0] for pt in pt_data if pt[3] == ec_phone])
    #zip_matches = set([pt[0] for pt in pt_data if pt[4] == ec_zip])


    # hashing approach
    first_matches = set([pt[0] for pt in first_hash[ec_first[:num_char]] if pt[1] == ec_first])
    last_matches = set([pt[0] for pt in last_hash[ec_last[:num_char]] if pt[2] == ec_last])
    phone_matches = set([pt[0] for pt in phone_hash[ec_phone[:num_char]] if pt[3] == ec_phone])
    zip_matches = set([pt[0] for pt in zip_hash[ec_zip[:num_char]] if pt[4] == ec_zip])
    
    # if any of these data types, on their own, produce only one mrn match, then we add it to a list
    matching_mrns = list()
    if len(first_matches) == 1:
        matching_mrns.extend([(mrn, 'first') for mrn in first_matches])
    if len(last_matches) == 1:
        matching_mrns.extend([(mrn, 'last') for mrn in last_matches])
    if len(phone_matches) == 1:
        matching_mrns.extend([(mrn, 'phone') for mrn in phone_matches])
    if len(zip_matches) == 1:
        matching_mrns.extend([(mrn, 'zip') for mrn in zip_matches])
    
    # now we try combinations of 2
    if len(first_matches & last_matches) == 1:
        matching_mrns.extend([(mrn, 'first,last') for mrn in (first_matches & last_matches)])
    if len(first_matches & phone_matches) == 1:
        matching_mrns.extend([(mrn, 'first,phone') for mrn in (first_matches & phone_matches)])
    if len(first_matches & zip_matches) == 1:
        matching_mrns.extend([(mrn, 'first,zip') for mrn in (first_matches & zip_matches)])
    
    if len(last_matches & phone_matches) == 1:
        matching_mrns.extend([(mrn, 'last,phone') for mrn in (last_matches & phone_matches)])
    if len(last_matches & zip_matches) == 1:
        matching_mrns.extend([(mrn, 'last,zip') for mrn in (last_matches & zip_matches)])
    
    if len(phone_matches & zip_matches) == 1:
        matching_mrns.extend([(mrn, 'phone,zip') for mrn in (phone_matches & zip_matches)])
    
    # now combinations of 3
    if len(first_matches & last_matches & phone_matches) == 1:
        matching_mrns.extend([(mrn, 'first,last,phone') for mrn in (first_matches & last_matches & phone_matches)])
    if len(first_matches & last_matches & zip_matches) == 1:
        matching_mrns.extend([(mrn, 'first,last,zip') for mrn in (first_matches & last_matches & zip_matches)])
    if len(first_matches & phone_matches & zip_matches) == 1:
        matching_mrns.extend([(mrn, 'first,phone,zip') for mrn in (first_matches & phone_matches & zip_matches)])
    if len(last_matches & phone_matches & zip_matches) == 1:
        matching_mrns.extend([(mrn, 'last,phone,zip') for mrn in (last_matches & phone_matches & zip_matches)])
    
    # finally the combination of all 4
    if len(first_matches & last_matches & phone_matches & zip_matches) == 1:
        matching_mrns.extend([(mrn, 'first,last,phone,zip') for mrn in (first_matches & last_matches & phone_matches & zip_matches)])
        
    for matched_mrn, path in matching_mrns:
        #relationship_results.append([pt_mrn, relationship, matched_mrn, path])
        writer.writerow([pt_mrn, relationship, matched_mrn, path])

# print( "Found %d EC -> PT matches, saving to file." % len(relationship_results), file=sys.stderr)

#wrifn[:13]ter.writerows(relationship_results)
ofh.close()
