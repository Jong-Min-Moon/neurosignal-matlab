import networkx as nx
import matplotlib.pyplot as plt
import numpy as np
import copy
from networkx.algorithms import community
import matplotlib.animation as animation
import community as lvcm
import scipy
import pickle
import pandas as pd   
import os
import plotly.graph_objects as go
import interpol as itp
import random


pwd = os.path.dirname(os.path.realpath(__file__))
pwd = pwd + "/pkls"
distMat = np.load(pwd + "/score_matrix.npy")

positions = pd.read_pickle(pwd + "/positions.pkl")
positions.columns = ["channelNum", "xPos", "yPos", "zPos"]
positions['channelNum'] = positions['channelNum'].astype('int')
positions.set_index("channelNum", inplace = True)

# threshold
thres_data = pd.read_pickle(pwd + "/thres.pkl")
thres = thres_data.iloc[0]


G = nx.Graph()

## channel list
channel_list = ["{}".format(int(i)) for i in positions.index]
# list of strings.
# Since channels might have been deleted, one should avoid using range() and always refer to this list


## We set each channel as a node (e.g., circles in the network map)
for channelNum in channel_list:
    G.add_node(channelNum, pos = positions.loc[int(channelNum)] )
pos = nx.get_node_attributes(G,'pos')


## we set the degree of synchronization between the electrodes as an edge
## (e.g., lines in the network map).
n_nodes = len(channel_list) # number of nodes = number of channels

for i in range(n_nodes):
    for j in range(i+1, n_nodes):
        sync_score = distMat[i,j]
        # the links with synchronized scores less than thres were filtered out.
        if (sync_score >= thres):
            G.add_edge(channel_list[i], channel_list[j], weight = sync_score)


            #run Louvain method. result: dictionary {channelNum:communityNum}
partition = lvcm.best_partition(graph=G, partition=None, random_state = 1)

degree_dict = dict(G.degree)
partition_list = set(partition.values())

max_k_w = []
for com in partition_list: # loop over each community
    list_nodes = [int(channelNum) for channelNum in channel_list
        if partition[channelNum] == com
        ]
    max_k_w = max_k_w + [list_nodes]
     # list comprehension. concat [member list] of each community

channel_commu_pair = {}
for channelNum in channel_list: # loop over channels
    for color_code, nodes_sharing_community in enumerate(max_k_w): #loop over communities
        if int(channelNum) in nodes_sharing_community:
            if len(nodes_sharing_community) == 1:
                channel_commu_pair[int(channelNum)] = 0
            else:
                channel_commu_pair[int(channelNum)] = color_code + 1

commu_list = set(channel_commu_pair.values())
new_commu_list = list(range(len(commu_list)))
commu_list = sorted(list(commu_list))
channel_converter = dict(zip(commu_list, new_commu_list))

for channel in channel_commu_pair:
    old_commu = channel_commu_pair[channel] 
    new_commu = channel_converter[old_commu]
    channel_commu_pair[channel]  = new_commu

cluster_membership_pd = pd.DataFrame({"node" : channel_commu_pair.keys(), "community" : channel_commu_pair.values()})

cluster_membership_pd.groupby("community").agg(list).to_pickle(pwd + "/community_info.pkl")



#n_partition = np.array(max(partition_list) + 1)
#np.save(pwd + "/prelim_n_partition.npy", n_partition)

#partition_count = pd.DataFrame(pd.Series(sorted(list(partition.values()))).value_counts())
#partition_count.reset_index(inplace=True)
#partition_count = np.array(partition_count)
#partition_count[:,0] = partition_count[:,0] +1

#np.save(pwd + "/prelim_count_partition.npy", partition_count)