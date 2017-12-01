labels = {};
labels(1,:) = {'Bruno'};
labels(2,:) = {'Geovana'};
labels(3,:) = {'Vinicius'};
labels(4,:) = {'Phelipe'};

% entries_names = [1; 1; 1; 1; 1; 1; 2; 2; 2; 2; 2; 3; 3; 3; 3; 3; 4; 4; 4; 4; 4];
% datasets = {'csi_data_bruno_1' 'csi_data_bruno_2' ...
%     'csi_data_bruno_3' 'csi_data_bruno_4' 'csi_data_bruno_5' ...
%     'csi_data_bruno_11 ' ... % Other day data from bruno
%     'csi_data_geovana_1' 'csi_data_geovana_2' 'csi_data_geovana_3' ...
%     'csi_data_geovana_4' 'csi_data_geovana_5' 'csi_data_vinicius_1' ...
%     'csi_data_vinicius_2' 'csi_data_vinicius_3' 'csi_data_vinicius_4' ...
%     'csi_data_vinicius_5' 'csi_data_phelipe_1' 'csi_data_phelipe_2' ...
%     'csi_data_phelipe_3' 'csi_data_phelipe_4' 'csi_data_phelipe_5'};
entries_names = [1; 1; 1; 1; 1; 2; 2; 2; 2; 2; 3; 3; 3; 3; 3; 4; 4; 4; 4; 4];
datasets = {'csi_direct_bruno_1' 'csi_direct_bruno_2' ...
    'csi_direct_bruno_3' 'csi_direct_bruno_4' 'csi_direct_bruno_5' ...
    'csi_direct_geovana_1' 'csi_direct_geovana_2' ...
    'csi_direct_geovana_3' 'csi_direct_geovana_4' 'csi_direct_geovana_5' ...
    'csi_direct_vinicius_1' 'csi_direct_vinicius_2' ...
    'csi_direct_vinicius_3' 'csi_direct_vinicius_4' ...
    'csi_direct_vinicius_5' 'csi_direct_phelipe_1' 'csi_direct_phelipe_2' ...
    'csi_direct_phelipe_3' 'csi_direct_phelipe_4' 'csi_direct_phelipe_5'};

all_features = [];
for i=1:size(datasets, 2)
    dataset = eval(datasets{1,i});
    [slices ~] = wifi_id_extract_freq_band_secs(dataset, 800);
    features = extract_features(slices.slice_complex_1, 800);
    all_features(i,:) = features;
end

% testsets = {'csi_data_bruno_6' 'csi_data_bruno_7' 'csi_data_bruno_8' ...
%     'csi_data_bruno_9' 'csi_data_bruno_10' 'csi_data_bruno_12' ...
%     'csi_data_geovana_6' 'csi_data_geovana_7' 'csi_data_geovana_8' ...
%     'csi_data_geovana_9' 'csi_data_geovana_10' 'csi_data_vinicius_6' ...
%     'csi_data_vinicius_7' 'csi_data_vinicius_8' 'csi_data_vinicius_9' ...
%     'csi_data_vinicius_10' 'csi_data_phelipe_6' 'csi_data_phelipe_7' ...
%     'csi_data_phelipe_8' 'csi_data_phelipe_9' 'csi_data_phelipe_10'};
testsets = {'csi_direct_bruno_6' 'csi_direct_bruno_7' ...
    'csi_direct_bruno_8' 'csi_direct_bruno_9' 'csi_direct_bruno_10' ...
    'csi_direct_geovana_7' ...
    'csi_direct_geovana_8' 'csi_direct_geovana_9' 'csi_direct_geovana_10' ...
    'csi_direct_vinicius_6' 'csi_direct_vinicius_7' ...
    'csi_direct_vinicius_8' 'csi_direct_vinicius_9' ...
    'csi_direct_vinicius_10' 'csi_direct_phelipe_6' 'csi_direct_phelipe_7' ...
    'csi_direct_phelipe_8' 'csi_direct_phelipe_9' 'csi_direct_phelipe_10'};

test_features = [];
for i=1:size(testsets, 2)
    testset = eval(testsets{1,i});
    [slices ~] = wifi_id_extract_freq_band_secs(testset, 800);
    features = extract_features(slices.slice_complex_1, 800);
    test_features(i,:) = features;
end

[ranked, weights] = relieff(all_features, entries_names, 5);
% ranked_features = all_features(:, find(weights>0.2));
% test_features = test_features(:, find(weights>0.2));

% Compute features by percent...
ranked_features_1 = all_features(:, ranked(1:floor(length(ranked)*0.01)));
test_features_1 = test_features(:, ranked(1:floor(length(ranked)*0.01)));
ranked_features_5 = all_features(:, ranked(1:floor(length(ranked)*0.05)));
test_features_5 = test_features(:, ranked(1:floor(length(ranked)*0.05)));
ranked_features_10 = all_features(:, ranked(1:floor(length(ranked)*0.1)));
test_features_10 = test_features(:, ranked(1:floor(length(ranked)*0.1)));
ranked_features_20 = all_features(:, ranked(1:floor(length(ranked)*0.2)));
test_features_20 = test_features(:, ranked(1:floor(length(ranked)*0.2)));
ranked_features_30 = all_features(:, ranked(1:floor(length(ranked)*0.3)));
test_features_30 = test_features(:, ranked(1:floor(length(ranked)*0.3)));
ranked_features_40 = all_features(:, ranked(1:floor(length(ranked)*0.4)));
test_features_40 = test_features(:, ranked(1:floor(length(ranked)*0.4)));
ranked_features_50 = all_features(:, ranked(1:floor(length(ranked)*0.5)));
test_features_50 = test_features(:, ranked(1:floor(length(ranked)*0.5)));
ranked_features_60 = all_features(:, ranked(1:floor(length(ranked)*0.6)));
test_features_60 = test_features(:, ranked(1:floor(length(ranked)*0.6)));
ranked_features_70 = all_features(:, ranked(1:floor(length(ranked)*0.7)));
test_features_70 = test_features(:, ranked(1:floor(length(ranked)*0.7)));
ranked_features_80 = all_features(:, ranked(1:floor(length(ranked)*0.8)));
test_features_80 = test_features(:, ranked(1:floor(length(ranked)*0.8)));
ranked_features_90 = all_features(:, ranked(1:floor(length(ranked)*0.9)));
test_features_90 = test_features(:, ranked(1:floor(length(ranked)*0.9)));
ranked_features_100 = all_features(:, ranked(1:floor(length(ranked))));
test_features_100 = test_features(:, ranked(1:floor(length(ranked))));

t = templateSVM('Standardize', true, 'KernelFunction', 'rbf', ...
    'KernelScale','auto');

SVMModel = fitcecoc(ranked_features_1, labels(entries_names), 'Learners', t);
disp('USING 1%');
disp(predict(SVMModel, test_features_1));

SVMModel = fitcecoc(ranked_features_5, labels(entries_names), 'Learners', t);
disp('USING 5%');
disp(predict(SVMModel, test_features_5));

SVMModel = fitcecoc(ranked_features_10, labels(entries_names), 'Learners', t);
disp('USING 10%');
disp(predict(SVMModel, test_features_10));

SVMModel = fitcecoc(ranked_features_20, labels(entries_names), 'Learners', t);
disp('USING 20%');
disp(predict(SVMModel, test_features_20));

SVMModel = fitcecoc(ranked_features_30, labels(entries_names), 'Learners', t);
disp('USING 30%');
disp(predict(SVMModel, test_features_30));

SVMModel = fitcecoc(ranked_features_40, labels(entries_names), 'Learners', t);
disp('USING 40%');
disp(predict(SVMModel, test_features_40));

SVMModel = fitcecoc(ranked_features_50, labels(entries_names), 'Learners', t);
disp('USING 50%');
disp(predict(SVMModel, test_features_50));

SVMModel = fitcecoc(ranked_features_60, labels(entries_names), 'Learners', t);
disp('USING 60%');
disp(predict(SVMModel, test_features_60));

SVMModel = fitcecoc(ranked_features_70, labels(entries_names), 'Learners', t);
disp('USING 70%');
disp(predict(SVMModel, test_features_70));

SVMModel = fitcecoc(ranked_features_80, labels(entries_names), 'Learners', t);
disp('USING 80%');
disp(predict(SVMModel, test_features_80));

SVMModel = fitcecoc(ranked_features_90, labels(entries_names), 'Learners', t);
disp('USING 90%');
disp(predict(SVMModel, test_features_90));

SVMModel = fitcecoc(ranked_features_100, labels(entries_names), 'Learners', t);
disp('USING 100%');
disp(predict(SVMModel, test_features_100));
