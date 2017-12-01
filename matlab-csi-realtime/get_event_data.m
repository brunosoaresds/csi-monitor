function [ events, var_csi ] = get_event_data( csi_data, frequency )
    csi_mag = abs(csi_data);
    nons_csi = (csi_mag - mean(csi_mag, 2)).';
    coeff = pca(nons_csi);
    % We monitor only the second pca comp;
    monitoring_comp = (nons_csi*coeff(:,2)).';
    
    % Calcule quantity of 100ms frames and adjust data to be at the right
    % size of qtt_of_frames*frequency/10.
    dec_sec_freq = floor(frequency/10);
    frames_per_dec_sec = floor(size(monitoring_comp, 2) / dec_sec_freq);
    monitoring_comp = monitoring_comp(1,1:dec_sec_freq*frames_per_dec_sec);
    
    % Creates de 100ms frames vectors
    frames_data = reshape(monitoring_comp, dec_sec_freq, []).';
    
    % Find 100ms frames that have std > limiar (mean+std);
    std_data = std(frames_data, 0, 2);
    limiar = mean(std_data) + std(std_data);
    event_dec_indexes = find(std_data > limiar);

    % Defines the maximum 100ms shift of perturbation to consider the same
    % event
    max_shift = 10;
    % Defines the events slices
    var_slices = [];
    slice_num = 0;
    last_num = -1;
    start_num = 0;
    for i=1:size(event_dec_indexes,1)
        event_index = event_dec_indexes(i,1);
        if(last_num+max_shift < event_index)
            if(start_num ~= 0)
                slice_num = slice_num + 1;
                var_slices(slice_num,:) = [start_num last_num];
            end
            start_num = event_index;
        end
        last_num = event_index;
        if(event_index == event_dec_indexes(end,1))
            slice_num = slice_num + 1;
            var_slices(slice_num,:) = [start_num last_num];
        end
    end
    
    % Construct variance slices based on time
    variance_slices = struct();
    data_indexes = [];
    vs_si = [];
    slice_i = 0;
    for i=1:size(var_slices, 1)
        slice = var_slices(i,:);
        slice_indexes = slice(1,1):slice(1,2);
        
        if(size(slice_indexes, 2) < 4)
            continue;
        end
        
        % Find the 100ms where we have the max perturbation
        slice_energy = frames_data(slice_indexes,:);
        mean_energy = mean(slice_energy,2);
        max_event = find(mean_energy==max(mean_energy));
        max_event = slice_indexes(1,max_event(1,1));
        
        % Defines the event range at the 4 seconds around the center of
        % perturbation (can be calibrated...)
        size_range = 20;
        slice_init = max_event - size_range;
        if slice_init < 1
            slice_init = 1;
        end
        slice_end = max_event + (size_range-1);
        if slice_end > size(frames_data, 1)
            slice_end = size(frames_data, 1);
        end
        
        slice_indexes = slice_init:slice_end;
        if(size(slice_indexes, 2) ~= size_range*2)
            continue;
        end
        
        slice_i = slice_i + 1;
        % Save complex data
        complex_indexes = (((slice_init-1)*dec_sec_freq)+1):slice_end*dec_sec_freq;
        vs_si(slice_i,:) = complex_indexes;
        complex_data = csi_data(:, complex_indexes);
        variance_slices = setfield(variance_slices, ...
            strcat('slice_complex_', num2str(slice_i)), complex_data);
        
        % Save component data
        slice_data = reshape(frames_data(slice_indexes,:).', 1, []);
        variance_slices = setfield(variance_slices, ...
            strcat('slice_', num2str(slice_i)), slice_data);
        
        data_indexes = cat(2, data_indexes, slice_indexes);
    end
    
    variance_slices.slices_indexes = vs_si;
    
    otherwhise_indexes = setdiff(1:frames_per_dec_sec, data_indexes);
    frames_data(otherwhise_indexes, :) = zeros();
    
    events = variance_slices;
    var_csi = reshape(frames_data.', 1, []);
end

