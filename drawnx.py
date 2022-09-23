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


pwd = os.getcwd()
#1.  create network.
distMat = np.load(pwd + "/score_matrix.npy")
#print(distMat)
positions = pd.read_pickle(pwd + "/positions.pkl")
#print(positions)
n_nodes = distMat.shape[1] # number of nodes = number of channels
G = nx.Graph()

# We set the electrode as a node (e.g., circles in the network map)
channel_list = ["{}".format(int(i)) for i in positions[0]]
#print(channel_list)
#G.add_nodes_from(channel_list)

#pos = {}
for i in range(len(channel_list)):
    x_now = positions.iloc[i, 1]
    y_now = positions.iloc[i, 2]
    z_now = positions.iloc[i, 3]
    position_now = (int(x_now), int(y_now), int(z_now))
    G.add_node(channel_list[i], pos = position_now )
    #pos[channel_list[i]] = position_now
pos=nx.get_node_attributes(G,'pos')
#print(pos)
# we set the degree of synchronization between the electrodes as an edge
# (e.g., lines in the network map).
for i in range(n_nodes):
    for j in range(i+1, n_nodes):
        sync_score = distMat[i,j]
        # the links with synchronized scores less than 0.5 were filtered out.
        if sync_score >= 1/2:
            
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
community_num_group = len(max_k_w)
color_list_community = [[] for i in range(len(G.nodes()))] # list comprehension. empty list of list

for i in range(len(G.nodes())):
   for j in range(community_num_group):
       if i in max_k_w[j]:
           color_list_community[i] = j
           



edges = G.edges()
weights = [G[u][v]['weight'] for u, v in edges]
Feature_color_sub = color_list_community

d = dict(G.degree)
node_size_normalized = np.fromiter(d.values(), dtype = float)
node_size_normalized = (node_size_normalized - np.min(node_size_normalized))/(np.max(node_size_normalized) - np.min(node_size_normalized))


#we need to seperate the X,Y,Z coordinates for Plotly
x_nodes = [ pos[ str(i+1) ][0] for i in range(len(pos)) ]# x-coordinates of nodes
y_nodes = [ pos[ str(i+1) ][1] for i in range(len(pos)) ]# y-coordinates
z_nodes = [ pos[ str(i+1) ][2] for i in range(len(pos)) ]# z-coordinates

#we  need to create lists that contain the starting and ending coordinates of each edge.
edge_list = G.edges()
x_edges=[]
y_edges=[]
z_edges=[]

#need to fill these with all of the coordiates
for edge in edge_list:
    #format: [beginning,ending,None]
    x_coords = [pos[edge[0]][0],pos[edge[1]][0],None]
    x_edges += x_coords

    y_coords = [pos[edge[0]][1],pos[edge[1]][1],None]
    y_edges += y_coords

    z_coords = [pos[edge[0]][2],pos[edge[1]][2],None]
    z_edges += z_coords

trace_edges = go.Scatter3d(
    name = "Edges",
    x=x_edges,
                        y=y_edges,
                        z=z_edges,
                        mode='lines',
                        line=dict(
                            color= weights,
                            colorscale=['blue','red'],
                            width=4,
                            colorbar=dict(thickness=20, title= "edges", xanchor = "left")                    
),
                        hoverinfo='none')

#create a trace for the nodes
trace_nodes = go.Scatter3d(
    name = "Community",
    x=x_nodes,
    y=y_nodes,
    z=z_nodes,
    mode='markers',
                        marker=dict(
                            symbol='circle',
                                    size= 10 + 20 * (1 + node_size_normalized),
                                    color=Feature_color_sub, #color the nodes according to their community
                                    colorscale=['lightgreen','magenta'], #either green or mageneta
                                    line=dict(color='black', width=0.5),
                                    colorbar=dict(thickness=20, title= "community", xanchor = "right")
                                    ),
                        text=Feature_color_sub,
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
                scene=dict(xaxis=dict(axis),
                        yaxis=dict(axis),
                        zaxis=dict(axis),
                        ),
                margin=dict(t=100),
                hovermode='closest')

data = [trace_edges, trace_nodes]
fig = go.Figure(data=data, layout=layout)

fig.write_html(pwd + "/networkfig.html")