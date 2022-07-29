"""
Script to compare output from two match scripts.

USAGE:
python compare_matches.py matchfile1.txt matchfile2.txt

@authors Fernanda Polubriaginof and Nicholas P. Tatonetti
"""

import os
import sys
import csv

fn1 = sys.argv[1]
d1 = '\t' if fn1.endswith('txt') else ','

fn2 = sys.argv[2]
d2 = '\t' if fn2.endswith('txt') else ','

print( "Comparing: %s and %s." % (fn1, fn2), file=sys.stderr)

pairs1 = set()
data1 = dict()
for row in csv.reader(open(fn1), delimiter=d1):
    pairs1.add( (row[0], row[2]) )
    data1[ (row[0], row[2]) ] = [row[1]] + row[3:]

pairs2 = set()
data2 = dict()
for row in csv.reader(open(fn2), delimiter=d2):
    pairs2.add( (row[0], row[2]) )
    data2[ (row[0], row[2]) ] = [row[1]] + row[3:]

print( "File 1 has %d pairs." % len(pairs1), file=sys.stderr)
print( "File 2 has %d pairs." % len(pairs2), file=sys.stderr)

print( "%d of %d are in common (%.3f%%)" % (len(pairs1 & pairs2), len(pairs1 | pairs2), len(pairs1 & pairs2)/float(len(pairs1 | pairs2))), file=sys.stderr)

diff1 = pairs1 - pairs2
if len(diff1) > 0:
    print( "The following pairs are unique to %s" % fn1, file=sys.stderr)
    for e1, e2 in diff1:
        val= data1[(e1,e2)]
        print( F"{e1}\t{e2}: {val}", file=sys.stderr)

diff2 = pairs2 - pairs1
if len(diff2) > 0:
    print( "The following pairs are unique to %s" % fn2, file=sys.stderr)
    for e1, e2 in diff2:
        val= data2[(e1,e2)]
        print( F"{e1}\t{e2}: {val}", file=sys.stderr)
