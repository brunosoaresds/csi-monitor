function [ variance_slices, var_csi] = second_variance( csi_data, frequency )
    filtered_data = pca_filter(squeeze(abs(csi_data)));
    dec_sec_freq = floor(frequency/10);
    dec_seconds = floor(size(filtered_data, 2) / dec_sec_freq);
    
    filtered_data = filtered_data(:,1:dec_sec_freq*dec_seconds);
    
    maxvar_indexes = [];
    reshaped_data = [];
    maxvar_indexes_stds = struct();
    for i=1:size(filtered_data,1)
        s_data = reshape(filtered_data(i,:), dec_sec_freq, []).';
        std_data = std(s_data, 0, 2);
        reshaped_data(i,:,:) = s_data.';
        limiar = mean(std_data) + (std(std_data)*1);
        maxvar_sub_indexes = find(std_data > limiar);
        
        % Save stds
        for stdi=1:size(maxvar_sub_indexes)
            index = maxvar_sub_indexes(stdi,1);
            value = std_data(index, 1);
            field_name = strcat('i_', num2str(index));
            if isfield(maxvar_indexes_stds, field_name)
                old_stored = getfield(maxvar_indexes_stds, field_name);
            else
                old_stored = [];
            end
            
            new_stored = cat(1, old_stored, value);
            maxvar_indexes_stds = setfield(maxvar_indexes_stds, ...
                field_name, new_stored);
        end
        
        % Checks if in other subcarrier that index is not present
        if size(maxvar_indexes, 2) == 0
           maxvar_indexes = maxvar_sub_indexes;
        else
            members = ismember(maxvar_indexes, maxvar_sub_indexes);
            remove_indexes = maxvar_indexes(find(members == 0));
            maxvar_indexes = setdiff(maxvar_indexes, remove_indexes);
        end
    end
        
    var_slices = [];
    slice_num = 0;
    last_num = -1;
    start_num = 0;
    difference_between = 10;
    for i=1:size(maxvar_indexes, 1)
        actual_num = maxvar_indexes(i);
        if(last_num+difference_between < actual_num)
            if(start_num ~= 0)
                slice_num = slice_num + 1;
                var_slices(slice_num,:) = [start_num last_num];
            end
            start_num = actual_num;
        end
        last_num = actual_num;
        if(i == size(maxvar_indexes, 1))
            slice_num = slice_num + 1;
            var_slices(slice_num,:) = [start_num last_num];
        end
    end
    
    % Construct variance slices based on time
    variance_slices = struct();
    data_indexes = [];
    vs_si = [];
    for i=1:size(var_slices, 1)
        slice = var_slices(i,:);
        slice_indexes = slice(1,1):slice(1,2);
        indexes_size = size(slice_indexes, 2);
        
        % Gets the center of pertubation slice
        center_index = 0;
        center_mean = 0;
        for j=1:indexes_size
            actual_si = slice_indexes(1,j);
            field_name = strcat('i_', num2str(actual_si));
            if isfield(maxvar_indexes_stds, field_name)
                stored = getfield(maxvar_indexes_stds, field_name);
            else
                stored = [];
            end
            
            actual_mean = mean(stored);
            if actual_mean > center_mean
                center_mean = actual_mean;
                center_index = actual_si;
            end
        end
        
        size_range = 20;
        slice_init = center_index - size_range;
        if slice_init < 1
            slice_init = 1;
        end
        slice_end = center_index + size_range;
        if slice_end < 1
            slice_end = 1;
        end
        vs_si(i,:) = [slice_init slice_end];
        slice_indexes = slice_init:slice_end;
        indexes_size = size(slice_indexes, 2);
        
        slice_data = reshape(reshaped_data(:, :, slice_indexes), 56, ...
            dec_sec_freq*indexes_size);
        variance_slices = setfield(variance_slices, ...
            strcat('slice_', num2str(i)), slice_data);
        
        data_indexes = cat(2, data_indexes, slice_indexes);
    end
    
    variance_slices.slices_indexes = vs_si;
    
    otherwhise_indexes = setdiff(1:dec_seconds, data_indexes);
    reshaped_data(:, :, otherwhise_indexes) = zeros();
    
    var_csi = reshape(reshaped_data, 56, dec_sec_freq*dec_seconds);
end

