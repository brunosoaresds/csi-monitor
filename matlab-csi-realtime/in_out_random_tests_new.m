useCwt = 1;
plotData = 1;
labels = {};
labels(1,:) = {'Saiu'};
labels(2,:) = {'Entrou'};
labels(3,:) = {'Sem Movimento'};
datasets_len = size(datasets,2);

% in_features = [];
% out_features = [];
% none_features = [];
% for i=1:datasets_len
%     if(exist(datasets{1,i}) == 0) 
%         splited_var = strsplit(datasets{1,i}, '_');
%         fileName = strcat('/home/bruno/gait_bruno_tests/gait_tests_', splited_var(1,3), '_dataset.mat');
%         load(fileName{:});
%     end
%     dataset = eval(datasets{1,i});
%     clear(datasets{1,i});
%     features = extract_gait_features_new(dataset, datasets_events_indexes{1, i}, 800, useCwt);
%     if(size(features, 1) ~= 3)
%         disp(strcat('Test: ', datasets{1,i}, ' - ', num2str(size(features, 1))));
%         continue;
%     end
%     out_features(i,:) = features(1,:);
%     in_features(i,:) = features(2,:);
%     none_features(i,:) = features(3,:);
%     disp(strcat(datasets{1,i}, ' - processed...'));
% end
% 
% % Plot data if necessary
% if(plotData == 1)
%     figure;
%     plot(out_features.');
%     if(useCwt == 0)
%         title('STFT OUT features');
%     else
%         title('CWT OUT features');
%     end
%     figure;
%     plot(in_features.');
%     if(useCwt == 0)
%         title('STFT IN features');
%     else
%         title('CWT IN features');
%     end
%     figure;
%     plot(none_features.');
%     if(useCwt == 0)
%         title('STFT NONE features');
%     else
%         title('CWT NONE features');
%     end
% end


%Now execute tests
disp('Dataset features successfully loaded, executing test...');
t = templateSVM('Standardize', true, 'KernelFunction', 'rbf', ...
    'KernelScale','auto');
rng shuffle
n_tests = 30;
%best_relieff = 100;
accuracies = [];
confusion_matrixes = [];
train_percents = [1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 99];
train_percents = [99];
for i=1:n_tests
  for j=1:length(train_percents)
      train_percent = train_percents(1,j);
      train_size = floor(datasets_len*(train_percent/100));
      random_train = randperm(datasets_len, train_size);
      random_tests = setdiff(1:datasets_len, random_train);
      test_size = size(random_tests, 2);

      train_set = cat(1, out_features(random_train,:), in_features(random_train, :), ...
          none_features(random_train, :));
      train_labels = [];
      train_labels(1:train_size, 1) = 1;
      train_labels(train_size+1:(train_size*2), 1) = 2;
      train_labels(((train_size*2)+1):(train_size*3), 1) = 3;

      test_set = cat(1, out_features(random_tests,:), in_features(random_tests, :), ...
          none_features(random_tests, :));
      test_labels = [];
      test_labels(1:test_size, 1) = 1;
      test_labels(test_size+1:(test_size*2), 1) = 2;
      test_labels(((test_size*2)+1):(test_size*3), 1) = 3;

%      [ranked, weights] = relieff(train_set, train_labels, 5);
%      rank_train_f = train_set(:, ranked(1:floor(length(ranked)*(best_relieff/100))));
%      rank_test_f = test_set(:, ranked(1:floor(length(ranked)*(best_relieff/100))));

      [coeff, scores, latent] = pca(train_set);
      rel = latent/sum(latent);
      sum_rel = 0;
      n_best_features = 0;
      for pca_s=1:length(rel)
          if sum_rel >= 0.99
              sum_rel = 0;
              n_best_features = pca_s;
          end
          sum_rel = sum_rel + rel(pca_s,1);
      end
      rank_train_f = train_set*coeff(:,1:n_best_features);
      rank_test_f = test_set*coeff(:,1:n_best_features);
      
      rank_train_f = train_set;
      rank_test_f = test_set;

      SVMModel = fitcecoc(rank_train_f, labels(train_labels), 'Learners', t);
      predictLabels = predict(SVMModel, rank_test_f);
      [ConfusionMat, NBlabels] = confusionmat(labels(test_labels), predictLabels);
      
      % Compute accertiveness.
      n_success = 0;
      n_errors = 0;
      for k=1:size(ConfusionMat,1)
          for l=1:size(ConfusionMat,2)
              if k==l
                  n_success = n_success + ConfusionMat(k,l);
              else
                  n_errors = n_errors + ConfusionMat(k,l);
              end
          end
      end
      accuracy = n_success/sum(sum(ConfusionMat));
      accuracies(i,j) = accuracy;
      confusion_matrixes(j,i,:,:) = ConfusionMat;
      disp(strcat('Finished: ', num2str(i), '-', num2str(train_percent)));
  end
end

% disp(size(accuracies));
% disp(accuracies);
disp(mean(accuracies, 1));
% disp(std(accuracies, 0, 1));
% 
squeeze(mean(confusion_matrixes(1,:,:,:),2))

return;

all_set = cat(1, out_features, in_features);
all_features_len = size(all_set, 1);
features_len = size(out_features, 1);
all_labels = [];
all_labels(1:features_len, 1) = 1;
all_labels(features_len+1:features_len*2, 1) = 2;

% Randomize all set and your labels
if(exist('randomize') == 0 || length(randomize) ~= all_features_len)
    % Create new random sequence if it not exists
    disp('creating and saving a new random sequence...');
    randomize = randperm(all_features_len, all_features_len);
    save(strcat('random_sequence_for_', num2str(all_features_len), '_', ...
        datestr(now,'DD-mm-YY'), '.mat'), 'randomize');
end
all_set = all_set(randomize, :);
all_labels = all_labels(randomize, :);
logical_labels = strcmp(labels(all_labels), labels{1,:});

[ranked, weights] = relieff(all_set, logical_labels, 5);
% relieff_percents = [1 10 20 30 40 50 60 70 80 90 95 100];
% relieff_percents = 1:100;
relieff_percents = [1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 99];
relieff_percents = [100];
accuracies = [];
accuracies_lOO = [];
% figure;
% hold on;
for j=1:length(relieff_percents)
   rpercent = relieff_percents(1,j)/100;
   rank_all_set = all_set(:, ranked(1:floor(length(ranked)*rpercent)));

   %SVMModel = fitcecoc(rank_all_set, labels(all_labels), 'Learners', t, ...
   %    'FitPosterior', 1, 'ClassNames', labels.');
   SVMModel = fitcecoc(rank_all_set, logical_labels, 'Learners', t);
   CVSVMModel = crossval(SVMModel);
   CVSVMModel_lOO = crossval(SVMModel, 'KFold', size(rank_all_set,1));
   accuracies(:,j) = kfoldLoss(CVSVMModel, 'mode', 'individual');
   accuracies_lOO(:,j) = kfoldLoss(CVSVMModel_lOO, 'mode', 'individual');
   
%    % Create ROC curve
%    [~, score_svm] = resubPredict(SVMModel);
%    [Xsvm,Ysvm,Tsvm,AUCsvm] = perfcurve(logical_labels, score_svm(:, SVMModel.ClassNames), 'true');
%    plot(Xsvm,Ysvm);
   
   disp(strcat('Finished: ', num2str(rpercent)));
end

% xlabel('False positive rate'); ylabel('True positive rate');
% title('ROC Curves for Logistic Regression, SVM, and Naive Bayes Classification');
% hold off;
   
%disp(size(all_set)); 
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
