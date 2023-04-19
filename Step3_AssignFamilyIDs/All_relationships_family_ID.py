"""
Use graph theory packages to identify disconnected subgraphs of the inferred relationship. 
Each disconnected subgraph is called a "family." Each family is assigned a single identifer.

@author Fernanda Polubriaginof and Nicholas Tatonetti

USAGE:
-----
python all_relationships.csv all_family_IDS.csv

"""

import networkx as nx
import matplotlib.pyplot as plt
import csv
import sys
import os
import networkx.algorithms.isomorphism as iso

infile = sys.argv[1]
outfile = sys.argv[2]
print(F"gen families:  reading {infile}")
reader = csv.reader(open(infile, 'r'), delimiter=',')
#header = reader.next() // no headers in \copy output

a = []
b = []
rel = []
all_relationships = []
for line in reader:
    a.append(line[0])
    b.append(line[2])
    rel.append(line[1])

for i in range(len(a)):
    all_relationships.append(tuple([a[i], b[i], rel[i]]))

u = nx.Graph()  # directed graph

for i in range(len(all_relationships)):
    arel = all_relationships[i]
    u.add_edge(arel[0], arel[1], rel=arel[2])

# Components sorted by size
## v2ism: comp = sorted(nx.connected_component_subgraphs(u), key=len, reverse=True)
comp = (u.subgraph(c) for c in nx.connected_components(u))
comp = sorted(list(comp), key = len, reverse = True)

outfh = open(outfile, 'w')
writer = csv.writer(outfh)
writer.writerow(['family_id', 'individual_id'])
for family_id in range(len(comp)):
    for individual_id in comp[family_id].nodes():
        writer.writerow([family_id, individual_id])
outfh.close()
