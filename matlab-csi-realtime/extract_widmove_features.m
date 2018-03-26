function [ all_features, energy_signatures, time_slice_features, ...
    spectrogram_data, event_pca ] = extract_widmove_features( csi_data, frequency )
    csi_mag = abs(csi_data);
    nons_csi = (csi_mag - mean(csi_mag, 2)).';
    coeff= pca(nons_csi);
    pca_comps = nons_csi*coeff(:,1:20);
    
    % Create the spectrogram
    [ newS, f, t, cutoff20, cutoff50, cutoff100 ] = stft_spectrogram(csi_data, frequency);
    
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
    all_energy_mean = mean(mean(newS(cutoff20:cutoff50, :)))*1000;
    for j=1:size(percentile,2)
        chunk_energy = sum(newS(cutoff20:cutoff50, j));
        if(chunk_energy > 0)
            event_len = event_len + 1;
        else
            if(event_len < 10)
                % Event have no minimum duration, remove it
                speed_curves(:,j-event_len:j) = 0;
                event_len = 0;
                continue;
            else
                % Save event speeds
                start_i = 0;
                end_i = 0;
                for k=j-event_len:j-1
                        smE = sum(newS(cutoff20:cutoff50,k));
                        if(smE > 0)
                            end_i = k;
                            if(start_i == 0) 
                                start_i = k;
                            end
                        end
                end
                
                new_event = speed_curves(:, start_i:end_i);
                event_energies = newS(cutoff20:cutoff50, start_i:end_i);
                slice_energy = sum(event_energies(find(event_energies > 0)))/all_energy_mean;
                
                if(slice_energy >= 0.5)
                    events = [events new_event];
                    events_indexes = [events_indexes [start_i end_i]];
                    if(size([start_i:end_i], 2) < 10)
                        disp('SIZE < 10');
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

    frame_time = (t(1,3) - t(1,2));

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
        
        features = [ t_mean t_max t_min t_skewness t_kurtosis t_var t_entropy ...
            l_mean l_max l_min l_skewness l_kurtosis l_var l_entropy];
        
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
    
    % Get time domain features
    window_size = frame_time * frequency;
    
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
    
    time_features = [];
    all_features = [];
    for i=1:length(events_indexes)
        event = events_indexes{1,i};
        start_time = floor(window_size*event(1,1));
        end_time = ceil(window_size*event(1,2));
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
        event_pca = pca_comps(centerIndex-1600:centerIndex+1600, 2);
        event_in_time = pca_comps(centerIndex-1600:centerIndex+1600, 2:6);
        %event_in_time = pca_comps(centerIndex-1600:centerIndex+1600, 2);
        
        event_size = size(event_in_time,1);
        event_in_time = event_in_time(1:(floor(event_size/10)*10),:);
        
        % Filter in 20-80Hz
        filtered_data = [];
        freq_range = [20 80];
        for m=1:size(event_in_time,2)
            [wt, wf] = cwt(event_in_time(:,m), 'amor', frequency);
            filtered_data(m,:) = icwt(wt, wf, freq_range, 'SignalMean', mean(event_in_time(:,m)));
        end
        event_in_time = filtered_data';
        % End filter
        
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

                time_slice_features(end+1,:) = [c_mean, c_max, c_min, ...
                    c_skewness, c_kurtosis, c_var, c_zcr, c_entropy, c_energy/100, fft_freq];
            end
        end
        
        reshaped_time_features = reshape(time_slice_features', 1, []);
        time_features(i,:) = reshaped_time_features;
        
        event_features = [event_durations(i,:).'; ...
            percentile_features(i,:).'; speed_features(i,:).'; ...
            energy_signatures(i,:).'; time_features(i,:).';].';
        all_features(i,:) = event_features;
    end
    
    spectrogram_data = struct('stft', newS, 'time', t, 'frequency', f);
end
