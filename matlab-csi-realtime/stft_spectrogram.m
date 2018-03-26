function [ newS, f, t, cutoff20, cutoff50, cutoff100 ] = stft_spectrogram( csi_data, frequency )
    % Create the PCA components based on the CSI amplitude.
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
    
    % Apply gaussian filter on spectrogram
    newS = imgaussfilt(newS, 0.8, 'FilterSize', 5);
    
%     figure;
%     imagesc(t, f, newS);
%     set(gca,'YDir','normal');
end

