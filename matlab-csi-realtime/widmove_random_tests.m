plotData = 0;
kfold_technique = 1;
labels = {};
labels(1,:) = {'Saiu'};
labels(2,:) = {'Entrou'};

% 57 11 54
% datasets_struct = {{'csi_data_bruno_w_', [1 76], 1} ...
%     {'csi_data_geovana_w_', [1 15], 2} ...
%     {'csi_data_vinicius_w_', [1 30], 3} ...
%     {'csi_data_phelipe_w_', [1 15], 4} ...
%     {'csi_data_josenilton_w_', [1 20], 5} ...
%     {'csi_data_luan_w_', [1 20], 6}  ...
%     {'csi_data_pablo_w_', [1 20], 7} ...
%     {'csi_data_marcelo_w_', [1 68], 8}};
datasets_struct = {{'csi_data_bruno_w_', [1 81], 1} ...
    {'csi_data_geovana_w_', [1 20], 2} ...
    {'csi_data_vinicius_w_', [1 35], 3} ...
    {'csi_data_phelipe_w_', [1 20], 4} ...
    {'csi_data_josenilton_w_', [1 25], 5} ...
    {'csi_data_luan_w_', [1 25], 6}  ...
    {'csi_data_pablo_w_', [1 25], 7} ...
    {'csi_data_marcelo_w_', [1 73], 8}};

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
    features = extract_widmove_features(dataset, 800);
    if(size(features, 1) ~= 2)
        disp(strcat('Test: ', datasets{1,i}, ' - ', num2str(size(features, 1))));
        continue;
    end
    out_features(i,:) = features(1,:);
    in_features(i,:) = features(2,:);
end

% Plot data if necessary
if(plotData == 1)
    figure;
    plot(out_features.');
    figure;
    plot(in_features.');
end

% Now execute tests
disp('Dataset features successfully loaded, executing test...');
t = templateSVM('Standardize', true, 'KernelFunction', 'rbf', ...
    'KernelScale','auto');
rng shuffle
all_set = cat(1, out_features, in_features);
all_features_len = size(all_set, 1);
all_labels = [];
all_labels(1:datasets_len, 1) = 1;
all_labels(datasets_len+1:datasets_len*2, 1) = 2;

if(kfold_technique == 0)
	n_tests = 50;
    %best_relieff = 100;
    accuracies = [];
    confusion_matrixes = [];
    train_percents = [1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100];
    qtd_of_predict = 25;
    for i=1:n_tests
        % Select a fixed quantity of random In/out samples to use in
        % predict phase
        predict_in_indexes = randperm(datasets_len, qtd_of_predict);
        predict_out_indexes = randperm(datasets_len, qtd_of_predict);
        predict_features = cat(1, out_features(predict_out_indexes,:), in_features(predict_in_indexes,:));
        predict_labels = [];
        predict_labels(1:qtd_of_predict, 1) = 1;
        predict_labels(qtd_of_predict+1:qtd_of_predict*2, 1) = 2;
        
        % Separate the other In/out samples
        train_in_indexes = setdiff(1:datasets_len, predict_in_indexes);
        train_out_indexes = setdiff(1:datasets_len, predict_out_indexes);
        train_out_features = out_features(train_out_indexes,:);
        train_in_features = in_features(train_in_indexes,:);
        train_size = length(train_out_indexes);
        % Shuffle the samples that will be used in train phase
        randomize = randperm(train_size, train_size);
        train_out_features = train_out_features(randomize, :);
        train_in_features = train_in_features(randomize, :);
        for j=1:length(train_percents)
            train_percent = train_percents(1,j);
            percent_size = floor(train_size*(train_percent/100));
            
            % Select the percent samples
            percent_features = cat(1, train_out_features(1:percent_size,:), train_in_features(1:percent_size,:));
            percent_labels = [];
            percent_labels(1:percent_size, 1) = 1;
            percent_labels(percent_size+1:percent_size*2, 1) = 2;
            percent_size = length(percent_labels);
            % Shuffle the vector that contains both In/Out samples
            randomize = randperm(percent_size, percent_size);
            percent_features = percent_features(randomize, :);
            percent_labels = percent_labels(randomize, :);

            % Get only best X% features
            % [ranked, weights] = relieff(percent_features, percent_labels, 5);
            % rank_train_f = percent_features(:, ranked(1:floor(length(ranked)*(best_relieff/100))));
            % rank_test_f = predict_features(:, ranked(1:floor(length(ranked)*(best_relieff/100))));

            disp(strcat('SVM MODEL (train/test): ', num2str(size(percent_features,1)), ...
                '/', num2str(size(predict_features,1))));
            SVMModel = fitcecoc(percent_features, labels(percent_labels), 'Learners', t);
            predictLabels = predict(SVMModel, predict_features);
            [ConfusionMat, NBlabels] = confusionmat(labels(predict_labels), predictLabels);
            n_success = ConfusionMat(1,1) + ConfusionMat(2,2);
            n_errors = ConfusionMat(1,2) + ConfusionMat(2,1);
            accuracy = n_success/sum(sum(ConfusionMat));
            accuracies(i,j) = accuracy;
            confusion_matrixes(j,i,:,:) = ConfusionMat;
            disp(strcat('Finished: ', num2str(i), '-', num2str(train_percent)));
        end
    end
    
    disp(mean(accuracies, 1));
    disp(std(accuracies, 0, 1));
    disp(squeeze(mean(confusion_matrixes(21,:,:,:),2)));
else
    % Create new random sequence if it not exists
    if(exist('randomize') == 0 || length(randomize) ~= all_features_len)
        disp('creating and saving a new random sequence...');
        randomize = randperm(all_features_len, all_features_len);
        save(strcat('random_sequence_for_', num2str(all_features_len), '_', ...
            datestr(now,'DD-mm-YY'), '.mat'), 'randomize');
    end
    % Randomize all set and your labels
    all_set = all_set(randomize, :);
    all_labels = all_labels(randomize, :);
    
    %logical_labels = strcmp(labels(all_labels), labels{1,:});

    [ranked, weights] = relieff(all_set, all_labels, 5);
    relieff_percents = [1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100];
    accuracies = [];
    accuracies_lOO = [];
    %figure;
    %hold on;
    for j=1:length(relieff_percents)
       rpercent = relieff_percents(1,j)/100;
       rank_all_set = all_set(:, ranked(1:floor(length(ranked)*rpercent)));

       if(j==100)
           SVMModel = fitcecoc(rank_all_set, labels(all_labels), 'Learners', t, ...
               'FitPosterior', 1, 'ClassNames', labels.');
       else
           SVMModel = fitcecoc(rank_all_set, labels(all_labels), 'Learners', t);
       end
       %SVMModel = fitcecoc(rank_all_set, labels(all_labels), 'Learners', t, ...
       %    'FitPosterior', 1, 'ClassNames', labels.');
       %SVMModel = fitcecoc(rank_all_set, logical_labels, 'Learners', t, ...
       %    'FitPosterior', 1);
       CVSVMModel = crossval(SVMModel);
       CVSVMModel_lOO = crossval(SVMModel, 'KFold', size(rank_all_set,1));
       accuracies(:,j) = kfoldLoss(CVSVMModel, 'mode', 'individual');
       accuracies_lOO(:,j) = kfoldLoss(CVSVMModel_lOO, 'mode', 'individual');

       % Create ROC curve
       %[~, score_svm] = resubPredict(SVMModel);
       %[Xsvm,Ysvm,Tsvm,AUCsvm] = perfcurve(logical_labels, score_svm(:, SVMModel.ClassNames), 'true');
       %plot(Xsvm,Ysvm);

       disp(strcat('Finished: ', num2str(rpercent)));
    end

    %xlabel('False positive rate'); ylabel('True positive rate');
    %title('ROC Curves for Logistic Regression, SVM, and Naive Bayes Classification');
    %hold off;

    disp('Kfold = 10:');
    disp(mean((1-accuracies), 1));
    disp(std((1-accuracies), 0, 1));

    disp('Leave One Out:');
    disp(mean((1-accuracies_lOO), 1));
    disp(std((1-accuracies_lOO), 0, 1));
end


