function data = get_csi_streams(csi, rx, tx)
    count = size(csi);
    for i=1:count(1,1)
        actual_csi = csi{i,1};
        csi_matrix = squeeze(actual_csi.csi(rx,tx,:));
        data(:,i) = csi_matrix;
    end
end