
labels = {};
labels(1,:) = {'Bruno'};
labels(2,:) = {'Phelipe'};
%labels(3,:) = {'Geovana'};
%labels(4,:) = {'Marcelo'};

entries_names = [];
entries_names(1:5,1) = 1;
entries_names(6:10,1) = 2;
%entries_names(3,1) = 3;
%entries_names(4,1) = 4;

classifier_data = [];
[x ~] = second_variance(csi_data_bruno_1, 800);
classifier_data(1,:) = extract_features(x.slice_1, 800);
%figure;
%plot(classifier_data(1,:));
[x ~] = second_variance(csi_data_bruno_2, 800);
classifier_data(2,:) = extract_features(x.slice_1, 800);
%figure;
%plot(classifier_data(2,:));
[x ~] = second_variance(csi_data_bruno_3, 800);
classifier_data(3,:) = extract_features(x.slice_1, 800);
%figure;
%plot(classifier_data(3,:));
[x ~] = second_variance(csi_data_bruno_4, 800);
classifier_data(4,:) = extract_features(x.slice_1, 800);
%figure;
%plot(classifier_data(4,:));
[x ~] = second_variance(csi_data_bruno_5, 800);
classifier_data(5,:) = extract_features(x.slice_1, 800);
%figure;
%plot(classifier_data(5,:));

[x ~] = second_variance(csi_data_phelipe_1, 800);
classifier_data(6,:) = extract_features(x.slice_1, 800);
%figure;
%plot(classifier_data(6,:));
[x ~] = second_variance(csi_data_phelipe_2, 800);
classifier_data(7,:) = extract_features(x.slice_1, 800);
%figure;
%plot(classifier_data(7,:));
[x ~] = second_variance(csi_data_phelipe_3, 800);
classifier_data(8,:) = extract_features(x.slice_1, 800);
%figure;
%plot(classifier_data(8,:));
[x ~] = second_variance(csi_data_phelipe_4, 800);
classifier_data(9,:) = extract_features(x.slice_1, 800);
%figure;
%plot(classifier_data(9,:));
[x ~] = second_variance(csi_data_phelipe_5, 800);
classifier_data(10,:) = extract_features(x.slice_1, 800);
%figure;
%plot(classifier_data(10,:));

%SVMModel = fitcsvm(classifier_data,entries_names,'KernelFunction','linear','Standardize',true);

test_set = [];
[x ~] = second_variance(csi_test_bruno_1, 800);
test_set(1,:) = extract_features(x.slice_1, 800);
[x ~] = second_variance(csi_test_phelipe_1, 800);
test_set(2,:) = extract_features(x.slice_1, 800);
[x ~] = second_variance(csi_test_bruno_2, 800);
test_set(3,:) = extract_features(x.slice_1, 800);

% Multi SVM
results = multisvm(classifier_data, entries_names, test_set); 
disp('multi class problem'); 
disp(labels(results));

% NAIVE BAYES
% entries_names = labels(entries_names);
% NBModel1 = fitNaiveBayes(classifier_data, entries_names, 'Distribution', 'kernel');
% NBModel1.ClassLevels
% 
% %Predict the trained data
% predictLabels1 = predict(NBModel1, test_set);
% %[ConfusionMat1, NBlabels] = confusionmat(entries_names, predictLabels1);
% disp(predictLabels1);

% data = importdata('environment_test.mat');
% 
% % Separate data over multiples 6 seconds
% dataLabels = fieldnames(data);
% secs = 6;
% pkts_sec = 725;
% trace_pkts = secs*pkts_sec;
% 
% labels = {};
% testLabels = {};
% classifierData = [];
% testData = [];
% for k=1:length(dataLabels)
%     dataChildName = dataLabels{k};
%     dataChild = getfield(data, dataChildName);
%     
%     n_traces = floor(size(dataChild, 2) / trace_pkts);
%     x = [];
%     for(i=1:n_traces)
%         startTrace = ((i-1)*trace_pkts)+1;
%         endTrace = i*trace_pkts;
%         x(i,:,:) = dataChild(:, startTrace:endTrace);
%     end
%     
%     classifierData = cat(1, classifierData, x(1:50,:,:));
%     testData = cat(1, testData, x(51:55,:,:));
%     % assignin('base', dataChildName, x);
%     
%     % Populate Labels
%     startLabel = size(labels, 1);
%     labels(startLabel+1:startLabel+50, :) = {dataChildName};
%     
%     startTestLabel = size(testLabels, 1);
%     testLabels(startTestLabel+1:startTestLabel+5, :) = {dataChildName};
% end
% 
% clear dataChild dataChildName endTrace startTrace startLabel x i k n_traces data
% 
% % Create feature vector
% featureVector = [];
% for i=1:size(classifierData,1)
%     traceData = squeeze(abs(classifierData(i,:,:)));
%     featureVector(i,:) = extract_features(traceData);
% end
% 
% % Create Naive Bayes classifier
% NBModel1 = fitNaiveBayes(featureVector, labels, 'Distribution', 'kernel');
% NBModel1.ClassLevels
% 
% %Predict the trained data
% predictLabels1 = predict(NBModel1, featureVector);
% [ConfusionMat1, NBlabels] = confusionmat(labels, predictLabels1);
% disp(ConfusionMat1);
% 
% 
% % Create feature vector of test data
% testFv = [];
% for i=1:size(testData, 1)
%     traceData = squeeze(abs(testData(i,:,:)));
%     testFv(i,:) = extract_features(traceData);
% end
% 
% % Predict new set of data
% ptest = predict(NBModel1, testFv);
% [ConfusionMatTest, NBlabelsTest] = confusionmat(testLabels, ptest);
% disp(ConfusionMatTest);