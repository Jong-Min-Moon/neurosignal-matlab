classdef networkAnalyzer < handle
    properties
       spikeTrains
       channels
       channelList
       nChannels
       distMat
       filepath
       pythonpath
       ChannelList
       positions
       syncScores
       nConnects
       thres
    end
    
    methods
        function na = networkAnalyzer(filepath, pythonpath)
            na.filepath = filepath;
            na.pythonpath = pythonpath;

            terminate(pyenv);
            pyenv('Version', pythonpath);
            pyenv("ExecutionMode","OutOfProcess")

        end
        
        
        function addChannels(na, reader)
            na.channels = reader.readManyChannelsFromFile(1, 1);
            na.channelList = reader.channelList;
            na.positions = zeros([length(na.channelList),4]);
            na.positions(:,1) = 1:length(na.channelList) %1st column: 
            na.positions(:,2) = na.channelList %2nd column: channel number 
        end


        
        function setChannelPosition2d(na, channelNum, xpos, ypos)
            idx = find( na.positions(:,2) == channelNum);
            na.positions(idx, 3) = xpos;
            na.positions(idx, 4) = ypos;
        end

        function setChannelPosition3d(na, channelNum, xpos, ypos, zpos)
            idx = find( na.positions(:,2) == channelNum);
            na.positions(idx, 3) = xpos;
            na.positions(idx, 4) = ypos;
            na.positions(idx, 5) = zpos;
        end

        function bandPass(na, bandRange)
            for i = 1 : length(na.channelList)
                channelNum = na.channelList(i);
                channel = na.channels(channelNum);
                channel.bandPass(bandRange);
            end
        end 
        
        function detectSpikes(na, thres, preTime, postTime)
            % add한 모든 채널에서 spike detection 수행
            for i = 1 : length(na.channelList)
                channelNum = na.channelList(i);
                channel = na.channels(channelNum);
                channel.detectSpikes(thres, preTime, postTime);
            end
        end
        
        function dist = spikeDist(na, thres)
            na.thres = thres
            pyrun("import numpy as np");
            pyrun("import pandas as pd");
            pyrun("import pyspike");

            % calculate and save entries of score matrix in python.
            % We just fetch each entry into matlab.
            pyrun("score_matrix = np.zeros((int(nChannels), int(nChannels)))", nChannels = length(na.channelList));
            na.nChannels = length(na.channelList);
            dist = zeros(na.nChannels);
            for i = 1 : na.nChannels
                for j = i+1 : na.nChannels
                    channel_1 = na.channels(na.channelList(i));
                    channel_2 = na.channels(na.channelList(j));
                    nTimestamps = channel_1.nTimestamps;
                        
                    if channel_1.nSpikes  <= 1
                        dist(i,j) = NaN;
                        dist(j,i) = NaN;
                        pyrun("score_matrix[int(i)-1, int(j)-1] = np.NaN", i=i, j=j );
                        pyrun("score_matrix[int(j)-1, int(i)-1] = np.NaN", i=i, j=j );
                    elseif channel_2.nSpikes <= 1
                        dist(i,j) = NaN;
                        dist(j,i) = NaN;
                        pyrun("score_matrix[int(i)-1, int(j)-1] = np.NaN", i=i, j=j );
                        pyrun("score_matrix[int(j)-1, int(i)-1] = np.NaN", i=i, j=j );
                    else
                        train_1 = channel_1.spikeTimestamps;
                        train_2 = channel_2.spikeTimestamps;
                        
                   
                        
                        pyrun("train_1 = np.array(matlab_array_1)", matlab_array_1 = train_1);
                        pyrun("train_2 = np.array(matlab_array_2)", matlab_array_2 = train_2);                   
                        pyrun("train_1 = pyspike.SpikeTrain(train_1, [0, a])", a = nTimestamps);
                        pyrun("train_2 = pyspike.SpikeTrain(train_2, [0, a])", a = nTimestamps);
                        
                        pyrun("score_matrix[int(i)-1, int(j)-1] = pyspike.spike_sync(train_1,train_2)", i=i, j=j );
                        pyrun("score_matrix[int(j)-1, int(i)-1] = score_matrix[int(i)-1, int(j)-1]", i=i, j=j );

    
                        dist(i,j) = pyrun("d = score_matrix[int(i)-1, int(j)-1]", "d", i=i, j=j );
                        dist(j,i) = dist(i,j);
                    end
                    
            
                end
            end
            
            filepath_score_matrix = na.filepath + "/score_matrix.npy"
            pyrun("np.save(path, score_matrix)", path = filepath_score_matrix);
            
            
            % 
            filepath_positions = na.filepath + "/positions.pkl"
            pyrun("positions = np.array(positions_matlab)", positions_matlab = na.positions);
            pyrun("positions_index = positions[:,0].astype(np.int64)");
            pyrun("positions = pd.DataFrame(positions[:,1:])");
            pyrun("positions.index = positions_index");
            pyrun("positions.to_pickle(path)", path = filepath_positions);
            
            heatmap(dist, 'Colormap', cool);
            na.distMat = dist;
            na.syncScores = array2table( ...
                dist, 'VariableNames',cellstr("node" + (1:na.nChannels)), 'RowNames', cellstr("node" + (1:na.nChannels)))
  
            na.nConnects = array2table(nansum((dist>na.thres),2), 'VariableNames', {'number of connected'}, 'RowNames',cellstr("node" + (1:na.nChannels)));              
        end
        
        function louvain(na, basic_size, multiplier, colorscale_edge, colorscale_node, degree_lim, edge_lim, edge_colorbar_lim, community_colorbar_max, display_community_color, display_degree, display_sync_score)
            pyrun("import numpy as np");
            pyrun("import pandas as pd");
           
            %node size
            pyrun("node_sizes = np.array([int(basic_size), int(basic_size)])", basic_size = basic_size, multiplier = multiplier);
            filepath_node_sizes = na.filepath + "/node_sizes.npy";
            pyrun("np.save(path, node_sizes)", path = filepath_node_sizes);

            %color
            pyrun("colors = pd.Series([colorscale_edge, colorscale_node])", colorscale_edge = colorscale_edge, colorscale_node = colorscale_node);
            filepath_colors = na.filepath + "/colors.pkl";
            pyrun("colors.to_pickle(path)", path = filepath_colors);

            % lim and threshold
            pyrun("lims = pd.Series([degree_lim_low, degree_lim_high, edge_lim_low, edge_lim_high, thres, community_max, edge_color_lim_low, edge_color_lim_high])", degree_lim_low = degree_lim(1), degree_lim_high = degree_lim(2), edge_lim_low = edge_lim(1), edge_lim_high = edge_lim(2), thres=na.thres, community_max = community_colorbar_max, edge_color_lim_low = edge_colorbar_lim(1), edge_color_lim_high = edge_colorbar_lim(2));
            filepath_lims = na.filepath + "/lims.pkl";
            pyrun("lims.to_pickle(path)", path = filepath_lims);

            % display components or not
            pyrun("display_or_not = pd.Series([display_community_color, display_degree, display_sync_score])", display_community_color = display_community_color, display_degree = display_degree, display_sync_score = display_sync_score);
            filepath_display_or_not = na.filepath + "/display_or_not.pkl";
            pyrun("display_or_not.to_pickle(path)", path = filepath_display_or_not);

            command = na.pythonpath + " " + na.filepath + "/drawnx.py";
            system(command)
        end



        
    
            
            
       
    end % methods
end %class
