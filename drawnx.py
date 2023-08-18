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


pwd_thisfile = os.path.dirname(os.path.realpath(__file__))
pwd = pwd_thisfile + "/pkls"

pwd_save = pd.read_pickle(pwd + "/savepath.pkl")[0]


distMat = np.load(pwd + "/score_matrix.npy")

positions = pd.read_pickle(pwd + "/positions.pkl")
positions.columns = ["channelNum", "xPos", "yPos", "zPos"]
positions['channelNum'] = positions['channelNum'].astype('int')
positions.set_index("channelNum", inplace = True)


#node_sizes
basic_size, multiplier = np.load(pwd + "/node_sizes.npy")

# edge colors
colors = pd.read_pickle(pwd + "/colors.pkl")
edge_startcolor = colors.iloc[0]
edge_endcolor   = colors.iloc[1]

# node colors
commu_color_pair = list(pd.read_pickle(pwd + "/colors_node.pkl"))
commu_color_pair = "".join(commu_color_pair)

# limits
lims = pd.read_pickle(pwd + "/lims.pkl")
lim_degree_low  = lims.iloc[0]
lim_degree_high = lims.iloc[1]
lim_edge_low    = lims.iloc[2]
lim_edge_high   = lims.iloc[3]
#community_max = lims.iloc[4]
lim_color_edge_low    = lims.iloc[4]
lim_color_edge_high   = lims.iloc[5]

# threshold
thres_data = pd.read_pickle(pwd + "/thres.pkl")
thres = thres_data.iloc[0]


# display_or_not
display_or_not = pd.read_pickle(pwd + "/display_or_not.pkl")
display_community_color  = display_or_not.iloc[0]
display_degree = display_or_not.iloc[1]
display_sync_score    = display_or_not.iloc[2]
display_axes = display_or_not.iloc[3]

# camera
camera_params = np.load(pwd + "/camera.npy")
camera_up = camera_params[0:3]
camera_center = camera_params[3:6]
camera_eye = camera_params[6:9]


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
np.random.seed(1)
partition = lvcm.best_partition(graph=G, partition=None, random_state = 1)


degree_dict = dict(G.degree)
partition_list = set(partition.values())
    
max_k_w = []
for com in partition_list: # loop over each community
    list_nodes = [int(channelNum) for channelNum in channel_list
        if partition[channelNum] == com
        and degree_dict[channelNum]>=lim_degree_low # NODE FILTERING
        and degree_dict[channelNum]<=lim_degree_high # NODE FILTERING
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
print(channel_commu_pair)
n_commu = max(channel_commu_pair.values())
if commu_color_pair[:4] == 'grad':  
    is_display_node_colorbar = True
    commu_color_pair = commu_color_pair[4:]
    commu_color_pair = [commu_color_pair[:7], commu_color_pair[7:]]
    commu_color_pair = itp.interpolate(commu_color_pair[0], commu_color_pair[1], n_commu-1) 
else:
    is_display_node_colorbar = False
    commu_color_pair = "".join(commu_color_pair)
    commu_color_pair = commu_color_pair.split("#")
    commu_color_pair = ["#" + code for code in commu_color_pair]
commu_color_pair = dict(zip(
        list(range(0,len(commu_color_pair))), commu_color_pair
    ))
commu_color_pair[0] = "#f0efef"
print(commu_color_pair)

# save as csv (2022.12.08)
cluster_membership_pd = pd.DataFrame({"node" : channel_commu_pair.keys(), "community" : channel_commu_pair.values()})

cluster_membership_pd.groupby("community").agg(list).to_csv(
    os.path.join(pwd_save, "community_info.csv")
    )  


layout = go.Layout(title="Community structure of the electrodes",
                width=700,
                height=625,
                showlegend=False,
                margin=dict(t=80),
                hovermode='closest')

fig = go.Figure(layout=layout)


node_filter = [degree_dict[channelNum]>=lim_degree_low and degree_dict[channelNum]<=lim_degree_high for channelNum in channel_list]
x_nodes = np.array([ pos[ channelNum ][0] for channelNum in channel_list])[node_filter]# NODE FILTERING
y_nodes = np.array([ pos[ channelNum ][1] for channelNum in channel_list])[node_filter]# NODE FILTERING
z_nodes = np.array([ pos[ channelNum ][2] for channelNum in channel_list])[node_filter]# NODE FILTERING

d = dict(G.degree)
degree_values = d.values()



# degree normalization
node_size_normalized = np.fromiter(degree_values, dtype = float)
degree_values = list(d.values())
min_degree = np.min(node_size_normalized)
max_degree = np.max(node_size_normalized)
if min_degree == max_degree:
    node_size_normalized == node_size_normalized/max_degree
else:
    node_size_normalized = (node_size_normalized - min_degree)/(max_degree - min_degree)

# NODE FILTERING
node_size_normalized = np.array(node_size_normalized)[node_filter]
channel_list_filtered = np.array(channel_list)[node_filter]

# community color
if display_degree:
    node_size= basic_size + multiplier * (1+node_size_normalized)
if not display_degree:
    node_size= basic_size + multiplier * (0 * (1+node_size_normalized) + 1)

# node color
if display_community_color:
    for i in range(len(channel_list_filtered)):
        channelNum = int(channel_list_filtered[i])
        community_now =  channel_commu_pair[channelNum]
        color_now = commu_color_pair[community_now]
        degree_now = degree_dict[str(channelNum)]
    #for i, color_code in enumerate(channel_commu_pair):
        

        if is_display_node_colorbar == 1: #draw colorbar
            node_dict = dict(
            symbol='circle',
            size= node_size[i],                           
            color=color_now, #color the nodes according to their community
            line = dict(color='black', width=0),
            colorbar = dict(thickness=20, title= "communities", xanchor = "right")
            )
        else: #do not draw colorbar
            node_dict = dict(
            symbol='circle',
            size= node_size[i],                           
            color=color_now, #color the nodes according to their community
            line=dict(color='black', width=0)
            )

        fig.add_trace( go.Scatter3d(
            name = "Community",
            x = np.array(x_nodes[i]),
            y = np.array(y_nodes[i]),
            z = np.array(z_nodes[i]),
            mode='markers',
            marker = node_dict,
            text = f"Channel {channelNum} has degree {degree_now} and belongs to community {community_now}",
            hoverinfo='text',
            showlegend = True
        ))
if not display_community_color:
    node_dict = dict(
        symbol='circle',
        size= node_size,
        color = "yellow",
        line=dict(color='black', width=0),
                                    )
#create a trace for the nodes
    fig.add_trace( go.Scatter3d(
        name = "Community",
        x=x_nodes,
        y=y_nodes,
        z=z_nodes,
        mode='markers',
        marker = node_dict,
        text=[f"Channel {channelNum} has degree {degree_now} and belongs to community {community_now}" for channelNum in channel_list_filtered],
        hoverinfo='text',
        showlegend = True
        ))



#we  need to create lists that contain the starting and ending coordinates of each edge.
edge_list = G.edges()

x_edges=[]
y_edges=[]
z_edges=[]
weights = []
#need to fill these with all of the coordiates

for u,v in edge_list:
    #format: [beginning,ending,None]
    sync_score_now = G[u][v]['weight']
    if (sync_score_now >= lim_edge_low) and (sync_score_now <= lim_edge_high) and (int(d[u]) >= int(lim_degree_low)) and (int(d[u]) <= int(lim_degree_high)) and (int(d[v]) >= int(lim_degree_low)) and (int(d[v]) <= int(lim_degree_high)):
        weights.append(round(sync_score_now,3))
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



#also need to create the layout for our plot


axis = dict(showbackground=False,
            showline=False,
            zeroline=False,
            showgrid=False,
            showticklabels=False,
            title='')




#edge
n_step = int( 1000* lim_color_edge_high - 1000* lim_color_edge_low + 1)
weights_transformed = [int(1000 * (weight - lim_color_edge_low)) for weight in weights]
color_list = itp.interpolate(edge_startcolor, edge_endcolor, n_step)

edge_text = f"sync score: {round(weights[0],3)}"
if display_sync_score: 
    color_idx_now = weights_transformed[0]
    color_now = color_list[color_idx_now]
    fig.add_trace(go.Scatter3d(
            name = f"Edges_{0}",
            x = x_edges,
            y = y_edges,
            z = z_edges[0 : 2],
            mode = 'lines',
            line = dict(
                            cmin = lim_color_edge_low,
                            cmax = lim_color_edge_high,
                            color= color_now,
                            colorscale = [edge_startcolor, edge_endcolor],
                            width=4,
                            colorbar=dict(thickness=20, title= "edges", xanchor = "left")
             ) ,
            hoverinfo='text',
            text = edge_text
        ) #go
        ) # list
if not display_sync_score: 
    fig.add_trace(go.Scatter3d(
            name = f"Edges_{0}",
            x = x_edges[0 : 2],
            y = y_edges[0 : 2],
            z = z_edges[0 : 2],
            mode = 'lines',
            line = dict(width=4),
            hoverinfo='text',
            text = edge_text
        ) #go
        ) # list

for i in range(1,len(weights)):
    edge_text = f"sync score: {round(weights[i],4)}"
    color_idx_now = weights_transformed[i]
    color_now = color_list[color_idx_now]
    if display_sync_score: 
        fig.add_trace(go.Scatter3d(
            name = f"Edges_{i}",
            x = x_edges[3*i : 3*i + 2],
            y = y_edges[3*i : 3*i + 2],
            z = z_edges[3*i : 3*i + 2],
            mode = 'lines',
            line = dict(
                            cmin = lim_color_edge_low,
                            cmax = lim_color_edge_high,
                            color= color_now,
                            colorscale = [edge_startcolor, edge_endcolor],
                            width=4
             ) ,
            hoverinfo='text',
            text = edge_text
        ) #go
        ) # list
    if not display_sync_score: 
        fig.add_trace(go.Scatter3d(
            name = f"Edges_{i}",
            x = x_edges[3*i : 3*i + 2],
            y = y_edges[3*i : 3*i + 2],
            z = z_edges[3*i : 3*i + 2],
            mode = 'lines',
            line = dict(width=4),
            hoverinfo='text',
            text = edge_text
        ) #go
        ) # list


camera = dict(
    up = dict(x = camera_up[0], y = camera_up[1], z = camera_up[2]),
    center = dict(x = camera_center[0], y = camera_center[1], z = camera_center[2]),
    eye = dict(x = camera_eye[0], y = camera_eye[1], z = camera_eye[2])
)

fig.update_layout(scene_camera=camera)
if not display_axes:
    fig.update_layout(
        scene = dict(
            xaxis = dict(visible=False),
            yaxis = dict(visible=False),
            zaxis =dict(visible=False)
            )
            )

fig.write_html(pwd_save+"/networkfig.html")
fig.write_image(pwd_save+"networkfig.svg")