c ja function [ carm_features ] = get_carm_features( event_csi, event_slice, frequency )
    function [f] = calcule_features(signal, wavelet_level, frequency, num_secs)
        reshaped = (frequency/(2^(wavelet_level-1)))/5;
        f = [];
        next_energy = 0;
        for i=1:(5*num_secs)
            inverse = ((5*num_secs) - i) + 1;
            start_at = (reshaped*(i-1)) + 0.000001;
            if(start_at < 1)
                start_at = 1;
            end
            start_at = ceil(start_at);
            end_at = ceil(reshaped*i);

            subsec_data = signal(1,start_at:end_at);
            energy_average = mean(subsec_data);
            difference_of_last = energy_average - next_energy;
            f(1,inverse) = energy_average;
            f(2,inverse) = difference_of_last;
            next_energy = energy_average;
        end
    end

    function [fcell] = calcule_wavelet_recurssive(w_level, stop_level, signal)   
        [ t, ~ ] = dwt(signal, 'sym1', 'mode', 'sym');
        fcell = { signal };

        if(w_level == stop_level-1)
            fcell = [ fcell t ];
            return;
        end

        nextt = calcule_wavelet_recurssive(w_level+1, stop_level, t);
        fcell = [fcell nextt ];
    end

    csi_mag = abs(event_csi);
    nons_csi = (csi_mag - mean(csi_mag, 2)).';
    coeff= pca(nons_csi);

    fcell = {};
    max_w_levels = 12;
    pca_comps = nons_csi*coeff(:,2:6);
    pca_comps = pca_comps(event_slice,:);
    for i=1:size(pca_comps,2)
        comp_data = calcule_wavelet_recurssive(1, max_w_levels, pca_comps(:,i).');
        for j=1:max_w_levels
            if i > 1
                aux = fcell{1,j};
                wdata = comp_data{1,j};
                aux(end+1,:) = wdata;
            else
                aux = comp_data{1,j};
            end

            fcell{1,j} = aux;
        end
    end

    % Average data and calcule features
    seconds = size(event_slice, 2)/frequency;
    all_features = [];
    for wsecs=1:max_w_levels
        all_data = fcell{1,wsecs};
        averaged_data = mean(all_data, 1);        
        features = calcule_features(averaged_data, wsecs, frequency, seconds);
        all_features((2*(wsecs-1)+1):2*wsecs,:) = features;
    end
    
    carm_features = reshape(all_features, 1, []);
end

