function [ final_data ] = wifi_id_silence_removal( csi_stream, packets_per_second )
    csi_amplitude = abs(csi_stream);
    filtered_data = butter_filter(csi_amplitude);
    short_time_p_size = floor(0.05 * packets_per_second);
    n_partitions = floor(size(filtered_data,2)/short_time_p_size);
    latest_data = n_partitions*short_time_p_size;
    
    s_data = reshape(filtered_data(1,1:latest_data), short_time_p_size, []).';
    for i=1:size(s_data,1)
        frame = s_data(i,:);
        E(1,i) = mean(abs(frame.^2));
    end
    
    E = log(medfilt1(E));
    plot(E);
    eMean = mean(E);
    
    S{1,1} = 0;
    latest_index = -1;
    for i=1:size(E,2)
        if E(1,i) > eMean
            if i-1 == latest_index
                S{1,end}(1,end+1) = i;
            else
                S{1,end+1} = i;
            end
            latest_index = i;
        end
    end
    S = S(1,2:end);
    
    frames_size = cellfun(@(x)size(x,2), S);
    max_frame = find(frames_size==max(frames_size));
    
    central_frame = S{1, max_frame(1,1)};
    initial = central_frame(1,1)*short_time_p_size;
    final = central_frame(1,end)*short_time_p_size;
    
    final_data = csi_stream(:,initial:final);
end

