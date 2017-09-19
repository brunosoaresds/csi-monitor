labels = {};
labels(1,:) = {'Bruno'};
labels(2,:) = {'Phelipe'};

entries_names = [];
all_features = [];

% Bruno
[slices, full_data] = second_variance(csi_data_bruno_1, 800);
features = extract_features(slices.slice_1, 800);
initial_index = size(entries_names,1);
entries_names(initial_index+1:initial_index+size(features,2), 1) = 1;
all_features = cat(1, all_features, features);

[slices, full_data] = second_variance(csi_data_bruno_2, 800);
features = extract_features(slices.slice_1, 800);
initial_index = size(entries_names,1);
entries_names(initial_index+1:initial_index+size(features,2), 1) = 1;
all_features = cat(1, all_features, features);

[slices, full_data] = second_variance(csi_data_bruno_3, 800);
features = extract_features(slices.slice_1, 800);
initial_index = size(entries_names,1);
entries_names(initial_index+1:initial_index+size(features,2), 1) = 1;
all_features = cat(1, all_features, features);

[slices, full_data] = second_variance(csi_data_bruno_4, 800);
features = extract_features(slices.slice_1, 800);
initial_index = size(entries_names,1);
entries_names(initial_index+1:initial_index+size(features,2), 1) = 1;
all_features = cat(1, all_features, features);

[slices, full_data] = second_variance(csi_data_bruno_5, 800);
features = extract_features(slices.slice_1, 800);
initial_index = size(entries_names,1);
entries_names(initial_index+1:initial_index+size(features,2), 1) = 1;
all_features = cat(1, all_features, features);


% Phelipe
[slices, full_data] = second_variance(csi_data_phelipe_1, 800);
features = extract_features(slices.slice_1, 800);
initial_index = size(entries_names,1);
entries_names(initial_index+1:initial_index+size(features,2), 1) = 2;
all_features = cat(1, all_features, features);

[slices, full_data] = second_variance(csi_data_phelipe_2, 800);
features = extract_features(slices.slice_1, 800);
initial_index = size(entries_names,1);
entries_names(initial_index+1:initial_index+size(features,2), 1) = 2;
all_features = cat(1, all_features, features);

[slices, full_data] = second_variance(csi_data_phelipe_3, 800);
features = extract_features(slices.slice_1, 800);
initial_index = size(entries_names,1);
entries_names(initial_index+1:initial_index+size(features,2), 1) = 2;
all_features = cat(1, all_features, features);

[slices, full_data] = second_variance(csi_data_phelipe_4, 800);
features = extract_features(slices.slice_1, 800);
initial_index = size(entries_names,1);
entries_names(initial_index+1:initial_index+size(features,2), 1) = 2;
all_features = cat(1, all_features, features);

[slices, full_data] = second_variance(csi_data_phelipe_5, 800);
features = extract_features(slices.slice_1, 800);
initial_index = size(entries_names,1);
entries_names(initial_index+1:initial_index+size(features,2), 1) = 2;
all_features = cat(1, all_features, features);



% PCA
% [coeff, score, latent] = pca(all_features.');
% auto_vet = coeff(:,1:2);
% pca_features = auto_vet.' * all_features;
% pca_features = reshape(pca_features, 112, []);
% 
% test_set = pca_features.';
% test_set = test_set([40, 200, 300, 400], :);
% disp(test_set);

% RELIEFF
entries_names = [];
entries_names(1:5,1) = 1;
entries_names(6:10,1) = 1;

[ranked, weights] = relieff(all_features, entries_names, 5);
ranked_features = all_features(:, find(weights>0.2));

test_set = [];
[slices, full_data] = second_variance(csi_test_bruno_1, 800);
features = extract_features(slices.slice_1, 800);
test_set(1,:) = features(1, find(weights > 0.2));
[slices, full_data] = second_variance(csi_test_bruno_2, 800);
features = extract_features(slices.slice_1, 800);
test_set(2,:) = features(1, find(weights > 0.2));
[slices, full_data] = second_variance(csi_test_phelipe_1, 800);
features = extract_features(slices.slice_1, 800);
test_set(3,:) = features(1, find(weights > 0.2));

results = multisvm(ranked_features, entries_names, test_set);
disp(labels(results));

% entries_names = labels(entries_names);
% NBModel1 = fitNaiveBayes(pca_features.', entries_names, 'Distribution', 'kernel');
% NBModel1.ClassLevels
% 
% %Predict the trained data
% predictLabels1 = predict(NBModel1, test_set);
% %[ConfusionMat1, NBlabels] = confusionmat(entries_names, predictLabels1);
% disp(predictLabels1);

