plotData = 0;
featureId = 1;
labels = {};
labels(1,:) = {'Bruno'};
labels(2,:) = {'Geovana'};
labels(3,:) = {'Vinicius'};
labels(4,:) = {'Phelipe'};
labels(5,:) = {'Josenilton'};
labels(6,:) = {'Luan'};
labels(7,:) = {'Pablo'};
labels(8,:) = {'Marcelo'};

datasets_struct = {{'csi_data_bruno_w_', [57 60], 1} {'csi_data_bruno_w_', [62 65], 1} {'csi_data_bruno_w_', [67 70], 1} {'csi_data_bruno_w_', [72 75], 1} ...
    {'csi_data_geovana_w_', [1 4], 2} {'csi_data_geovana_w_', [6 9], 2} {'csi_data_geovana_w_', [11 14], 2} ...
    {'csi_data_vinicius_w_', [11 14], 3} {'csi_data_vinicius_w_', [16 19], 3} {'csi_data_vinicius_w_', [21 24], 3} {'csi_data_vinicius_w_', [26 29], 3} ...
    {'csi_data_phelipe_w_', [1 4], 4} {'csi_data_phelipe_w_', [6 9], 4} {'csi_data_phelipe_w_', [11 14], 4} ...
    {'csi_data_josenilton_w_', [1 4], 5} {'csi_data_josenilton_w_', [6 9], 5} {'csi_data_josenilton_w_', [11 14], 5} ...
    {'csi_data_luan_w_', [1 4], 6} {'csi_data_luan_w_', [6 9], 6} {'csi_data_luan_w_', [11 14], 6} ...
    {'csi_data_pablo_w_', [1 4], 7} {'csi_data_pablo_w_', [6 9], 7} {'csi_data_pablo_w_', [11 14], 7} {'csi_data_pablo_w_', [16 19], 7} ...
    {'csi_data_marcelo_w_', [54 57], 8} {'csi_data_marcelo_w_', [59 62], 8} {'csi_data_marcelo_w_', [64 67], 8}};
datasets = {};
entries_names = [];
for i=1:length(datasets_struct)
    x = datasets_struct{1,i};
    pattern = x{1,1};
    indexes = x{1,2};
    label_id = x{1,3};
    for j=indexes(1,1):indexes(1,2)
        datasets = [datasets strcat(pattern, num2str(j))];
        entries_names(end+1) = label_id;
    end
end
entries_names = entries_names.';

last = 0;
all_features = [];
for i=1:size(datasets, 2)
    dataset = eval(datasets{1,i});
    features = extract_gait_features(dataset, 800);
    if(size(features, 1) ~= 2)
        disp(strcat('Test: ', datasets{1,i}, num2str(size(features, 1))));
    end
    all_features(i,:) = features(featureId,:);
    
    % Plot features;
    if(plotData == 1)
        actual = entries_names(i,1);
        if(actual ~= last)
            figure;
            hold on;
        end
        last = actual;
        plot(features(featureId,:));    
    end
end


% Define test set
testsets_struct = {{'csi_data_bruno_w_', [61 61], 1} {'csi_data_bruno_w_', [66 66], 1} {'csi_data_bruno_w_', [71 71], 1} {'csi_data_bruno_w_', [76 76], 1} ...
    {'csi_data_geovana_w_', [5 5], 2} {'csi_data_geovana_w_', [10 10], 2} {'csi_data_geovana_w_', [15 15], 2} ...
    {'csi_data_vinicius_w_', [15 15], 3} {'csi_data_vinicius_w_', [20 20], 3} {'csi_data_vinicius_w_', [25 25], 3} {'csi_data_vinicius_w_', [30 30], 3}...
    {'csi_data_phelipe_w_', [5 5], 4} {'csi_data_phelipe_w_', [10 10], 4} {'csi_data_phelipe_w_', [15 15], 4} ...
    {'csi_data_josenilton_w_', [5 5], 5} {'csi_data_josenilton_w_', [10 10], 5} {'csi_data_josenilton_w_', [15 15], 5} ...
    {'csi_data_luan_w_', [5 5], 6} {'csi_data_luan_w_', [10 10], 6} {'csi_data_luan_w_', [15 15], 6} ...
    {'csi_data_pablo_w_', [5 5], 7} {'csi_data_pablo_w_', [10 10], 7} {'csi_data_pablo_w_', [15 15], 7} {'csi_data_pablo_w_', [20 20], 7} ...
    {'csi_data_marcelo_w_', [58 58], 8} {'csi_data_marcelo_w_', [63 63], 8} {'csi_data_marcelo_w_', [68 68], 8}};
testsets = {};
test_names = [];
for i=1:length(testsets_struct)
    x = testsets_struct{1,i};
    pattern = x{1,1};
    indexes = x{1,2};
    label_id = x{1,3};
    for j=indexes(1,1):indexes(1,2)
        testsets = [testsets strcat(pattern, num2str(j))];
        test_names(end+1) = label_id;
    end
end
test_names = test_names.';

last = 0;
test_features = [];
for i=1:size(testsets, 2)
    testset = eval(testsets{1,i});
    features = extract_gait_features(testset, 800);
    if(size(features, 1) ~= 2)
        disp(strcat('Test: ', testsets{1,i}, num2str(size(features, 1))));
    end
    test_features(i,:) = features(featureId,:);
    
    % Plot features;
    if(plotData == 1)
        actual = test_names(i,1);
        if(actual ~= last)
            figure;
            hold on;
        end
        last = actual;
        plot(features(featureId,:));    
    end
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

%SVMModel = fitcnb(ranked_features_1, labels(entries_names), 'Distribution', 'kernel');
SVMModel = fitcecoc(ranked_features_1, labels(entries_names), 'Learners', t);
disp('USING 1%');
predictLabels = predict(SVMModel, test_features_1);
[ConfusionMat, NBlabels] = confusionmat(labels(test_names), predictLabels);
disp(ConfusionMat);

%SVMModel = fitcnb(ranked_features_5, labels(entries_names), 'Distribution', 'kernel');
SVMModel = fitcecoc(ranked_features_5, labels(entries_names), 'Learners', t);
disp('USING 5%');
predictLabels = predict(SVMModel, test_features_5);
[ConfusionMat, NBlabels] = confusionmat(labels(test_names), predictLabels);
disp(ConfusionMat);

%SVMModel = fitcnb(ranked_features_10, labels(entries_names), 'Distribution', 'kernel');
SVMModel = fitcecoc(ranked_features_10, labels(entries_names), 'Learners', t);
disp('USING 10%');
predictLabels = predict(SVMModel, test_features_10);
[ConfusionMat, NBlabels] = confusionmat(labels(test_names), predictLabels);
disp(ConfusionMat);

%SVMModel = fitcnb(ranked_features_20, labels(entries_names), 'Distribution', 'kernel');
SVMModel = fitcecoc(ranked_features_20, labels(entries_names), 'Learners', t);
disp('USING 20%');
predictLabels = predict(SVMModel, test_features_20);
[ConfusionMat, NBlabels] = confusionmat(labels(test_names), predictLabels);
disp(ConfusionMat);

%SVMModel = fitcnb(ranked_features_30, labels(entries_names), 'Distribution', 'kernel');
SVMModel = fitcecoc(ranked_features_30, labels(entries_names), 'Learners', t);
disp('USING 30%');
predictLabels = predict(SVMModel, test_features_30);
[ConfusionMat, NBlabels] = confusionmat(labels(test_names), predictLabels);
disp(ConfusionMat);

%SVMModel = fitcnb(ranked_features_50, labels(entries_names), 'Distribution', 'kernel');
SVMModel = fitcecoc(ranked_features_50, labels(entries_names), 'Learners', t);
disp('USING 50%');
predictLabels = predict(SVMModel, test_features_50);
[ConfusionMat, NBlabels] = confusionmat(labels(test_names), predictLabels);
disp(ConfusionMat);

%SVMModel = fitcnb(ranked_features_60, labels(entries_names), 'Distribution', 'kernel');
SVMModel = fitcecoc(ranked_features_60, labels(entries_names), 'Learners', t);
disp('USING 60%');
predictLabels = predict(SVMModel, test_features_60);
[ConfusionMat, NBlabels] = confusionmat(labels(test_names), predictLabels);
disp(ConfusionMat);

%SVMModel = fitcnb(ranked_features_70, labels(entries_names), 'Distribution', 'kernel');
SVMModel = fitcecoc(ranked_features_70, labels(entries_names), 'Learners', t);
disp('USING 70%');
predictLabels = predict(SVMModel, test_features_70);
[ConfusionMat, NBlabels] = confusionmat(labels(test_names), predictLabels);
disp(ConfusionMat);

%SVMModel = fitcnb(ranked_features_80, labels(entries_names), 'Distribution', 'kernel');
SVMModel = fitcecoc(ranked_features_80, labels(entries_names), 'Learners', t);
disp('USING 80%');
predictLabels = predict(SVMModel, test_features_80);
[ConfusionMat, NBlabels] = confusionmat(labels(test_names), predictLabels);
disp(ConfusionMat);

%SVMModel = fitcnb(ranked_features_90, labels(entries_names), 'Distribution', 'kernel');
SVMModel = fitcecoc(ranked_features_90, labels(entries_names), 'Learners', t);
disp('USING 90%');
predictLabels = predict(SVMModel, test_features_90);
[ConfusionMat, NBlabels] = confusionmat(labels(test_names), predictLabels);
disp(ConfusionMat);

%SVMModel = fitcnb(ranked_features_100, labels(entries_names), 'Distribution', 'kernel');
SVMModel = fitcecoc(ranked_features_100, labels(entries_names), 'Learners', t);
disp('USING 100%');
predictLabels = predict(SVMModel, test_features_100);
[ConfusionMat, NBlabels] = confusionmat(labels(test_names), predictLabels);
disp(ConfusionMat);
disp(predictLabels);


%SVMModel = fitcnb(ranked_features_40, labels(entries_names), 'Distribution', 'kernel');
SVMModel = fitcecoc(ranked_features_40, labels(entries_names), 'Learners', t);
disp('USING 40%');
predictLabels = predict(SVMModel, test_features_40);
[ConfusionMat, NBlabels] = confusionmat(labels(test_names), predictLabels);
disp(ConfusionMat);
