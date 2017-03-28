function ret = pca_filter(data, components)
    % fill components param if not informed
    if nargin < 2
        components = 2:6;
    end
    
    [m, n] = size(data);
    
    % Removes the mean (static path) of data
    data = data - repmat(mean(data), m, 1);
    
    [coeff, score, latent] = pca(data);
    % Calculates the component reliability
    %rel = latent/sum(latent);
    
    [~, n_score] = size(score);
    if max(components) > n_score
        components = 1:n_score;
    end
    ret = score(:,components)*coeff(:,components)';
end