% csi, rx, tx
function rx_tx_datas = get_csi_streams(csi)
    %csi = evalin('base', 'csi');
    
    % Initialize the cells
    rx_tx_datas = {};
    for i=1:9
        rx_tx_datas{1,i} = [];
    end
    
    count = size(csi, 1);
    for i=1:count
        actual_csi = csi{i,1};
        for j=1:actual_csi.nr
            for k=1:actual_csi.nc
                cell_index = ((j-1)*3)+k;
                rx_tx_datas{1,cell_index} = [rx_tx_datas{1,cell_index} squeeze(actual_csi.csi(j,k,:))];
            end
        end
    end
end