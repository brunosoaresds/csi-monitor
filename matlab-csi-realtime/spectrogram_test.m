csi_mag = abs(csi_data_running);
%csi_mag = abs(csi_data_walking);
nons_csi = (csi_mag - mean(csi_mag, 2)).';
coeff= pca(nons_csi);
pca_comps = nons_csi*coeff(:,1:20);

frequency = 800;
x = [];
clear newS cutoff
for i=1:size(pca_comps, 2)
   [y,f,t,p] = spectrogram(pca_comps(:,i), 256, 155, [], frequency);
   %[y,f,t,p] = spectrogram(pca_comps(:,i), 1024, 758, [], 2500);
   
   % Define the frequency range cut-off
   if(exist('cutoff') == 0)
       % Find the index of 146Hz
        for i=1:length(f)
           freq = f(i,1);
           if(freq > 146)
               cutoff = i;
               break
           end
        end
   end
   
   % Apply frequency cut-off
   y = abs(y(1:cutoff,:));
   p = p(1:cutoff,:);
   f = f(1:cutoff,1);
   
   % Define the chunks power level
   y_power = sum(y, 1);
   p_power = sum(p, 1);
   
   % Gets the Silence chunks
   limiar_y = mean(mean(y))*90;
   limiar_p = mean(mean(p))*90;
   silence_y_indexes = find(y_power <  limiar_y);
   silence_p_indexes = find(p_power <  limiar_p);
   
   % Normalize the energy by the division of energy per total of energy
   y = bsxfun(@rdivide, y, y_power);
   y(isnan(y)) = 0;
   p = bsxfun(@rdivide, p, p_power);
   p(isnan(p)) = 0;
   
   % Removes the noise floor
   y = y - mean(y,2);
   p = p - mean(p,2);
   
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
for j=1:size(percentile,2)
    chunk_energy = sum(percentile(:,j));
    if(chunk_energy > 0)
        event_len = event_len + 1;
    else
        if(event_len < 6)
            % Event have no minimum duration, remove it
            speed_curves(:,j-event_len:j) = 0;
            event_len = 0;
            continue;
        else
            % Save event speeds
            events = [events speed_curves(:,j-event_len:j-1)];
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
end

frame_time = (t(1,3) - t(1,2));
window_size = frame_time * frequency;

cycles_secs = [];
% Cycles/s calculed by the torso
for i=1:length(events)
    event = events{1,i};
    acf = autocorr(event(1,:));
    inverted = max(acf) - acf;
    [peakValues, indexes] = findpeaks(inverted);
    cycles_secs(end+1) = (indexes(1,1)-1) * frame_time * 2;
end

% 2.95ms && 3.71ms
% 2.35ms && 2.71ms
figure;
imagesc(t, f, imgaussfilt(newS, 0.8, 'FilterSize', 5))
set(gca,'YDir','normal')
