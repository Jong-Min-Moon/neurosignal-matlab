import networkx as nx
import matplotlib.pyplot as plt
import numpy as np
import copy
from networkx.algorithms import community
import matplotlib.animation as animation
import community as lvcm
import scipy
import pickle
            
#1.  create network.
distMat = np.load("score_matrix.npy")
n_nodes = distMat.shape[1] # number of nodes = number of channels
G = nx.Graph()

# We set the electrode as a node (e.g., circles in the network map)
G.add_nodes_from(range(n_nodes))
        
# we set the degree of synchronization between the electrodes as an edge
# (e.g., lines in the network map).
for i in range(n_nodes):
    for j in range(i+1, n_nodes):
        sync_score = distMat[i,j]
        # the links with synchronized scores less than 0.5 were filtered out.
        if sync_score >= 1/2:
            G.add_edge(i, j, weight = sync_score)




# Louvain method
partition = lvcm.best_partition(graph=G, partition=None, random_state = 1)
max_k_w = []
for com in set(partition.values()):
    list_nodes = [nodes for nodes in partition.keys() if partition[nodes] == com]
    max_k_w = max_k_w + [list_nodes]
     # list comprehension. concat [member list] of each community

     
# Make Community Color list
community_num_group = len(max_k_w)
color_list_community = [[] for i in range(len(G.nodes()))] # list comprehension. empty list of list

for i in range(len(G.nodes())):
   for j in range(community_num_group):
       if i in max_k_w[j]:
           color_list_community[i] = j
           

# Plot Community           
fig, ax = plt.subplots()
edges = G.edges()
weights = [G[u][v]['weight'] for u, v in edges]
Feature_color_sub = color_list_community

d = dict(G.degree)

pos = {}
for key in d.keys():
    row_num = key // 8
    col_num = key % 8
    pos[key] = [row_num, col_num]


node_size_normalized = np.fromiter(d.values(), dtype = float)
print(node_size_normalized)
node_size_normalized = (node_size_normalized - np.min(node_size_normalized))/(np.max(node_size_normalized) - np.min(node_size_normalized))
nx.draw_networkx_nodes(
    G=G,
    pos = pos,
    nodelist=d.keys(),
    node_size = 30 * (1 + node_size_normalized),
    node_color=Feature_color_sub,
    cmap='jet',
    vmin=0,
    vmax=community_num_group,
    ax = ax )

edges = nx.draw_networkx_edges(
    G = G,
    pos = pos,
    edge_color = weights,
    width = 1.5,
    edge_cmap = plt.cm.Blues,
    ax = ax)
        #    %pyrun("plt.xticks([])")
        #    %pyrun("plt.yticks([])")
plt.colorbar(edges)
        #    %pyrun("plt.show(block=False)")

fig.savefig('networkfig.png')