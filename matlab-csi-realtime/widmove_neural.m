% Create vector with all set
all_set = cat(1, out_features, in_features);
all_features_len = size(all_set, 1);
features_len = size(out_features, 1);
all_labels = [];
all_labels(1:features_len, 1) = 1;
all_labels(features_len+1:features_len*2, 1) = 2;

% suffle all_set
all_set = all_set(randomize, :).';
all_labels = all_labels(randomize, :).';

% create onehotencoding
targets = zeros(2, all_features_len);
for i=1:all_features_len
    targets(all_labels(1,i), i) = 1;
end

clear i features_len all_features_len all_labels;