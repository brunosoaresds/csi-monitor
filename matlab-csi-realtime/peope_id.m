datasets_struct = {{'csi_data_top_bruno_', [1 3], 1} ...
    {'csi_data_top_phelipe_', [1 3], 2}};

datasets_struct = {{'csi_data_top_phelipe_', [1 1], 1}};

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
for i=1:datasets_len
    dataset = eval(datasets{1,i});
    
    csi_mimo = size(dataset, 2);
    all_csi_streams = [];
    for j=1:csi_mimo
        csi_data = dataset{1,j};
        all_csi_streams = cat(2, all_csi_streams, csi_data.');
        %pca_comps = filter_csi_with_pca(csi_data.', 6, 0);
        %figure;
        %cwt(pca_comps(:,1:1), 'amor', 800);
    end
    
    pca_comps = filter_csi_with_pca(all_csi_streams, 6, 0);
    
    
    
    
    
%     figure;
%     plot(pca_comps(:,1:6));
%     figure;
%     cwt(pca_comps(:,1), 'amor', 800);
%     figure;
%     cwt(pca_comps(:,2), 'amor', 800);
%     figure;
%     cwt(pca_comps(:,3), 'amor', 800);
%     figure;
%     cwt(pca_comps(:,4), 'amor', 800);
%     figure;
%     cwt(pca_comps(:,5), 'amor', 800);
%     figure;
%     cwt(pca_comps(:,6), 'amor', 800);
    
%     clear(datasets{1,i});
%     features = extract_widmove_features(dataset, 800);
%     if(size(features, 1) ~= 2)
%         disp(strcat('Test: ', datasets{1,i}, ' - ', num2str(size(features, 1))));
%         continue;
%     end
%     out_features(i,:) = features(1,:);
%     in_features(i,:) = features(2,:);
end