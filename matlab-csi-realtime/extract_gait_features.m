function [ all_features, energy_signatures, time_slice_features ] = extract_gait_features( csi_data, frequency )
    csi_mag = abs(csi_data);
    nons_csi = (csi_mag - mean(csi_mag, 2)).';
    coeff= pca(nons_csi);
    pca_comps = nons_csi*coeff(:,1:20);
    
    for i=1:size(pca_comps, 2)
       [y,f,t,p] = spectrogram(pca_comps(:,i), 256, 155, [], frequency);
       %[y,f,t,p] = spectrogram(pca_comps(:,i), 1024, 758, [], frequency);

       % Define the frequency range cut-off for body movement
       if(exist('cutoff') == 0)
           % Find the index of 146Hz
            for i=1:length(f)
               freq = f(i,1);
               if(freq >= 20 && exist('cutoff20') == 0)
                   cutoff20 = i;
               end
               if(freq >= 50 && exist('cutoff50') == 0)
                   cutoff50 = i;
               end
               if(freq >= 100 && exist('cutoff100') == 0)
                   cutoff100 = i;
               end
               if(freq >= 146 && exist('cutoff') == 0)
                   cutoff = i;
               end
            end
       end

       % Apply frequency cut-off
       y = abs(y(1:cutoff,:));
       p = p(1:cutoff,:);
       f = f(1:cutoff,1);
       
       auxY = y;
       auxP = p;

       % Define the chunks power level
       y_power = sum(y, 1);
       p_power = sum(p, 1);

       % Gets the Silence chunks
       limiar_y = mean(mean(y))*80;
       limiar_p = mean(mean(p))*80;
       silence_y_indexes = find(y_power <  limiar_y);
       silence_p_indexes = find(p_power <  limiar_p);
       
       % Removes the noise floor
       %y = y - mean(auxY(:,silence_y_indexes),2);
       %p = p - mean(auxP(:,silence_p_indexes),2);

       % Normalize the energy by the division of energy per total of energy
       y = bsxfun(@rdivide, y, y_power);
       y(isnan(y)) = 0;
       p = bsxfun(@rdivide, p, p_power);
       p(isnan(p)) = 0;

       % Removes the noise floor
       y = y - mean(y(:,silence_y_indexes),2);
       p = p - mean(p(:,silence_p_indexes),2);

       % Remove silenced chunks
       y(:,silence_y_indexes) = 0;
       p(:,silence_p_indexes) = 0;

       % Removes negative magnitude
       y(find(y<0)) = 0;
       p(find(p<0)) = 0;

       if(exist('newS'))
           newS = newS + y;
       else
           newS = y;
       end
    end
    
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
    last_with_energy = 0;
    all_energy_mean = mean(mean(newS(cutoff20:cutoff50, :)))*1000;
    for j=1:size(percentile,2)
        chunk_energy = sum(newS(cutoff20:cutoff50, j));
        if(chunk_energy > 0 || j-last_with_energy < 5)
            event_len = event_len + 1;
            if(chunk_energy > 0)
                last_with_energy = j;
            end
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
    for i=1:length(events)
        % Calcule main features
        event = events{1,i};
        torso_curve = event(1,:);
        legs_curve = event(2,:);
        event_duration = frame_time*length(torso_curve);
        
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
        
        %features = [ event_duration t_mean t_max t_min t_skewness t_kurtosis t_var t_zcr t_entropy ...
        features = [ event_duration t_mean t_max t_min t_skewness t_kurtosis t_var t_entropy ...
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
    
    gait_features = [];
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
        
        energy_signatures(:,:, i) = energy_signature;
        reshaped_energy = reshape(energy_signature, 1, []);
        event_features = [speed_features(i,:).'; reshaped_energy.'].';
        gait_features(i,:) = event_features;
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
        event_size = size(event_in_time,1);
        event_in_time = event_in_time(1:(floor(event_size/10)*10),:);
        %event_in_time = mean(event_in_time,2);
        
        % Filter in 20-80Hz
        filtered_data = [];
        freq_range = [20 80];
        for m=1:size(event_in_time,2)
            [wt, f] = cwt(event_in_time(:,m), 'amor', frequency);
            filtered_data(m,:) = icwt(wt, f, freq_range, 'SignalMean', mean(event_in_time(:,m)));
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

                time_slice_features(end+1,:) = [c_mean/10, c_max/10, c_min/10, ...
                    c_skewness/10, c_kurtosis/10, c_var/10, c_zcr/10, c_entropy/10, c_energy/1000, fft_freq/10];
            end
        end
        
        %normalize kurtosis
        %time_slice_features(:,5) = time_slice_features(:,5)/sum(time_slice_features(:,5)) * 10;
        %time_features(:,:, i) = time_slice_features;
        
        %plot(time_slice_features.');
        reshaped_time_features = reshape(time_slice_features', 1, []);
        %reshaped_time_features = (reshaped_time_features - min(reshaped_time_features)) / ( max(reshaped_time_features) - min(reshaped_time_features) ) * (max(max(nons_csi)) /10);
        event_features = [gait_features(i,:).'; reshaped_time_features.'].'; % all features
        %event_features = gait_features(i,:); % Speed and spectrogram energy
        %event_features = reshape(energy_signatures(:,:, i), 1, []); % Only Spectrogram energy
        all_features(i,:) = event_features;
    end
    
    % 2.95ms && 3.71ms
    % 2.35ms && 2.71ms
    %
    %figure;
    %imagesc(t, f, imgaussfilt(newS, 0.8, 'FilterSize', 5))
    %set(gca,'YDir','normal')
end

