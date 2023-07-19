classdef setterPosition < handle
    properties
    end

    methods
    function sp = setter_position()
    end

    function position_array_new = setChannelPosition3d(sp, position_array, channelNum, xpos, ypos, zpos)
     position_array_new = position_array(:,:);
            idx = find( position_array(:,2) == channelNum);
            position_array_new(idx, 3) = xpos;
            position_array_new(idx, 4) = ypos;
            position_array_new(idx, 5) = zpos;
            fprintf("set channel %d's position as (%f, %f, %f)\n", ...
                channelNum, ...
                position_array_new(idx, 3), ...
                position_array_new(idx, 4), ...
                position_array_new(idx, 5))
    end % end of function setChannelPosition3d

    function position_array_new = setChannelPosition3dArray(sp, position_array, position_input_array)
    position_array_new = position_array(:,:);
    n_channel = size(position_array_new);
    n_channel = n_channel(1);
    channelNum_array = position_array_new(:,2);
    for ii = 1 : n_channel
        channelNum = channelNum_array(ii);
        position_array_new = sp.setChannelPosition3d( ...
            position_array_new, channelNum, ...
            position_input_array(ii,1), ...
            position_input_array(ii,2), ...
            position_input_array(ii,3));
    end 
    end
    end % end of methods   
end % end of class