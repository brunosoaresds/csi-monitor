function [events_indexes] = extract_event_intervals(csi_data, frequency)
    csi_mag = abs(csi_data);
    nons_csi = (csi_mag - mean(csi_mag, 2)).';
    coeff= pca(nons_csi);
    pca_comps = nons_csi*coeff(:,2);
    
    % Create the spectrogram
    [ newS, ~, t, cutoff20, cutoff50, ~ ] = stft_spectrogram(csi_data, frequency);
    
    frame_time = (t(1,3) - t(1,2));
    min_walk_frame_size = ceil(1.2/frame_time);
    window_size = frame_time * frequency;

    event_len = 0;
    events_indexes = {};
    
    % Normalize Body energies between 0 and 1
    bodyMoveEnergies = newS(cutoff20:cutoff50, :);
    energyIndexes = find(bodyMoveEnergies > 0);
    allEnergies = bodyMoveEnergies(energyIndexes);
    maxEnergy = max(allEnergies);
    minEnergy = min(allEnergies);
    normEnergyVal = (allEnergies-minEnergy)/(maxEnergy-minEnergy);
    bodyMoveEnergies(energyIndexes) = normEnergyVal;
    all_energy_mean = mean(normEnergyVal);
    
    for j=1:size(newS,2)
        chunk_energy = sum(bodyMoveEnergies(:, j));
        if(chunk_energy > 0)
            event_len = event_len + 1;
        else
            if(event_len < min_walk_frame_size)
                % Event have no minimum duration, remove it
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
                
                event_energies = bodyMoveEnergies(:, start_i:end_i);
                slice_energy = mean(event_energies(find(event_energies > 0)))/all_energy_mean;
                
                if(slice_energy >= 0.5)
                    start_csi_i = floor(window_size*start_i);
                    end_csi_i = ceil(window_size*end_i);
                    
                    event_in_time = pca_comps(start_csi_i:end_csi_i, 1);
                    % Start modification of fixed size
                    maxVal = max(event_in_time).^2;
                    minVal = min(event_in_time).^2;
                    if(maxVal > minVal)
                        centerIndex = find(event_in_time == max(event_in_time));
                    else
                        centerIndex = find(event_in_time == min(event_in_time));
                    end
                    centerIndex = start_csi_i + centerIndex;
                    wid_start = centerIndex-1600;
                    wid_end = centerIndex+1600;
                    if(wid_start < 1)
                        wid_start = 1;
                    end
                    if(wid_end > size(pca_comps,1))
                        wid_end = size(pca_comps,1);
                    end
        
                    events_indexes = [events_indexes [wid_start wid_end]];
                end
                event_len = 0;
            end
        end
    end
end