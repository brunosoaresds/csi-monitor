function [pca_comps] = filter_csi_with_pca(csi_streams, pcs_count, include_noise_pcs)
    % fill components param if not informed
    if nargin < 2
        pcs_count = 6;
    end
    if nargin < 3
        include_noise_pcs = 0;
    end
    
    csi_mag = abs(csi_streams);
    nons_csi = csi_mag - mean(csi_mag, 2);
    [coeff, ~, latent] = pca(nons_csi);

    start_pcs = 1;
    if include_noise_pcs == 0
        % Compute Noise PCs and Info PCs
        rel = latent/sum(latent);
        sum_rel = 0;
        for i=1:length(rel)
            if sum_rel >= 0.9
                sum_rel = 0;
                start_pcs = i;
            end
            sum_rel = sum_rel + rel(i,1);
        end
    end
    end_pcs = start_pcs+pcs_count-1;
    
%     disp(strcat('start:', num2str(start_pcs)));
%     disp(strcat('end:', num2str(end_pcs)));
    
    pca_comps = nons_csi*coeff(:,start_pcs:end_pcs);
end