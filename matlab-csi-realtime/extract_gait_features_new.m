function [ all_features, energy_signatures, time_slice_features, ...
    spectrogram_data, event_pca ] = extract_gait_features_new(csi_data, ...
    time_events, frequency, use_wavelet)

    if nargin < 4
        use_wavelet = 0;
    end

    % Starts feature extraction
    csi_mag = abs(csi_data);
    nons_csi = (csi_mag - mean(csi_mag, 2)).';
    coeff= pca(nons_csi);
    pca_comps = nons_csi*coeff(:,1:20);
    
    % Creates the spectrogram
    if use_wavelet == 0
        [ newS, f, t, ~, ~, cutoff100 ] = ...
            stft_spectrogram(csi_data, frequency);
    else
        [ newS, f, t, ~, ~, cutoff100 ] = ...
            wavelet_spectrogram(csi_data, frequency);
    end
    
    frame_time = (t(1,3) - t(1,2));
    window_size = frame_time * frequency;
    
    % Create Event Spectrogram indexes
    spec_events = {};
    for i=1:length(time_events)
        time_event_indexes = time_events{1,i};
        end_slice = floor(time_event_indexes(1,2)/window_size);
        if end_slice > size(newS,2)
            end_slice = size(newS,2);
        end
        spec_event = [ceil(time_event_indexes(1,1)/window_size) end_slice];
        spec_events = [spec_events spec_event];
    end
    
    % Start percentile creation and your 50% and 95% respectively speed
    % curves
    percentile = [];
    speed_curves(1:2, 1:size(newS,2)) = 0;
    for j=1:size(newS, 2)
        chunk_energy = sum(newS(:,j));
        for i=1:size(newS, 1)
            percentile(i,j) = sum(newS(1:i,j))/chunk_energy;
            if(speed_curves(1,j) == 0 && percentile(i,j) >= 0.5)
                speed_curves(1,j) = f(i)/2*0.0579;
            end
            if(speed_curves(2,j) == 0 && percentile(i,j) >= 0.95)
                speed_curves(2,j) = f(i)/2*0.0579;
            end
        end
    end
    percentile(isnan(percentile)) = 0;  % Zero NaN values.
    speed_curves(isnan(speed_curves)) = 0;
    
    speed_events = {};
    for i=1:length(spec_events)
        spec_event = spec_events{1,i};
        speed_event = speed_curves(:, spec_event(1,1):spec_event(1,2));
        initial_len = length(speed_event);
        speed_event(:, find(sum(speed_event,1) == 0)) = [];
        if length(speed_event) == 0
            speed_event = zeros(2, initial_len);
        end
        speed_events = [speed_events speed_event];
    end
    % End Percentile creation
    
    % Extracts Percentile curve
    percentile_features = [];
    for i=1:length(spec_events)
        event = spec_events{1,i};
        start_time = event(1,1);
        end_time = event(1,2);
        
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
        
        % Remove silenced time series
        curves_sum = sum(percentile_curves, 1);
        [~, silenced_indexes] = find(curves_sum == 0);
        initial_size = length(curves_sum);
        first_index = 1;
        for j=silenced_indexes
            if(j==first_index)
                percentile_curves(:,1) = [];
                first_index = first_index + 1;
            end
        end
        curves_sum = sum(percentile_curves, 1);
        [~, silenced_indexes] = find(curves_sum == 0);
        last_index = length(curves_sum);
        for j=sort(silenced_indexes, 'descend')
            if(j==last_index)
                percentile_curves(:,end) = [];
                last_index = last_index - 1;
            end
        end
        
        if size(percentile_curves, 2) == 0
            percentile_curves = zeros(3, initial_size);
        end
        % End silence removal
        
        percentile_curves = imresize(percentile_curves, [3 30], 'nearest').';
        percentile_features(i,:) = reshape(percentile_curves, 1, []);
    end
    
    % Extracts speed features
    speed_features = [];
    event_durations = [];
    for i=1:length(speed_events)
        % Calcule main features
        event = speed_events{1,i};
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
    for i=1:length(spec_events)
        event = spec_events{1,i};
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
    
    % Extracts PCA time features
    time_features = [];
    all_features = [];
    for i=1:length(time_events)
        event = time_events{1,i};
        event_pca = pca_comps(event(1,1):event(1,2), 2);
        event_in_time = pca_comps(event(1,1):event(1,2), 2:6);

        event_size = size(event_in_time,1);
        event_in_time = event_in_time(1:(floor(event_size/10)*10),:);
        
        % Filter in 20-80Hz
        filtered_data = [];
        freq_range = [20 80];
        for m=1:size(event_in_time,2)
            [wt, wf] = cwt(event_in_time(:,m), 'amor', frequency);
            filtered_data(m,:) = icwt(wt, wf, freq_range, 'SignalMean', ...
                mean(event_in_time(:,m)));
        end
        event_in_time = filtered_data';
        
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
        
        % Normalize energy signature (normally its very low comparing 
        % with other features...)
        e_multiplier = (max(energy_signatures(i,:))/max(time_features(i,:))) * 200;
        if(e_multiplier < 200)
            e_multiplier = 200;
        end
        
        energy_norm_features = (energy_signatures(i,:).') * e_multiplier;
        
        event_features = [event_durations(i,:).'; ...
            percentile_features(i,:).'; speed_features(i,:).'; ...
            energy_norm_features; time_features(i,:).';].';
        all_features(i,:) = event_features;
    end
    
    spectrogram_data = struct('stft', newS, 'time', t, 'frequency', f);
end

