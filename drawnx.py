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

################################################
################################################
# load data

pwd = os.getcwd()
#1.  create network.
distMat = np.load(pwd + "/score_matrix.npy")

positions = pd.read_pickle(pwd + "/positions.pkl")

n_nodes = distMat.shape[1] # number of nodes = number of channels
G = nx.Graph()

#node_sizes
basic_size, multiplier = np.load(pwd + "/node_sizes.npy")

# colors
colors = pd.read_pickle(pwd + "/colors.pkl")
colorscale_edge = colors.iloc[0]
colorscale_node = colors.iloc[1]



# colors
lims = pd.read_pickle(pwd + "/lims.pkl")
lim_degree_low  = lims.iloc[0]
lim_degree_high = lims.iloc[1]
lim_edge_low    = lims.iloc[2]
lim_edge_high   = lims.iloc[3]
thres = lims.iloc[4]
community_max = lims.iloc[5]
lim_color_edge_low    = lims.iloc[6]
lim_color_edge_high   = lims.iloc[7]


# display_or_not
display_or_not = pd.read_pickle(pwd + "/display_or_not.pkl")
display_community_color  = display_or_not.iloc[0]
display_degree = display_or_not.iloc[1]
display_sync_score    = display_or_not.iloc[2]

################################################
################################################

# We set the electrode as a node (e.g., circles in the network map)
channel_list = ["{}".format(int(i)) for i in positions[0]] #list of strings


#pos = {}
for i in range(len(channel_list)):
    x_now = positions.iloc[i, 1]
    y_now = positions.iloc[i, 2]
    z_now = positions.iloc[i, 3]
    position_now = (int(x_now), int(y_now), int(z_now))
    G.add_node(channel_list[i], pos = position_now )
    #pos[channel_list[i]] = position_now
pos=nx.get_node_attributes(G,'pos')


# we set the degree of synchronization between the electrodes as an edge
# (e.g., lines in the network map).
for i in range(n_nodes):
    for j in range(i+1, n_nodes):
        sync_score = distMat[i,j]
        # the links with synchronized scores less than 0.5 were filtered out.
        if (sync_score >= thres):
            G.add_edge(channel_list[i], channel_list[j], weight = sync_score)




# Louvain method
partition = lvcm.best_partition(graph=G, partition=None, random_state = 1)
max_k_w = []
for com in set(partition.values()):
    list_nodes = [nodes for nodes in partition.keys() if partition[nodes] == com]
    list_nodes = [channel_list.index(node) for node in list_nodes]
    max_k_w = max_k_w + [list_nodes]
     # list comprehension. concat [member list] of each community

     
# Make Community Color list
# APPLY NODE FILTERING!
d = dict(G.degree)
degree_values = list(d.values())
community_num_group = len(max_k_w)
color_list_community = [[] for i in range(len(G.nodes())) 
if (degree_values[i]>=lim_degree_low) and (degree_values[i]<=lim_degree_high)
] # list comprehension. empty list of list

for i in range(len(color_list_community)):
    for j in range(community_num_group):
        if i in max_k_w[j]:
            color_list_community[i] = j

########################################################
########################################################
# 2022.12.08
Feature_color_sub = np.array(color_list_community)+1  # cluster num = 1, 2, 3, .... not 0 , 1, 2, ...

cluster_membership_pd = pd.DataFrame({"node" : np.arange(1,len(Feature_color_sub)+1), "community" : Feature_color_sub})
cluster_membership_pd.groupby("community").agg(list).to_csv("community_info.csv")  

########################################################
########################################################

edges = G.edges()
weights = [G[u][v]['weight'] for u, v in edges]


#degree = node size
d = dict(G.degree)
degree_values = d.values()
node_size_normalized = np.fromiter(degree_values, dtype = float)
degree_values = list(d.values())
node_size_normalized = (node_size_normalized - np.min(node_size_normalized))/(np.max(node_size_normalized) - np.min(node_size_normalized))







#we need to seperate the X,Y,Z coordinates for Plotly
x_nodes = [ pos[ str(i+1) ][0] for i in range(len(pos)) if (degree_values[i]>=lim_degree_low) and (degree_values[i]<=lim_degree_high)]# x-coordinates of nodes
y_nodes = [ pos[ str(i+1) ][1] for i in range(len(pos)) if (degree_values[i]>=lim_degree_low) and (degree_values[i]<=lim_degree_high)]# y-coordinates
z_nodes = [ pos[ str(i+1) ][2] for i in range(len(pos)) if (degree_values[i]>=lim_degree_low) and (degree_values[i]<=lim_degree_high)]# z-coordinates






#we  need to create lists that contain the starting and ending coordinates of each edge.
edge_list = G.edges()

x_edges=[]
y_edges=[]
z_edges=[]

weights = [G[u][v]['weight'] for u, v in edge_list if (G[u][v]['weight'] >= lim_edge_low) and (G[u][v]['weight'] <= lim_edge_high) and (int(d[u]) >= int(lim_degree_low)) and (int(d[u]) <= int(lim_degree_high)) and (int(d[v]) >= int(lim_degree_low)) and (int(d[v]) <= int(lim_degree_high))]
#need to fill these with all of the coordiates

for u,v in edge_list:
    #format: [beginning,ending,None]
    sync_score_now = G[u][v]['weight']
    if (sync_score_now >= lim_edge_low) and (sync_score_now <= lim_edge_high) and (int(d[u]) >= int(lim_degree_low)) and (int(d[u]) <= int(lim_degree_high)) and (int(d[v]) >= int(lim_degree_low)) and (int(d[v]) <= int(lim_degree_high)):
        x_coords = [
            pos[ u ][0],
            pos[ v ][0],
            None
            ]
        x_edges += x_coords

        y_coords = [pos[u][1],pos[v][1],None]
        y_edges += y_coords

        z_coords = [pos[u][2],pos[v][2],None]
        z_edges += z_coords





#####################################
#####################################
# 22.12.08. on/off features
# community color
if display_degree:
    node_size= basic_size + multiplier * (1 + node_size_normalized)
if not display_degree:
    node_size= basic_size + multiplier * (0 * (1 + node_size_normalized) + 1)

# node color
if display_community_color:
    node_dict = dict(
                            symbol='circle',
                                    size= node_size,
                                    cmin= 1,
                                    cmax = community_max,
                                    color=Feature_color_sub, #color the nodes according to their community
                                    colorscale=colorscale_node, #either green or mageneta
                                    line=dict(color='black', width=0.5),
                                    colorbar=dict(thickness=20, title= "community", xanchor = "right")
                                    )
if not display_community_color:
    node_dict = dict(
        symbol='circle',
        size= node_size,
        color = "yellow",
        line=dict(color='black', width=0.5),
                                    )

# edge color
if display_sync_score:
    linedict  = dict(
                            cmin = lim_color_edge_low,
                            cmax = lim_color_edge_high,
                            color= weights,
                            colorscale= colorscale_edge,
                            width=4,
                            colorbar=dict(thickness=20, title= "edges", xanchor = "left")                    
)
if not display_sync_score:
    linedict = dict(width=4)

trace_edges = go.Scatter3d(
    name = "Edges",
    x=x_edges,
    y=y_edges,
    z=z_edges,
    mode='lines',
    line=linedict,
    hoverinfo='none')

#create a trace for the nodes
trace_nodes = go.Scatter3d(
    name = "Community",
    x=x_nodes,
    y=y_nodes,
    z=z_nodes,
    mode='markers',
    marker = node_dict,
                        text=[f"Node {i+1} belongs to community {Feature_color_sub[i]}" for i in range(len(Feature_color_sub))],
                        hoverinfo='text',
                        showlegend = True
                        )

axis = dict(showbackground=False,
            showline=False,
            zeroline=False,
            showgrid=False,
            showticklabels=False,
            title='')
#also need to create the layout for our plot
layout = go.Layout(title="Community structure of the electrodes",
                width=650,
                height=625,
                showlegend=False,
                #scene=dict(
                #    xaxis=dict(axis),
                #    yaxis=dict(axis),
                #    zaxis=dict(axis),
               #         ),
                margin=dict(t=80),
                hovermode='closest')

data = [trace_edges, trace_nodes]
fig = go.Figure(data=data, layout=layout)

fig.write_html(pwd + "/networkfig.html")