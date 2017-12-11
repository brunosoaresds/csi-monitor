plotData = 0;
labels = {};
labels(1,:) = {'Saiu'};
labels(2,:) = {'Entrou'};

% 57 11 54
datasets_struct = {{'csi_data_bruno_w_', [1 76], 1} ...
    {'csi_data_geovana_w_', [1 15], 2} ...
    {'csi_data_vinicius_w_', [1 30], 3} ...
    {'csi_data_phelipe_w_', [1 15], 4} ...
    {'csi_data_josenilton_w_', [1 20], 5} ...
    {'csi_data_luan_w_', [1 20], 6}  ...
    {'csi_data_pablo_w_', [1 20], 7} ...
    {'csi_data_marcelo_w_', [1 68], 8}};
datasets = {};
labels_indexes = [];
for i=1:length(datasets_struct)
    x = datasets_struct{1,i};
    pattern = x{1,1};
    indexes = x{1,2};
    for j=indexes(1,1):indexes(1,2)
        datasets = [datasets strcat(pattern, num2str(j))];
        labels_indexes(end+1,1) = x{1,3};
    end
end

% Calcule features for all samples
datasets_len = size(datasets,2);
%if(size(out_features, 1) ~= datasets_len)
    in_features = [];
    out_features = [];
    for i=1:datasets_len
        if(exist(datasets{1,i}) == 0) 
            splited_var = strsplit(datasets{1,i}, '_');
            fileName = strcat('/home/bruno/gait_bruno_tests/gait_tests_', splited_var(1,3), '_dataset.mat');
            load(fileName{:});
        end
        dataset = eval(datasets{1,i});
        clear(datasets{1,i});
        features = extract_gait_features(dataset, 800);
        out_features(i,:) = features(1,:);
        in_features(i,:) = features(2,:);
        if(size(features, 1) ~= 2)
            disp(strcat('Test: ', datasets{1,i}, ' - ', num2str(size(features, 1))));
        end
    end
%end

% Now execute tests
disp('Dataset features successfully loaded, executing test...');
t = templateSVM('Standardize', true, 'KernelFunction', 'rbf', ...
    'KernelScale','auto');
% rng shuffle
% n_tests = 50;
% relieff_percents = [30 40 50 60 70 80 90 100];
% accuracies = [];
% for i=1:n_tests
%    train_size = floor(datasets_len*0.90);
%    random_train = randperm(datasets_len, train_size);
%    random_tests = setdiff(1:datasets_len, random_train);
%    test_size = size(random_tests, 2);
% 
%    train_set = cat(1, out_features(random_train,:), in_features(random_train, :));
%    train_labels = [];
%    train_labels(1:train_size, 1) = 1;
%    train_labels(train_size+1:(train_size*2), 1) = 2;
% 
%    test_set = cat(1, out_features(random_tests,:), in_features(random_tests, :));
%    test_labels = [];
%    test_labels(1:test_size, 1) = 1;
%    test_labels(test_size+1:(test_size*2), 1) = 2;
% 
%    [ranked, weights] = relieff(train_set, train_labels, 5);
%    for j=1:length(relieff_percents)
%        rpercent = relieff_percents(1,j)/100;
%        %disp(strcat('Calculating relieff for: ', num2str(rpercent)));
%        rank_train_f = train_set(:, ranked(1:floor(length(ranked)*rpercent)));
%        rank_test_f = test_set(:, ranked(1:floor(length(ranked)*rpercent)));
% 
%        SVMModel = fitcecoc(rank_train_f, labels(train_labels), 'Learners', t);
%        predictLabels = predict(SVMModel, rank_test_f);
%        [ConfusionMat, NBlabels] = confusionmat(labels(test_labels), predictLabels);
%        %disp(ConfusionMat);
%        %disp(predictLabels);
%        n_success = ConfusionMat(1,1) + ConfusionMat(2,2);
%        n_errors = ConfusionMat(1,2) + ConfusionMat(2,1);
%        accuracy = n_success/sum(sum(ConfusionMat));
%        accuracies(i,j) = accuracy;
%    end
% end
% 
% %disp(size(accuracies));
% %disp(accuracies);
% disp(mean(accuracies, 1));
% disp(std(accuracies, 0, 1));

all_set = cat(1, out_features, in_features);
features_len = size(out_features, 1);
all_labels = [];
all_labels(1:features_len, 1) = 1;
all_labels(features_len+1:features_len*2, 1) = 2;

[ranked, weights] = relieff(all_set, all_labels, 5);
relieff_percents = [1 10 20 30 40 50 60 70 80 90 95 100];
relieff_percents = 1:100;
accuracies = [];
accuracies_lOO = [];
for j=1:length(relieff_percents)
   rpercent = relieff_percents(1,j)/100;
   rank_all_set = all_set(:, ranked(1:floor(length(ranked)*rpercent)));

   SVMModel = fitcecoc(rank_all_set, labels(all_labels), 'Learners', t);
   CVSVMModel = crossval(SVMModel);
   CVSVMModel_lOO = crossval(SVMModel, 'KFold', size(rank_all_set,1));
   accuracies(:,j) = kfoldLoss(CVSVMModel, 'mode', 'individual');
   accuracies_lOO(:,j) = kfoldLoss(CVSVMModel_lOO, 'mode', 'individual');
end

disp('Kfold = 10:');
disp(mean(accuracies, 1));
disp(std(accuracies, 0, 1));

disp('Leave One Out:');
disp(mean(accuracies_lOO, 1));
disp(std(accuracies_lOO, 0, 1));

figure;
errorbar(1-mean(accuracies, 1), std(accuracies, 0, 1));
figure;
errorbar(1-mean(accuracies_lOO, 1), std(accuracies_lOO, 0, 1));
% exit;
