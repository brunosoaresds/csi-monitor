% Test configuration
% activation_functions = {'compet', 'elliotsig', 'hardlim', 'hardlims', ...
%     'logsig', 'netinv', 'poslin', 'purelin', 'radbas', 'radbasn', ...
%     'satlin', 'satlins', 'softmax', 'tansig', 'tribas'};
activation_functions = {'compet', 'logsig', 'radbas', 'radbasn', ...
    'softmax', 'tansig'};
tests_by_neurons_count = 50;
test_samples_by_class = 50;
neurons_count = [10,50:50:1000];
layers_count = 1;
scores = zeros(layers_count, length(activation_functions), length(neurons_count), tests_by_neurons_count);
models = cell(layers_count, length(activation_functions), length(neurons_count));
best_layer_config = zeros(layers_count, 2);
best_score = 0;

% Start test...
for l=1:layers_count
    disp(strcat('Starting layer: ', num2str(l)));
    for af=1:length(activation_functions)
        useAf = activation_functions{af};
        disp(strcat('Starting AF: ', useAf));
        for n=1:length(neurons_count)
            actHiddenLayerSize = neurons_count(n);
            disp(strcat('Starting Neurons count: ', num2str(actHiddenLayerSize)));
            layers = cat(2, best_layer_config(1:l-1, 1).', ...
                actHiddenLayerSize);
            
            %net = patternnet(layers);
            %traingdm or trainlm or trainscg
            net = fitnet(layers, 'trainscg'); % https://www.mathworks.com/help/nnet/ref/fitnet.html#bu2w2vc-1-trainFcn

            for ltf=1:l-1
                net.layers{ltf}.transferFcn = ...
                    activation_functions{best_layer_config(ltf, 2)};
            end
            net.layers{l}.transferFcn = useAf;
            
            net.divideParam.trainRatio = 0.8;
            net.divideParam.valRatio = 0.2;
            net.divideParam.testRatio = 0;
            net.trainparam.epochs = 10000;
            net.trainParam.lr = 0.0001;
            net.trainParam.showWindow = false;

            models{l,af,n} = net;
%             valid_scores = zeros(1, tests_by_neurons_count); % comment after
            for t=1:tests_by_neurons_count
                [trainX, trainY, testX, testY] = generate_testset( ...
                    in_features, out_features, none_features, ...
                    test_samples_by_class);
                
                [tnet, tr] = train(net, trainX, trainY);

                p = tnet(testX);
                [~, p] = max(p);
                [~, testYMax] = max(testY);
                scores(l,af,n,t) = sum(testYMax == p) / length(testYMax);
%                 valid_scores(1, t) = sum(testYMax == p) / length(testYMax); % comment after
                if(scores(l,af,n,t) > best_score)
%                 if(valid_scores(1, t) > best_score) % comment after
                    best_score = scores(l,af,n,t);
%                     best_score = valid_scores(1, t); % comment after
                    best_model = tnet;
                end
                disp(['Done test: ', num2str(t)]);
            end
            
            disp(strcat('Done Neurons count: ', num2str(actHiddenLayerSize)));
        end
        disp(strcat('Done AF: ', useAf));
    end
    layer_scores = squeeze(scores(l,:,:,:));
    layer_scores_mean = mean(layer_scores, 3);
    [maxNVal, maxN] = max(layer_scores_mean, [], 2);
    [~, maxAfI] = max(maxNVal);
    maxNI = maxN(maxAfI,1);
    best_layer_config(l,1) = neurons_count(1, maxNI);
    best_layer_config(l,2) = maxAfI;
    disp(strcat('Done layer: ', num2str(l), ' - Best config: ', ...
        activation_functions{maxAfI}, ' / ', ...
        num2str(best_layer_config(l,1))));
end


function [trainX, trainY, testX, testY] = generate_testset(in_features, out_features, none_features, train_qtd, randomize)
    % Create vector with all set
    all_set = cat(1, out_features, in_features, none_features);
    all_features_len = size(all_set, 1);
    features_len = size(out_features, 1);
    all_labels = [];
    all_labels(1:features_len, 1) = 1;
    all_labels(features_len+1:features_len*2, 1) = 2;
    all_labels((features_len*2)+1:features_len*3, 1) = 3;
    
    % generate randomization of it not exists
    if nargin < 5
        rng shuffle
        randomize = randperm(all_features_len, all_features_len);
    end

    % suffle all_set
    all_set = all_set(randomize, :).';
    all_labels = all_labels(randomize, :).';

    % create onehotencoding
    targets = zeros(3, all_features_len);
    for i=1:all_features_len
        targets(all_labels(1,i), i) = 1;
    end

    % Separate train and test set
    all_set_size = size(all_set, 2);
    [~, testOut] = find(all_labels == 1);
    [~, testIn] = find(all_labels == 2);
    [~, testNone] = find(all_labels == 3);
    allTestIndexes = sort(cat(2, testOut(1, 1:train_qtd), testIn(1, 1:train_qtd), ...
        testNone(1, 1:train_qtd)));
    allTrainIndexes = setdiff(1:all_set_size, allTestIndexes);
    trainX = all_set(:, allTrainIndexes);
    trainY = targets(:, allTrainIndexes);
    testX = all_set(:, allTestIndexes);
    testY = targets(:, allTestIndexes);
end
