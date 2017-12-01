function [features, cell] = extract_features(csi, frequency)
    function [f] = calcule_features(complex_curve, los_power, frequency)
        curve = abs(complex_curve);
        curve = curve - los_power;
%         curve = db(curve);
        
        c_mean = mean(curve);
        c_max = max(curve);
        c_min = min(curve);
        c_skewness = skewness(curve);
        c_kurtosis = kurtosis(curve);
        c_var = var(curve);
        c_zcr = sum(abs(diff(curve>0)))/length(curve);
        
        normalized_curve = curve/max(abs(curve));
        c_entropy = entropy(normalized_curve);
        c_energy = mean(curve.^2);
        
        c_fft = abs(fft(curve)/frequency);
        cp_fft = c_fft(1:frequency/2+1);
        cp_fft(2:end-1) = 2*cp_fft(2:end-1);
        cp_fft(1,1) = 0;
        fft_freq = find(cp_fft == max(cp_fft(:)));
        fft_freq = fft_freq(1,1);
        
        f = [c_mean, c_max, c_min, c_skewness, c_kurtosis, c_var, c_zcr, ...
            c_entropy, c_energy, fft_freq];
    end

    subcarriers = 1:56;
%     %subcarriers = [1, 10, 20, 30, 40, 50, 56];

    %%% TIME EXTRACTION - OUR WORK
    features = [];
    dec_sec_freq = floor(frequency/10);
    csi_ifft = abs(ifft(csi));
    for i=subcarriers
        s_data = reshape(csi(i,:), dec_sec_freq, []).';
        ifft_reshaped = reshape(csi_ifft(1,:), dec_sec_freq, []).';
        for j=1:size(s_data, 1)
            slice_data = s_data(j,:);
            ifft_data = ifft_reshaped(j,:);
            features = cat(1, features, calcule_features(slice_data, ifft_data, dec_sec_freq));
        end
    end
    
%     for i=[8:9]
%         feature_data = features(:,i);
%         features(:,i) = (feature_data - min(feature_data)) / ( max(feature_data) - min(feature_data) );
%     end

% Inline features
    features = reshape(features, 1, []);
    
%     features = features.';
    
%     for i=7:7
%         feature_data = features(:,i);
%         features(:,i) = (feature_data - min(feature_data)) / ( max(feature_data) - min(feature_data) );
%     end

    
%     %%% TIME EXTRACTION - WIFI-ID
%     features = [];
%     dec_sec_freq = floor(frequency/10);
%     for i=subcarriers
%         s_data = reshape(abs_csi(i,:), dec_sec_freq, []).';
%         for j=1:size(s_data,1)
%             slice_data = s_data(j,:);
%             features = cat(1, features, calcule_features(slice_data));
%         end
%     end
%     
%     for i=7:7
%         feature_data = features(:,i);
%         features(:,i) = (feature_data - min(feature_data)) / ( max(feature_data) - min(feature_data) );
%     end
%     features = reshape(features, 1, []);

%     %%% WAVELET EXTRACTION
%     features = [];
%     for i=subcarriers
%         csi_stream_data = abs_csi(i, :);
%         
%         % Get wavelet curves
%         [ t1, d1 ] = dwt( csi_stream_data, 'sym1', 'mode', 'sym' );
%         [ t2, d2 ] = dwt( d1, 'sym1', 'mode', 'sym' );
%         [ t3, d3 ] = dwt( d2, 'sym1', 'mode', 'sym' );
%         [ t4, d4 ] = dwt( d3, 'sym1', 'mode', 'sym' );
%         [ t5, d5 ] = dwt( d4, 'sym1', 'mode', 'sym' );
% 
%         % Extract feature vector
%         fv = {csi_stream_data; t1; d1; t2; d2; t3; d3; t4; d4; t5; d5};
%         fv = cellfun(@calcule_features, fv, 'UniformOutput', false);
%         fv = cell2mat(fv);
%         features{i,1} = fv;
%     end
%     
%     features = cell2mat(features);
%     features = reshape(features, 1, []);
end