classdef networkAnalyzer < handle
    properties
       positionSetter

       spikeTrains
       channels
       channelList
       nChannels
       distMat

       filepath
       pyfilepath
       pythonpath
       savepath
       
       ChannelList
       positions
       syncScores
       nConnects
       thres
       is_spike_detected
       louvain_n_groups
       louvain_count_groups
    end
    
    methods
        function na = networkAnalyzer(filepath, pythonpath, savepath)
            na.positionSetter = setterPosition();

            na.pyfilepath = filepath;
            na.filepath = na.pyfilepath + "/pkls";
            na.pythonpath = pythonpath;
            na.savepath = savepath;
            na.is_spike_detected = false;

            terminate(pyenv);
            pyenv('Version', pythonpath);
            pyenv("ExecutionMode","OutOfProcess")
            
            pyrun("import numpy as np");
            pyrun("import pandas as pd");
            pyrun("import pyspike");

        end
        
        
        function addChannels(na, reader)
            fprintf("Deleted previous data\n")
            na.channels = reader.readManyChannelsFromFile(1, 1);
            na.channelList = reader.channelList;
            na.positions = zeros([length(na.channelList),4]);
            na.positions(:,1) = 1:length(na.channelList); %1st column: 
            na.positions(:,2) = na.channelList; %2nd column: channel number 
        end


        function deleteChannel(na, channelNumArray)
            for channelNum = channelNumArray
                fprintf("Deleted channal %d\n", channelNum)

                % delete from channelList
                idx_channelList = find(na.channelList == channelNum);
                na.channelList(idx_channelList) = [];
                
                % delete from channels
                na.channels(channelNum) = [];
               % remove(na.channels, channelNum);
    
                % delet from positions
                idx_positions = find( na.positions(:,2) == channelNum);
                na.positions(idx_positions,:) = [];
                fprintf("%d channels left\n", length(na.channelList))
            end
        end
        

        %%%% positions 
        function setChannelPosition3d(na, channelNum, xpos, ypos, zpos)
            na.positions = na.positionSetter.setChannelPosition3d( ...
                na.positions, ...
                channelNum, xpos, ypos, zpos);
        end

        function setChannelPosition3dArray(na, positions_input_array)
            na.positions = na.positionSetter.setChannelPosition3dArray( ...
                na.positions, ...
                positions_input_array);
        end
        %%%% end of positions

        
        function bandPass(na, bandRange)
            for i = 1 : length(na.channelList)
                % pick a channel object
                channelNum = na.channelList(i);
                channel = na.channels(channelNum);
                
                % do the job
                channel.bandPass(bandRange);
            end
        end 
        
        function n_spike_table = detectSpikes(na, thres, preTime, postTime)
            % add한 모든 채널에서 spike detection 수행
            nspike_array = [];
            for i = 1 : length(na.channelList)
                % pick a channel object
                channelNum = na.channelList(i);
                channel = na.channels(channelNum);

                % do the job
                fprintf("channel %d ", channelNum)
                nspike_array(i) = channel.detectSpikes(thres, preTime, postTime);
            end
            n_spike_table = array2table( ...
                nspike_array', ...
                'VariableNames', cellstr("n_spike"), ...
                'RowNames', cellstr("node" + na.channelList));
            na.is_spike_detected = true;

                

        end

        function average_amp_table = getMeanSpikeAmplitude(na, range_start, range_end, isRaw)
            % add한 모든 채널에서 계산 수행
            average_amp_array = [];
            for i = 1 : length(na.channelList)
                % pick a channel object
                channelNum = na.channelList(i);
                channel = na.channels(channelNum);

                % do the job
                %fprintf("channel %d ", channelNum)
                [average_amp, ] = channel.getMeanSpikeAmplitude(range_start, range_end, isRaw);
                average_amp_array(i) = average_amp;
            end % end of for
            average_amp_table = array2table( ...
                average_amp_array', ...
                'VariableNames', cellstr("average_amp"), ...
                'RowNames', cellstr("node" + na.channelList));
        end % end of function
        
        function init_score_mat(na)

        end
        
        function py_spikeIntoDist(na, train_1, train_2, nTimestamps)
            % turn spikes into SpikeTrain objects in Python
            pyrun("train_1 = np.array(matlab_array_1)", matlab_array_1 = train_1);
            pyrun("train_2 = np.array(matlab_array_2)", matlab_array_2 = train_2);                   
            pyrun("train_1 = pyspike.SpikeTrain(train_1, [0, a])", a = nTimestamps);
            pyrun("train_2 = pyspike.SpikeTrain(train_2, [0, a])", a = nTimestamps);
            pyrun("dist_now = pyspike.spike_sync(train_1,train_2)");
        end

        function dist = spikeDist(na, thres, is_normalize, n_simul)
            dist = zeros(na.nChannels);

            if na.is_spike_detected == false
                fprintf("run detectSpikes first")
                return
            end

               
            na.thres = thres;
            
            %initialize score matrix
            na.nChannels = length(na.channelList);
            pyrun("score_matrix = np.zeros((int(nChannels), int(nChannels)))", nChannels = na.nChannels );            

            % calculate and save entries of score matrix in python.
            % We just fetch each entry into matlab.
            for i = 1 : na.nChannels
                fprintf("calculating sync score between %ith and other channels...\n", i)
                for j = i+1 : na.nChannels
                    % pick two channel objects
                    channel_1 = na.channels(na.channelList(i));
                    channel_2 = na.channels(na.channelList(j));

                    % do the job
                    nTimestamps = channel_1.nTimestamps;
                    if channel_1.nSpikes <= 1
                        % edge case 1
                        dist(i,j) = NaN;
                        pyrun("score_matrix[int(i)-1, int(j)-1] = np.NaN", i=i, j=j );
                    elseif channel_2.nSpikes <= 1
                        % edge case 2
                        dist(i,j) = NaN;
                        pyrun("score_matrix[int(i)-1, int(j)-1] = np.NaN", i=i, j=j );
                    else
                        % main calculation
                        nSpikes_1 = channel_1.nSpikes;
                        nSpikes_2 = channel_2.nSpikes;
                        
                        %this produces a python variable "dist_now"
                        na.py_spikeIntoDist( ...
                            channel_1.spikeTimestamps, ...
                            channel_2.spikeTimestamps, ...
                            nTimestamps)
                         
                        %% normalizing
                        if ~ is_normalize
                            pyrun("entry_value = dist_now")
                        else
                            pyrun("rng_generator = np.random.default_rng()")
                            pyrun("normalized_score_save = np.empty(1000)")
                            pyrun("normalized_score_save[:] = np.nan")
                            
                            for k = 1:n_simul
                                
                                
                                % generate two random spike trains and obtain a random sync score
                                    % random spike train 1
                                pyrun("random_train_1 = np.sort(" + ...
                                    "rng_generator.choice(int(nTimestamps), " + ...
                                    "size = int(nSpikes_1)," + ...
                                    "replace=False" + ...
                                    ")" + ...
                                    ")" , ...
                                    nTimestamps = nTimestamps, ...
                                    nSpikes_1 = nSpikes_1);  
                                pyrun("random_train_1 = pyspike.SpikeTrain(random_train_1, [0, a])", ...
                                    a = nTimestamps);
    
                                    % random spike train 2
                                pyrun("random_train_2 = np.sort(" + ...
                                    "rng_generator.choice(int(nTimestamps)," + ...
                                    "size = int(nSpikes_2)," + ...
                                    "replace=False" + ...
                                    ")" + ...
                                    ") ",nTimestamps = nTimestamps, nSpikes_2 = nSpikes_2);
                                pyrun("random_train_2 = pyspike.SpikeTrain(random_train_2, [0, a])", ...
                                    a = nTimestamps);
                            
                                    % calculate the sync score
                                pyrun("normalizer_now = pyspike.spike_sync(random_train_1,random_train_2)");                 
                                pyrun("normalized_score_save[int( py_list_idx )] = dist_now - normalizer_now", ...
                                    py_list_idx = k - 1);
                            end % end of 1000 random draws (k loop)
                            
                            % normalize
                            pyrun("entry_value = max(0, normalized_score_save.mean())");
                        end % if is_normalize
                        %% save 
                            % savein ij-th entry
                        pyrun("score_matrix[int(i)-1, int(j)-1] = entry_value", i=i, j=j ); % save into python numpy array
                        dist(i,j) = pyrun("d = score_matrix[int(i)-1, int(j)-1]", "d", i=i, j=j );
                            
                        % symmetric matrix
                        pyrun("score_matrix[int(j)-1, int(i)-1] = score_matrix[int(i)-1, int(j)-1]", i=i, j=j );       
                        dist(j,i) = dist(i,j);
                    end %
                end % end of i-th loop
            end % end of j-th loop            
            
            %% save information as files
                % score matrix
            filepath_score_matrix = na.filepath + "/score_matrix.npy"
            pyrun("np.save(path, score_matrix)", path = filepath_score_matrix);
            
                % positions of channels
            filepath_positions = na.filepath + "/positions.pkl"
            pyrun("positions = np.array(positions_matlab)", positions_matlab = na.positions);
            pyrun("positions_index = positions[:,0].astype(np.int64)");
            pyrun("positions = pd.DataFrame(positions[:,1:])");
            pyrun("positions.index = positions_index");
            pyrun("positions.to_pickle(path)", path = filepath_positions);
            
                % sync score heatmap
            heatmap(dist, 'Colormap', cool);
            na.distMat = dist;

                % sync score table
            na.syncScores = array2table( ...
                dist, ...
                'VariableNames', cellstr("node" + (1:na.nChannels)), ...
                'RowNames', cellstr("node" + (1:na.nChannels)));
  
                % degree table
            na.nConnects = array2table( ...
                nansum((dist>na.thres),2), ...
                'VariableNames', {'number of connected'}, ...
                'RowNames',cellstr("node" + (1:na.nChannels)));              
        end
        


        function louvain_prelim(na)
            pyrun("import numpy as np");
            pyrun("import pandas as pd");
           
           
            % threshold
            pyrun("thres_value = pd.Series([thres])", thres=na.thres);
            filepath_thres = na.filepath + "/thres.pkl";
            pyrun("thres_value.to_pickle(path)", path = filepath_thres);
    
            command = na.pythonpath + " " + na.pyfilepath + "/drawnx_prelim.py";
            system(command)
        end

        function get_n_groups(na)
            prelim_n_partition_path = na.filepath + "/prelim_n_partition.npy";
            na.louvain_n_groups = int64(py.numpy.load(prelim_n_partition_path));

            prelim_count_partition_path = na.filepath + "/prelim_count_partition.npy";
            na.louvain_count_groups = int64(py.numpy.load(prelim_count_partition_path));
        end

        function n_group = get_group_info(na)
            na.louvain_prelim();
            pause(7);
            na.get_n_groups;
            n_group = na.louvain_n_groups;
            fprintf("number of groups: %i\n", na.louvain_n_groups);
            fprintf("number of channels per group:\n");
            fprintf("   group / number of channels")
            na.louvain_count_groups
        end

        function louvain(na, ...
                basic_size, multiplier, ...
                edge_startcolor, edge_endcolor, color_list_node, ...
                degree_lim, edge_lim, ...
                edge_colorbar_lim, ...
                display_community_color, display_degree, display_sync_score, display_axes, ...
                camera_up, camera_center, camera_eye)
            pyrun("import numpy as np");
            pyrun("import pandas as pd");
           
            %node size
            pyrun("node_sizes = np.array([int(basic_size), int(basic_size)])", basic_size = basic_size, multiplier = multiplier);
            filepath_node_sizes = na.filepath + "/node_sizes.npy";
            pyrun("np.save(path, node_sizes)", path = filepath_node_sizes);

            %edge colorbar
            pyrun("colors = pd.Series([edge_startcolor, edge_endcolor])", edge_startcolor = edge_startcolor, edge_endcolor = edge_endcolor);
            filepath_colors = na.filepath + "/colors.pkl";
            pyrun("colors.to_pickle(path)", path = filepath_colors);
            
            %node colors
            pyrun("colors_node = pd.Series(color_list_node)", color_list_node = color_list_node);
            filepath_colors_node = na.filepath + "/colors_node.pkl";
            pyrun("colors_node.to_pickle(path)", path = filepath_colors_node);

            % lim
            pyrun("lims = pd.Series(" + ...
                "[" + ...
                "degree_lim_low," + ...
                "degree_lim_high," + ...
                "edge_lim_low," + ...
                "edge_lim_high," + ...
                "edge_color_lim_low," + ...
                "edge_color_lim_high" + ...
                "]" + ...
                ")", ...
                degree_lim_low = degree_lim(1), ...
                degree_lim_high = degree_lim(2), ...
                edge_lim_low = edge_lim(1), ...
                edge_lim_high = edge_lim(2), ...
                edge_color_lim_low = edge_colorbar_lim(1), ...
                edge_color_lim_high = edge_colorbar_lim(2) ...
                );
            filepath_lims = na.filepath + "/lims.pkl";
            pyrun("lims.to_pickle(path)", path = filepath_lims);

            % threshold
            pyrun("thres_value = pd.Series([thres])", thres=na.thres);
            filepath_thres = na.filepath + "/thres.pkl";
            pyrun("thres_value.to_pickle(path)", path = filepath_thres);

            % display components or not
            pyrun("display_or_not = pd.Series([display_community_color, display_degree, display_sync_score, display_axes])", display_community_color = display_community_color, display_degree = display_degree, display_sync_score = display_sync_score, display_axes = display_axes);
            filepath_display_or_not = na.filepath + "/display_or_not.pkl";
            pyrun("display_or_not.to_pickle(path)", path = filepath_display_or_not);


            % camera = 
            pyrun("camera = np.array([up_x, up_y, up_z, center_x, center_y, center_z, eye_x, eye_y, eye_z])", up_x = camera_up(1), up_y  = camera_up(2), up_z = camera_up(3), center_x = camera_center(1), center_y = camera_center(2), center_z = camera_center(3), eye_x = camera_eye(1), eye_y = camera_eye(2), eye_z = camera_eye(3));
            filepath_camera = na.filepath + "/camera.npy";
            pyrun("np.save(path, camera)", path = filepath_camera); 

            % graph save path
            pyrun("pwd_save = pd.Series([savepath])", savepath = na.savepath);
            filepath_savepath = na.filepath + "/savepath.pkl";
            pyrun("pwd_save.to_pickle(path)", path = filepath_savepath);

            command = na.pythonpath + " " + na.pyfilepath + "/drawnx.py";
            system(command)
        end
        
    
            
            
       
    end % methods
end %class
