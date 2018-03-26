plotData = 1;
featureId = 2;
labels = {};
labels(1,:) = {'Bruno'};
labels(2,:) = {'Geovana'};
labels(3,:) = {'Vinicius'};
labels(4,:) = {'Phelipe'};
labels(5,:) = {'Josenilton'};
labels(6,:) = {'Luan'};
labels(7,:) = {'Pablo'};
labels(8,:) = {'Marcelo'};

% 57 11 54
% datasets_struct = {{'csi_data_bruno_w_', [57 81], 1} ...
%     {'csi_data_geovana_w_', [1 20], 2} ...
%     {'csi_data_vinicius_w_', [11 35], 3} ...
%     {'csi_data_phelipe_w_', [1 20], 4} ...
%     {'csi_data_josenilton_w_', [1 25], 5} ...
%     {'csi_data_marcelo_w_', [54 73], 6}};

% {'csi_data_luan_w_', [1 25], 6} ...
% {'csi_data_pablo_w_', [1 25], 7} ...

datasets_struct = {{'csi_data_bruno_w_', [57 58], 1} ...
    {'csi_data_geovana_w_', [1 2], 2} ...
    {'csi_data_vinicius_w_', [11 12], 3} ...
    {'csi_data_phelipe_w_', [1 2], 4} ...
    {'csi_data_josenilton_w_', [1 2], 5} ...
    {'csi_data_marcelo_w_', [54 55], 8}};
    
datasets = {};
labels_indexes = [];
for i=1:length(datasets_struct)
    x = datasets_struct{1,i};
    pattern = x{1,1};
    indexes = x{1,2};
    label_id = x{1,3};
    for j=indexes(1,1):indexes(1,2)
        datasets = [datasets strcat(pattern, num2str(j))];
        labels_indexes(end+1,1) = x{1,3};
    end
end

% Calcule features for all samples
datasets_len = size(datasets,2);
all_set = [];
last = 0;
%if(size(out_features, 1) ~= datasets_len)
    for i=1:datasets_len
        if(exist(datasets{1,i}) == 0) 
            splited_var = strsplit(datasets{1,i}, '_');
            fileName = strcat('/home/bruno/gait_bruno_tests/gait_tests_', splited_var(1,3), '_dataset.mat');
            load(fileName{:});
            
            lastTraceNum = str2num(splited_var{1,5})-1;
            for l=1:lastTraceNum
                removeVar = strcat('csi_data_', splited_var(1,3), '_w_', num2str(l));
                clear(removeVar{1,1});
            end
        end
        dataset = eval(datasets{1,i});
        clear(datasets{1,i});
        disp(strcat('Extracting: ', datasets{1,i}));
        [features, ~, ~, ~, pca] = extract_gait_features(dataset, 800);
        all_set(i,:) = features(featureId,:);

        % Plot features;
        if(plotData == 1)
            actual = labels_indexes(i,1);
            if(actual ~= last)
                figure;
                hold on;
            end
            last = actual;
            
            plot(features(featureId,:));
        end
    
        if(size(features, 1) ~= 2)
            disp(strcat('Error Test: ', datasets{1,i}, ' - ', num2str(size(features, 1))));
        end
    end
%end

% Now execute tests
disp('Dataset features successfully loaded, executing test...');
t = templateSVM('Standardize', true, 'KernelFunction', 'rbf', ...
    'KernelScale','auto');
rng shuffle
% n_tests = 50;
% best_relieff = 100;
% accuracies = [];
% confusion_matrixes = [];
% train_percents = [1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 99];
% train_percents = [50];
% for i=1:n_tests
%    for j=1:length(train_percents)
%        train_percent = train_percents(1,j);
%        train_size = floor(datasets_len*(train_percent/100));
%        random_train = randperm(datasets_len, train_size);
%        random_tests = setdiff(1:datasets_len, random_train);
%        test_size = size(random_tests, 2);
% 
%        train_set = cat(1, out_features(random_train,:), in_features(random_train, :));
%        train_labels = [];
%        train_labels(1:train_size, 1) = 1;
%        train_labels(train_size+1:(train_size*2), 1) = 2;
% 
%        test_set = cat(1, out_features(random_tests,:), in_features(random_tests, :));
%        test_labels = [];
%        test_labels(1:test_size, 1) = 1;
%        test_labels(test_size+1:(test_size*2), 1) = 2;
% 
%        [ranked, weights] = relieff(train_set, train_labels, 5);
%        rank_train_f = train_set(:, ranked(1:floor(length(ranked)*(best_relieff/100))));
%        rank_test_f = test_set(:, ranked(1:floor(length(ranked)*(best_relieff/100))));
% 
%        SVMModel = fitcecoc(rank_train_f, labels(train_labels), 'Learners', t);
%        predictLabels = predict(SVMModel, rank_test_f);
%        [ConfusionMat, NBlabels] = confusionmat(labels(test_labels), predictLabels);
%        n_success = ConfusionMat(1,1) + ConfusionMat(2,2);
%        n_errors = ConfusionMat(1,2) + ConfusionMat(2,1);
%        accuracy = n_success/sum(sum(ConfusionMat));
%        accuracies(i,j) = accuracy;
%        confusion_matrixes(j,i,:,:) = ConfusionMat;
%        disp(strcat('Finished: ', num2str(i), '-', num2str(train_percent)));
%    end
% end
% 
% %disp(size(accuracies));
% %disp(accuracies);
% disp(mean(accuracies, 1));
% disp(std(accuracies, 0, 1));
% 
% conf_data = squeeze(mean(confusion_matrixes(1,:,:,:),2));
% disp(conf_data);
% 
% return;

[ranked, weights] = relieff(all_set, labels_indexes, 5);
relieff_percents = [1 10 20 30 40 50 60 70 80 90 95 100];
relieff_percents = 1:100;
relieff_percents = [1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 99];
relieff_percents = [30 40 80 90 100];
relieff_percents = [40 100];
accuracies = [];
accuracies_lOO = [];
for j=1:length(relieff_percents)
   rpercent = relieff_percents(1,j)/100;
   rank_all_set = all_set(:, ranked(1:floor(length(ranked)*rpercent)));

   SVMModel = fitcecoc(rank_all_set, labels(labels_indexes), 'Learners', t);
   CVSVMModel = crossval(SVMModel);
   CVSVMModel_lOO = crossval(SVMModel, 'KFold', size(rank_all_set,1));
%    accuracies(:,j) = (1-kfoldLoss(CVSVMModel, 'mode', 'individual'))*100;
%    accuracies_lOO(:,j) = (1-kfoldLoss(CVSVMModel_lOO, 'mode', 'individual'))*100;
   accuracies(:,j) = kfoldLoss(CVSVMModel, 'mode', 'individual');
   accuracies_lOO(:,j) = kfoldLoss(CVSVMModel_lOO, 'mode', 'individual');
   
   disp(strcat('Finished: ', num2str(rpercent)));
end

disp(size(all_set)); 
disp('Kfold = 10:');
disp(mean((1-accuracies), 1));
disp(std((1-accuracies), 0, 1));
 
disp('Leave One Out:');
disp(mean((1-accuracies_lOO), 1));
disp(std((1-accuracies_lOO), 0, 1));

% figure;
% errorbar(1-mean(accuracies, 1), std(accuracies, 0, 1));
% figure;
% errorbar(1-mean(accuracies_lOO, 1), std(accuracies_lOO, 0, 1));
% exit;
