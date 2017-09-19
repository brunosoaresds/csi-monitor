function [ variance_slices, var_csi] = second_variance( csi_data, frequency )
    filtered_data = pca_filter(squeeze(abs(csi_data)));
    dec_sec_freq = floor(frequency/10);
    dec_seconds = floor(size(filtered_data, 2) / dec_sec_freq);
    
    filtered_data = filtered_data(:,1:dec_sec_freq*dec_seconds);
    
    maxvar_indexes = [];
    reshaped_data = [];
    for i=1:size(filtered_data,1)
        s_data = reshape(filtered_data(i,:), dec_sec_freq, []).';
        std_data = std(s_data, 0, 2);
        reshaped_data(i,:,:) = s_data.';
        limiar = mean(std_data) + (std(std_data)*1);
        maxvar_sub_indexes = find(std_data > limiar);
        
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
    
    variance_slices = struct();
    variance_slices.slices_indexes = var_slices;
    data_indexes = [];
    for i=1:size(var_slices, 1)
        slice = var_slices(i,:);
        slice_indexes = slice(1,1):slice(1,2);
        indexes_size = size(slice_indexes, 2);
        slice_data = reshape(reshaped_data(:, :, slice_indexes), 56, ...
            dec_sec_freq*indexes_size);
        variance_slices = setfield(variance_slices, ...
            strcat('slice_', num2str(i)), slice_data);
        
        data_indexes = cat(2, data_indexes, slice_indexes);
    end
    
    otherwhise_indexes = setdiff(1:dec_seconds, data_indexes);
    reshaped_data(:, :, otherwhise_indexes) = zeros();
    
    var_csi = reshape(reshaped_data, 56, dec_sec_freq*dec_seconds);
end

