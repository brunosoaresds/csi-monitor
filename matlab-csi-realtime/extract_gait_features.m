function [ all_features, energy_signatures, time_slice_features, ...
    spectrogram_data, event_pca ] = extract_gait_features( csi_data, frequency )

    csi_mag = abs(csi_data);
    nons_csi = (csi_mag - mean(csi_mag, 2)).';
    coeff= pca(nons_csi);
    pca_comps = nons_csi*coeff(:,1:20);
    
    % Create the spectrogram
    [ newS, f, t, cutoff20, cutoff50, cutoff100 ] = stft_spectrogram(csi_data, frequency);
    %[ newS, f, t, cutoff20, cutoff50, cutoff100 ] = wavelet_spectrogram(csi_data, frequency);
    
    frame_time = (t(1,3) - t(1,2));
    min_walk_frame_size = ceil(1.2/frame_time);
    window_size = frame_time * frequency;
    
    % Calcule percentile
    percentile = [];
    for j=1:size(newS, 2)
        chunk_energy = sum(newS(:,j));
        for i=1:size(newS, 1)
            percentile(i,j) = sum(newS(1:i,j))/chunk_energy;
        end
    end
    percentile(isnan(percentile)) = 0;

    % Find percentile curves with 50% and 95%
    speed_curves(1:2, 1:size(percentile,2)) = 0;
    event_len = 0;
    events = {};
    events_indexes = {};
    
    % Normalize Body energies between 0 and 1
    bodyMoveEnergies = newS(cutoff20:cutoff100, :);
    energyIndexes = find(bodyMoveEnergies > 0);
    allEnergies = bodyMoveEnergies(energyIndexes);
    maxEnergy = max(allEnergies);
    minEnergy = min(allEnergies);
    normEnergyVal = (allEnergies-minEnergy)/(maxEnergy-minEnergy);
    bodyMoveEnergies(energyIndexes) = normEnergyVal;
    all_energy_mean = mean(normEnergyVal);
    
    for j=1:size(percentile,2)
        chunk_energy = sum(bodyMoveEnergies(:, j));
        if(chunk_energy > 0)
            event_len = event_len + 1;
        else
            if(event_len < min_walk_frame_size)
                % Event have no minimum duration, remove it
                speed_curves(:,j-event_len:j) = 0;
                event_len = 0;
                continue;
            else
                % Save event speeds
                start_i = 0;
                end_i = 0;
                for k=j-event_len:j-1
                        smE = sum(bodyMoveEnergies(:,k));
                        if(smE > 0)
                            end_i = k;
                            if(start_i == 0) 
                                start_i = k;
                            end
                        end
                end
                
                new_event = speed_curves(:, start_i:end_i);
                event_energies = bodyMoveEnergies(:, start_i:end_i);
                
                slice_energy = mean(event_energies(find(event_energies > 0)))/all_energy_mean;
                
                start_csi_i = floor(window_size*start_i);
                start_csi_i = start_csi_i - 1600;
                if start_csi_i <= 0
                    start_csi_i = 1;
                end
                end_csi_i = ceil(window_size*end_i);
                end_csi_i = end_csi_i + 1600;
                if end_csi_i > size(nons_csi, 1)
                    end_csi_i = size(nons_csi, 1);
                end
                
                csi_e_data = nons_csi(start_csi_i:end_csi_i, :);
                msframesize = (frequency/10);
                duration_size = floor((end_csi_i-start_csi_i)/msframesize);
                ev_vars = zeros(1, duration_size);
                coeff_vars = zeros(size(csi_data,1)-1, duration_size);
                for ev_i=1:duration_size
                    msframe_start = ((ev_i-1) * msframesize)+1;
                    msframe_end = ((ev_i) * msframesize);
                    msframe_csi_data = csi_e_data(msframe_start:msframe_end,:);
                    coeff_msframe = pca(msframe_csi_data);
                    coeff_2nth_frame = coeff_msframe(:,2);
                    pca_2nth = msframe_csi_data*coeff_2nth_frame;
                    ev_vars(1,ev_i) = var(pca_2nth);
                    for coefs_i=2:length(coeff_2nth_frame)
                        coeff_vars(coefs_i-1, ev_i) = std([coeff_2nth_frame(coefs_i, 1) coeff_2nth_frame(coefs_i-1, 1)]);
                    end
                end
                
                if(slice_energy >= 0.5 && start_csi_i >= 1000)
                    events = [events new_event];
                    events_indexes = [events_indexes [start_i end_i]];
                    if(size([start_i:end_i], 2) < min_walk_frame_size)
                        disp(strcat('SIZE < ', num2str(min_walk_frame_size)));
                    end
                end
                event_len = 0;
            end
        end
        
        for i=1:size(percentile,1)
            energy_level = percentile(i,j);
            if(speed_curves(1,j) == 0 && energy_level >= 0.5)
                speed_curves(1,j) = f(i)/2*0.0579;
            end
            if(speed_curves(2,j) == 0 && energy_level >= 0.95)
                speed_curves(2,j) = f(i)/2*0.0579;
            end
        end
        
        last_energy = chunk_energy;
    end
    
    % Extract speed features
    speed_features = [];
    event_durations = [];
    for i=1:length(events)
        % Calcule main features
        event = events{1,i};
        torso_curve = event(1,:);
        legs_curve = event(2,:);
        event_durations(i,:) = frame_time*length(torso_curve);
        
        % Torso features
        t_mean = mean(torso_curve);
        t_max = max(torso_curve);
        t_min = min(torso_curve);
        t_skewness = skewness(torso_curve);
        t_kurtosis = kurtosis(torso_curve);
        t_var = var(torso_curve);
        normalized_curve = torso_curve/max(abs(torso_curve));
        t_entropy = entropy(normalized_curve);
        
        % Legs Features
        l_mean = mean(legs_curve);
        l_max = max(legs_curve);
        l_min = min(legs_curve);
        l_skewness = skewness(legs_curve);
        l_kurtosis = kurtosis(legs_curve);
        l_var = var(legs_curve);
        normalized_curve = legs_curve/max(abs(legs_curve));
        l_entropy = entropy(normalized_curve);
        
        %features = [ t_mean t_max t_min t_skewness t_kurtosis t_var t_zcr t_entropy ...
        features = [ t_mean t_max t_min t_skewness t_kurtosis t_var t_entropy ...
            l_mean l_max l_min l_skewness l_kurtosis l_var l_entropy];
        
%         % Calcule torso cycle/s
%         acf = autocorr(torso_curve);
%         inverted = max(acf) - acf;
%         disp(size(inverted));
%         [~, indexes] = findpeaks(inverted);
%         if(length(indexes) > 0)
%             features(1,end+1) = (indexes(1,1)-1) * frame_time * 2;
%         else
%             features(1,end+1) = 0;
%         end
%         
%         % Calcule legs cycle/s
%         acf = autocorr(legs_curve);
%         inverted = max(acf) - acf;
%         [~, indexes] = findpeaks(inverted);
%         if(length(indexes) > 0)
%             features(1,end+1) = (indexes(1,1)-1) * frame_time * 2;
%         else
%             features(1,end+1) = 0;
%         end
        
        speed_features(i,:) = features;
    end
    
    % Get energy signatures
    energy_signatures = [];
    for i=1:length(events_indexes)
        event = events_indexes{1,i};
        event_energies = newS(1:cutoff100, event(1,1):event(1,2));
        
        fulltime = frame_time * size(event_energies, 2);
        time25percent = fulltime/4;
        
        energy_signature = [];
        for k=1:4
            concept_start_time = (time25percent*(k-1));
            concept_end_time = (time25percent*(k));
            start_index = floor(concept_start_time/frame_time)+1;
            end_index = ceil(concept_end_time/frame_time);
            if(end_index > size(event_energies, 2))
                end_index = size(event_energies, 2);
            end
            
            slice_energy = event_energies(:, start_index:end_index);
            norm_energy = mean(slice_energy, 2);
            
            energy_signature(:,k) = norm_energy;
        end
        
        reshaped_energy = reshape(energy_signature, 1, []);
        energy_signatures(i,:) = reshaped_energy;
    end
    
%     % ONLY FOR EVENT RECOGNITION
%     event_recog_features = [];
%     for i=1:length(events_indexes)
%         event = events_indexes{1,i};
%         event_energy = newS(:, event(1,1):event(1,2));
%         ft = [];
%         for k=1:size(event_energy,1)
%            ft(end+1) = mean(event_energy(k,:));
%            ft(end+1) = var(event_energy(k,:));
%            ft(end+1) = max(event_energy(k,:));
%            ft(end+1) = min(event_energy(k,:));
%         end
%         event_recog_features(i,:) = ft;
%     end
%     % END EVENT RECOGNITION
    
    % Calcule non events frames
    events_frames = [];
    for i=1:length(events_indexes)
        event = events_indexes{1,i};
        start_time = floor(window_size*(event(1,1)-(1.5/frame_time)));
        end_time = ceil(window_size*(event(1,2)+(1.5/frame_time)));
        events_frames = [events_frames; (start_time:end_time).'];
    end
    
    otherwhise_indexes = setdiff(1:size(csi_data,2), events_frames);
    % Update CSI DATA with a normalization in perturbation
    nons_csi = (csi_mag - mean(csi_mag(:, otherwhise_indexes), 2)).';
    coeff= pca(nons_csi);
    pca_comps = nons_csi*coeff(:,1:20);
    
    %Calcule phase
%     phases_features = [];
%     for i=1:length(events_indexes)
%         event = events_indexes{1,i};
%         start_time = floor(window_size*event(1,1));
%         end_time = ceil(window_size*event(1,2));
%         event_in_time = csi_data(:, start_time:end_time).';
%         event_size = size(event_in_time,1);
%         event_in_time = event_in_time(1:(floor(event_size/10)*10),:);
% 
%         time_slice_features = [];
%         for j=1:size(event_in_time, 2)
%             relative_freq = size(event_in_time,1)/10;
%             s_data = reshape(event_in_time(:,j), relative_freq, []).';
%             for k=1:size(s_data, 1)
%                 time_slice_features(end+1,:) = entropy(phase(s_data(k,:)));
%             end
%         end
%         
%         phase_feature = imresize(reshape(time_slice_features, 1, []), [1 500], 'nearest');
%         phases_features(i,:) = phase_feature;
%     end
%     all_features = phases_features;
%     return;
    
    % Percentile curve
    percentile_features = [];
    for i=1:length(events_indexes)
        event = events_indexes{1,i};
        e_start_time = floor(event(1,1));
        e_end_time = ceil(event(1,2));

        start_time = e_start_time;
        end_time = e_end_time;
        
        event_percentile = percentile(:,start_time:end_time);
        percentile_curves = zeros(3, size(event_percentile,2));
        for j=1:size(event_percentile, 2)
            event_p_slice = event_percentile(:,j);
            perc_25 = find(event_p_slice >= 0.25);
            perc_50 = find(event_p_slice >= 0.50);
            perc_95 = find(event_p_slice >= 0.95);
            if(length(perc_25) > 0)
                percentile_curves(1,j) = perc_25(1,1);
            end
            if(length(perc_50) > 0)
                percentile_curves(2,j) = perc_50(1,1);
            end
            if(length(perc_95) > 0)
                percentile_curves(3,j) = perc_95(1,1);
            end
        end
        
        percentile_curves = imresize(percentile_curves, [3 30], 'nearest').';
        percentile_features(i,:) = reshape(percentile_curves, 1, []);
    end
    
    % Multipath features
%     multipath_features = [];
%     for i=1:length(events_indexes)
%         event = events_indexes{1,i};
%         start_time = floor(window_size*event(1,1));
%         end_time = ceil(window_size*event(1,2));
%         event_in_time = csi_data(:, start_time:end_time);
%         
%         ms100_size = frequency/10;
%         ms100_slices = floor(size(event_in_time,2)/ms100_size);
%         event_in_time = event_in_time(:, 1:ms100_slices*ms100_size);
%         event_iffts = [];
%         for k=1:ms100_slices
%             start_i = ((k-1)*ms100_size)+1;
%             end_i = k*ms100_size;
%             slice_data = event_in_time(:, start_i:end_i);
%             
%             angle_amp_f = [];
%             for l=1:2
%                 if l==1
%                     slice_ifft = abs(ifft(abs(slice_data)));
%                 else
%                     slice_ifft = abs(ifft(angle(slice_data)));
%                 end
%                 treated_ifft = mean(slice_ifft,2);
%                 hist_out = histcounts(treated_ifft, size(treated_ifft, 1));
%                 hist_out = hist_out(1,2:end);
%                 energy_indexes = find(hist_out > 0);
%                 multipaths = length(energy_indexes);
%                 norm_hist_energies = energy_indexes.*hist_out(1, energy_indexes);
%                 norm_hist_energies = imresize(norm_hist_energies, [1 20], 'nearest');
%                 angle_amp_f(:,l) = norm_hist_energies;
%             end
%             event_iffts(k,:) = reshape(angle_amp_f, 1, []);
%         end
%         
%         multipath_feature = reshape(event_iffts, 1, []);
%         multipath_feature = imresize(multipath_feature, [1 1000], 'nearest');
%         multipath_features(i,:) = multipath_feature;
%     end
    
    time_features = [];
    all_features = [];
    for i=1:length(events_indexes)
        event = events_indexes{1,i};
        start_time = floor(window_size*event(1,1));
        end_time = ceil(window_size*event(1,2));
%         start_time = floor(window_size*(event(1,1)-(1.5/frame_time)));
%         end_time = ceil(window_size*(event(1,2)+(1.5/frame_time)));
        %event_in_time = nons_csi(start_time:end_time, :);
        event_in_time = pca_comps(start_time:end_time, 2);
        
        % Start modification of fixed size
        maxVal = max(event_in_time).^2;
        minVal = min(event_in_time).^2;
        if(maxVal > minVal)
            centerIndex = find(event_in_time == max(event_in_time));
        else
            centerIndex = find(event_in_time == min(event_in_time));
        end
        centerIndex = start_time + centerIndex;
        wid_start = centerIndex-1600;
        wid_end = centerIndex+1600;
        if(wid_start < 1)
            wid_start = 1;
        end
        if(wid_end > size(pca_comps,1))
            wid_end = size(pca_comps,1);
        end
        event_pca = pca_comps(wid_start:wid_end, 2);
        event_in_time = pca_comps(wid_start:wid_end, 2:6);
        % USE 2:6 to get best results
        %event_in_time = pca_comps(start_time:end_time, 2);
        % End modification of fixed size
        
        event_size = size(event_in_time,1);
        event_in_time = event_in_time(1:(floor(event_size/10)*10),:);
        %event_in_time = mean(event_in_time,2);
        
        % Filter in 20-80Hz
        filtered_data = [];
        freq_range = [20 80];
        for m=1:size(event_in_time,2)
            [wt, wf] = cwt(event_in_time(:,m), 'amor', frequency);
            filtered_data(m,:) = icwt(wt, wf, freq_range, 'SignalMean', mean(event_in_time(:,m)));
        end
        event_in_time = filtered_data';
        % End filter
        
        % Normalize filtered data
        %event_in_time = event_in_time.^2;
        %mean_event_time = mean(event_in_time, 2);
        %min_event_time = min(event_in_time, [], 2);
        %max_event_time = max(event_in_time, [], 2);
        
        %norm_data = bsxfun(@rdivide, (event_in_time - min_event_time), (max_event_time - min_event_time)) * 10;
        %norm_data = event_in_time - mean_event_time;
        %event_in_time = norm_data;
        
        %energy_level = sum(event_in_time,2);
        %event_in_time = bsxfun(@rdivide, event_in_time, energy_level);
        
        %event_in_time = event_in_time - mean(event_in_time,1);
        % end
        
        time_slice_features = [];
        for j=1:size(event_in_time, 2)
            relative_freq = size(event_in_time,1)/10;
            s_data = reshape(event_in_time(:,j), relative_freq, []).';
            for k=1:size(s_data, 1)
                curve = db(s_data(k,:));
                
                c_mean = mean(curve);
                c_max = max(curve);
                c_min = min(curve);
                c_skewness = skewness(curve);
                c_kurtosis = kurtosis(curve);
                c_var = var(curve);
                c_zcr = sum(abs(diff(curve>0)))/length(curve);

                normalized_curve = curve/max(abs(curve));
                c_entropy = entropy(normalized_curve);
                c_energy = mean(s_data(k,:).^2);

                c_fft = abs(fft(curve)/relative_freq);
                cp_fft = c_fft(1:floor(relative_freq/2+1));
                cp_fft(2:end-1) = 2*cp_fft(2:end-1);
                cp_fft(1,1) = 0;
                fft_freq = find(cp_fft == max(cp_fft(:)));
                fft_freq = fft_freq(1,1);

%                time_slice_features(end+1,:) = [c_mean/10, c_max/10, c_min/10, ...
%                    c_skewness/10, c_kurtosis/10, c_var/10, c_zcr/10, c_entropy/10, c_energy/1000, fft_freq/10];
                time_slice_features(end+1,:) = [c_mean, c_max, c_min, ...
                    c_skewness, c_kurtosis, c_var, c_zcr, c_entropy, c_energy/100, fft_freq];
            end
        end
        
        %normalize kurtosis
        %time_slice_features(:,5) = time_slice_features(:,5)/sum(time_slice_features(:,5)) * 10;
        %time_features(:,:, i) = time_slice_features;
        
        %plot(time_slice_features.');
        reshaped_time_features = reshape(time_slice_features', 1, []);
        time_features(i,:) = reshaped_time_features;
        
        %reshaped_time_features = (reshaped_time_features - min(reshaped_time_features)) / ( max(reshaped_time_features) - min(reshaped_time_features) ) * (max(max(nons_csi)) /10);
        %event_features = [gait_features(i,:).'; percentile_features(i,:).'; reshaped_time_features.'].'; % all features
        %event_features = [gait_features(i,:).'; reshaped_time_features.'].'; % all features
        %event_features = gait_features(i,:); % Speed and spectrogram energy
        %event_features = reshape(energy_signatures(:,:, i), 1, []); % Only Spectrogram energy
        
        event_features = [event_durations(i,:).'; ...
            percentile_features(i,:).'; speed_features(i,:).'; ...
            energy_signatures(i,:).'; time_features(i,:).';].';
        all_features(i,:) = event_features;
    end
    
    % 2.95ms && 3.71ms
    % 2.35ms && 2.71ms
    %
%     figure;
%     imagesc(t, f, newS);
%     set(gca,'YDir','normal');
    
    spectrogram_data = struct('stft', newS, 'time', t, 'frequency', f);
end

