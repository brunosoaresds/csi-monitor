datasets_struct = {{'csi_data_bruno_w_', [1 76], 1} ...
    {'csi_data_geovana_w_', [1 15], 2} ...
    {'csi_data_vinicius_w_', [1 30], 3} ...
    {'csi_data_phelipe_w_', [1 15], 4} ...
    {'csi_data_josenilton_w_', [1 20], 5} ...
    {'csi_data_luan_w_', [1 20], 6}  ...
    {'csi_data_pablo_w_', [1 20], 7} ...
    {'csi_data_marcelo_w_', [1 68], 8}};

[datasets, labels_indexes] = mount_datasets(datasets_struct);

datasets_len = size(datasets,2);
if(exist('datasets_events_indexes') == 0)
    datasets_events_indexes = {};
    for i=1:datasets_len
        if(exist(datasets{1,i}) == 0) 
            splited_var = strsplit(datasets{1,i}, '_');
            fileName = strcat('/home/bruno/gait_bruno_tests/gait_tests_', splited_var(1,3), '_dataset.mat');
            load(fileName{:});
        end
        dataset = eval(datasets{1,i});
        clear(datasets{1,i});
        events_intervals = extract_event_intervals(dataset, 800);
        datasets_events_indexes{1,i} = events_intervals;
    end
end

% Validate event indexes
enable_plot = 0;
for i=1:datasets_len
    events_indexes = datasets_events_indexes{1,i};
    if length(events_indexes) ~= 3
        disp(strcat('Wrong event length: ', datasets{1,i}, ' - ', num2str(length(events_indexes)), ' - ', num2str(i)));
    end
    
    if enable_plot == 1
        if(exist(datasets{1,i}) == 0) 
            splited_var = strsplit(datasets{1,i}, '_');
            fileName = strcat('/home/bruno/gait_bruno_tests/gait_tests_', splited_var(1,3), '_dataset.mat');
            load(fileName{:});
        end

        dataset = eval(datasets{1,i});
        clear(datasets{1,i});
        pca_filtered = filter_csi_with_pca(dataset.', 2, 1);
        pca_2nth = pca_filtered(:,2);
        pca_mean = mean(pca_2nth);
        figure;
        plot(pca_2nth);
        hold on;
        
        non_event = events_indexes{1,3};
        non_event_sig = pca_2nth;
        non_event_sig(setdiff(1:length(pca_2nth), non_event(1,1):non_event(1,2)), :) = pca_mean;
        plot(non_event_sig);
        
        all_event_indexes = [];
        for j=1:(length(events_indexes)-1)
            event_indexes = events_indexes{1,j};
            all_event_indexes = cat(2, all_event_indexes, event_indexes(1,1):event_indexes(1,2));
        end
        all_event_indexes = sort(all_event_indexes);
        pca_2nth(setdiff(1:length(pca_2nth), all_event_indexes), :) = pca_mean;
        plot(pca_2nth);
        
        hold off;
    end
end

enable_non_e_gen = 0;
enable_plot = 0;
if enable_non_e_gen==1
    for i=1:datasets_len
        events_indexes = datasets_events_indexes{1,i};
        
        if(exist(datasets{1,i}) == 0) 
            splited_var = strsplit(datasets{1,i}, '_');
            fileName = strcat('/home/bruno/gait_bruno_tests/gait_tests_', ...
                splited_var(1,3), '_dataset.mat');
            load(fileName{:});
        end

        dataset = eval(datasets{1,i});
        clear(datasets{1,i});
        pca_filtered = filter_csi_with_pca(dataset.', 2, 1);
        disp(size(pca_filtered));
        pca_2nth = pca_filtered(:,2);
        pca_mean = mean(pca_2nth);
        
        if enable_plot == 1
            figure;
            plot(pca_2nth);
            hold on;
        end

        all_event_indexes = [];
        for j=1:length(events_indexes)
            event_indexes = events_indexes{1,j};
            all_event_indexes = cat(2, all_event_indexes, ...
                event_indexes(1,1):event_indexes(1,2));
        end
        all_event_indexes = sort(all_event_indexes);
        non_event_indexes = setdiff(1:length(pca_2nth), all_event_indexes);
        event_signal = pca_2nth;
        event_signal(non_event_indexes, :) = pca_mean;
        
        if enable_plot == 1
            plot(event_signal);
        end

        % Search in the non_event_signals, a continuous period of 4s
        in_out_e_len = length(event_indexes(1,1):event_indexes(1,2));
        id = [false, diff(non_event_indexes)==1, false];
        start_indexes=strfind(id,[0 1]);
        end_indexes=strfind(id,[ 1 0]);
        non_events_intervals = {};
        for nei=1:length(start_indexes)
            non_event = start_indexes(1,nei):end_indexes(1,nei);
            non_e_len = length(non_event);
            if non_e_len >= in_out_e_len
                random_start = ceil(rand*(non_e_len-in_out_e_len+1));
                random_end = random_start + in_out_e_len - 1;
                non_events_intervals = [non_events_intervals ...
                    non_event_indexes(1, non_event(1, random_start:random_end))];
            end
        end

        choosen_non_ei = ceil(rand*length(non_events_intervals));
        choosen_non_ei = non_events_intervals{1, choosen_non_ei};
        non_event_signal = pca_2nth;
        other_indexes = setdiff(1:length(pca_2nth), choosen_non_ei);
        non_event_signal(other_indexes, :) = pca_mean;
        
        events_indexes{1,3} = [choosen_non_ei(1,1) choosen_non_ei(1,end)];
        datasets_events_indexes{1,i} = events_indexes;
        
        if enable_plot == 1
            plot(non_event_signal);
            hold off;
        end
    end
end

clear datasets_len dataset fileName splited_var all_event_indexes event_indexes events_indexes ...
    events_intervals i j pca_2nth pca_mean pca_filtered plot

function [datasets, labels_indexes] = mount_datasets(datasets_struct)
    datasets = {};
    labels_indexes = [];
    for i=1:length(datasets_struct)
        x = datasets_struct{1,i};
        pattern = x{1,1};
        indexes = x{1,2};
        for j=indexes(1,1):indexes(1,2)
            datasets = [datasets strcat(pattern, num2str(j))];
            labels_indexes(end+1,1) = x{1,3};
        end
    end
end