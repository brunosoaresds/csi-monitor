function [ newS, freqs, sample_time, cutoff20, cutoff50, cutoff100 ] = wavelet_spectrogram( csi_data, frequency )
    % Create the PCA components based on the CSI amplitude.
    csi_mag = abs(csi_data);
    nons_csi = (csi_mag - mean(csi_mag, 2)).';
    coeff= pca(nons_csi);
    pca_comps = nons_csi*coeff(:,2:6);
    
    samples_len = size(csi_data, 2);
    sample_duration = samples_len/frequency;
    sample_time = linspace(0, sample_duration, samples_len);
    for comp=1:size(pca_comps,2)
        [cfs, freqs] = cwt(pca_comps(:,comp), 'amor', frequency);
%         if(comp == 1)
%             figure;
%             cwt(pca_comps(:,comp), 'amor', frequency);
%         end
        % Find for the frequencies indexes
        % Define the frequency range cut-off for body movement
        if(exist('cutoff20') == 0)
            freq_len = length(freqs);
            for i=1:freq_len
                freqIndex = (freq_len+1)-i;
                freq = freqs(freqIndex,1);
                if(freq >= 1 && exist('cutoff1') == 0)
                	cutoff1 = freqIndex;
                end
                if(freq >= 20 && exist('cutoff20') == 0)
                	cutoff20 = freqIndex;
                end
                if(freq >= 50 && exist('cutoff50') == 0)
                	cutoff50 = freqIndex;
                end
                if(freq >= 100 && exist('cutoff100') == 0)
                	cutoff100 = freqIndex;
                end
            end
        end
        
        energy = abs(cfs);
        
        % Removes the noise floor in frequency
        energy = energy - mean(energy, 2);
        
        % Silence frequences in different range than 0~100Hz
        silenceFrequencies = setdiff(1:size(energy,1), cutoff100:cutoff1+1);
        energy(silenceFrequencies, :) = 0;
        
        % Removes negative energies
        energy(find(energy<0)) = 0;
        
        % Find body movement intervals
        %energy20hz = energy(cutoff20,:);
        %normEnergy = (energy20hz-min(energy20hz))/(max(energy20hz)-min(energy20hz));
        
        % Remove noise floor (below to 12,5% of energy)
        %[~, noiseLocs] = find(normEnergy <= 0.125);
        %withoutNoiseEnergy = normEnergy;
        %withoutNoiseEnergy(noiseLocs) = 0;
        %[~, movementLocs] = find(withoutNoiseEnergy > 0);
        
        % Group similar peaks
        %lastIndex = 0;
        %for i=movementLocs
        %    if(lastIndex ~= 0 && (i-lastIndex) < (frequency/2))
        %        withoutNoiseEnergy(1, lastIndex:i) = 1;
        %    end
        %    lastIndex = i;
        %end
        
        % Remove silenced indexes;
        %[~, movementLocs] = find(withoutNoiseEnergy > 0);
        %silencedLocs = setdiff(1:size(energy,2), movementLocs);
        %energy(:, silencedLocs) = 0;
        
        % Sum component spectrograms
        if(exist('newS'))
        	newS = newS + energy;
        else
            newS = energy;
        end
    end
    
    % Cut frequencies and flip up to down the data
    newS = flipud(newS(cutoff100:cutoff1,:));
    freqs = flipud(freqs(cutoff100:cutoff1, :));
    freqLen = length(freqs);
    cutoff20 = freqLen-(cutoff20-cutoff100);
    cutoff50 = freqLen-(cutoff50-cutoff100);
    cutoff100 = freqLen-(cutoff100-cutoff100);
    
    % Normalize Body energies between 0 and 1
    energyIndexes = find(newS > 0);
    allEnergies = newS(energyIndexes);
    maxEnergy = max(allEnergies);
    minEnergy = min(allEnergies);
    normEnergyVal = (allEnergies-minEnergy)/(maxEnergy-minEnergy);
    newS(energyIndexes) = normEnergyVal;
    % Remove silenced (no movement) slices.
%     all_energy_mean = mean(normEnergyVal);
%     for i=1:size(newS,2)
%         chunkEnergies = newS(:,i)/all_energy_mean;
%         if(length(find(chunkEnergies < 0.1)) > 0)
%             newS(:,i) = 0;
%         end
%     end
    
    % Apply gaussian filter on spectrogram
    newS = imgaussfilt(newS, 0.8, 'FilterSize', 5);
    %imshow(newS, 'DisplayRange', [min(min(newS)) max(max(newS))]);
    %figure;
    
    %freqs
    
    %imagesc(sample_time, freqs, newS);
%      imagesc(sample_time, log2(freqs), newS);
     %set(gca,'Ydir','normal');
% 
%     ax = gca;
%     ytick = cellfun(@str2num, ax.YTickLabel);
%     ax.YTickLabel = num2str(2.^ytick);
end

