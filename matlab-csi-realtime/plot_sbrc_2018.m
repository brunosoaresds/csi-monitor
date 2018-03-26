if(exist('csi_data_bruno_w_70'))
    [~, ~, ~, spectrogram] = extract_gait_features(csi_data_bruno_w_70, 800);
end

% Plot in/out spectrograms
enable = 0;
if(enable == 1)
    events_plot = {{'out_event', 79:100} {'in_event', 190:215}};
    for i=1:length(events_plot)
        event = events_plot{1,i};
        event_name = event{1,1};
        event_in_time = event{1,2};

        time_indexes = event_in_time;
        time_indexes = spectrogram.time(1, time_indexes);
        time_indexes = time_indexes - time_indexes(1,1) + spectrogram.time(1,1);
        stft_data = imgaussfilt(spectrogram.stft(:, event_in_time), 0.8, 'FilterSize', 5);

        fig_obj = figure;
        imagesc(time_indexes, spectrogram.frequency, stft_data);
        set(gca,'YDir','normal');
        set(gca,'FontSize', 30);
        ylabel('Frequency (Hz)');
        xlabel('Time (s)');

        filename = strcat('/home/bruno/spectrogram_no_border_', event_name, '.eps');
        set(gcf,'units','points','position',[10,10,500,900]);
        print(filename, '-depsc', '-r0');
        close(fig_obj);
    end
end

% Plot Signals with different filters
enable=0;
if(enable == 1)
    event_in = csi_data_bruno_w_70(:,19694:21311);
    event_out = csi_data_bruno_w_70(:,7978:9696);
    events_plot = {{'out_event', event_out} {'in_event', event_in}};
    for i=1:length(events_plot)
        event = events_plot{1,i};
        event_name = event{1,1};
        event_csi = event{1,2};

        csi_mag = abs(event_csi);
        nons_csi = (csi_mag - mean(csi_mag, 2)).';
        coeff= pca(nons_csi);
        pca_comp = nons_csi*coeff(:,2);
        pca_comp(622:626,1) = pca_comp(621,1);

        [b,a] = butter(9,150/(800/2));
        butter_filter = filter(b, a, csi_mag(1,:));
        
        % Plot figures
        plot_ylim = [min([min(csi_mag(1,:)) min(butter_filter)]) ...
            max([max(csi_mag(1,:)) max(butter_filter)])];
        
        total_packets = size(csi_mag,2);
        seconds = total_packets/800;
        xplot = linspace(0, seconds, total_packets);

        fig_obj = figure;
        plot(xplot, csi_mag(1,:));
        ylabel('Amplitude');
        xlabel('Time (s)');
        xlim([xplot(1,1) xplot(end,end)]);
        ylim(plot_ylim);
        set(gca,'FontSize', 25);
        
        set(gcf,'units','points','position',[10,10,500,400]);
        filename = strcat('/home/bruno/', event_name, '_no_filter.eps');
        print(filename, '-depsc', '-r0');
        close(fig_obj);

        fig_obj = figure;
        plot(xplot, butter_filter);
        ylabel('Amplitude');
        xlabel('Time (s)');
        xlim([xplot(1,1) xplot(end,end)]);
        ylim(plot_ylim);
        set(gca,'FontSize', 25);
        
        set(gcf,'units','points','position',[10,10,500,400]);
        filename = strcat('/home/bruno/', event_name, '_butter_filter.eps');
        print(filename, '-depsc', '-r0');
        close(fig_obj);

        fig_obj = figure;
        plot(xplot, pca_comp);
        ylabel('Amplitude');
        xlabel('Time (s)');
        xlim([xplot(1,1) xplot(end,end)]);
        set(gca,'FontSize', 25);
        
        set(gcf,'units','points','position',[10,10,500,400]);
        filename = strcat('/home/bruno/', event_name, '_pca_filter.eps');
        print(filename, '-depsc', '-r0');
        close(fig_obj);
    end
end

% Plot comparison between variance and spectrogram movement interval
enable = 0;
if(enable == 1)
    csi_mag = abs(csi_data_bruno_w_70);
    nons_csi = (csi_mag - mean(csi_mag, 2)).';
    coeff= pca(nons_csi);
    pca_comp = nons_csi*coeff(:,2);
    
    stft_data = imgaussfilt(spectrogram.stft(9:17, :), 0.8, 'FilterSize', 5);
    total_packets = size(csi_mag,2);
    seconds = total_packets/800;
    xplot = linspace(0, seconds, total_packets);
    
    fig_obj = figure;
    plot(xplot, pca_comp);
    ylabel('Amplitude');
    xlabel('Time (s)');
    xlim([xplot(1,1) xplot(end,end)]);
    set(gca,'FontSize', 25);
    
    set(gcf,'units','points','position',[10,10,600,500]);
    print('/home/bruno/long_time_pca_signal.eps', '-depsc', '-r0');
    close(fig_obj);
    
    fig_obj = figure;
    imagesc(spectrogram.time, spectrogram.frequency(9:17, 1), stft_data);
    set(gca,'YDir','normal');
    set(gca,'FontSize', 25);
    ylabel('Frequency (Hz)');
    xlabel('Time (s)');
    
    set(gcf,'units','points','position',[10,10,600,500]);
    print('/home/bruno/long_time_spectrogram.eps', '-depsc', '-r0');
    close(fig_obj);
end

% Plot random tests
enable = 0;
if(enable == 1)
    % Confidence interval
    ci = 0.95;
    alpha = 1 - ci;
    
    xdata = [1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100];
    
    % K-Fold
    fig_obj = figure;
    ac_data = (1-accuracies)*100;
    ac_mean = mean(ac_data, 1);
    ac_std = std(ac_data, 0, 1);
    
    n = size(ac_data,1);
    T_multiplier = tinv(1-alpha/2, n-1);
    ci95 = T_multiplier*ac_std/sqrt(n);
    
    e = errorbar(xdata, ac_mean, ci95,'-s','Marker', '*', ...
        'MarkerSize',10, 'MarkerEdgeColor','red','MarkerFaceColor','red', ...
        'Color', 'black', 'CapSize', 11);
    ylabel('Acurácia (%)');
    xlabel('Quantidade de features ReliefF (%)');
%     ylabel('Accuracy (%)');
%     xlabel('Quantity of best ReliefF features (%)');
    xlim([1 100]);
    ylim([0 100]);
    set(gca,'FontSize', 25);
    
    set(gcf,'units','points','position',[10,10,600,500]);
    print('/home/bruno/kfold.eps', '-depsc', '-r0');
    close(fig_obj);

    % Leave-One-Out
    fig_obj = figure;
    ac_data = (1-accuracies_lOO)*100;
    ac_mean = mean(ac_data, 1);
    ac_std = std(ac_data, 0, 1);
    
    n = size(ac_data,1);
    T_multiplier = tinv(1-alpha/2, n-1);
    ci95 = T_multiplier*ac_std/sqrt(n);
    
    e = errorbar(xdata, ac_mean, ci95,'-s','Marker', '*', ...
        'MarkerSize',10, 'MarkerEdgeColor','red','MarkerFaceColor','red', ...
        'Color', 'black', 'CapSize', 11);
    ylabel('Acurácia (%)');
    xlabel('Quantidade de features ReliefF (%)');
%     ylabel('Accuracy (%)');
%     xlabel('Quantity of best ReliefF features (%)');
    xlim([1 100]);
    ylim([0 100]);
    set(gca,'FontSize', 25);

    set(gcf,'units','points','position',[10,10,600,500]);
    print('/home/bruno/loo.eps', '-depsc', '-r0');
    close(fig_obj);
end

% qtd de amostras
enable = 0;
if(enable == 1)
    ci = 0.95;
    alpha = 1 - ci;
    
    fig_obj = figure;
    xdata = [1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100];
    max_amount = datasets_len-qtd_of_predict;
    xdata = xdata*max_amount/100;
    ac_data = accuracies*100;
    mean_data = mean(ac_data, 1);
    ac_std = std(ac_data, 0, 1);
    
    n = size(ac_data,1);
    T_multiplier = tinv(1-alpha/2, n-1);
    ci95 = T_multiplier*ac_std/sqrt(n);
    
    e = errorbar(xdata, mean_data, ci95,'-s','Marker', '*', ...
        'MarkerSize',10, 'MarkerEdgeColor','red','MarkerFaceColor','red', ...
        'Color', 'black', 'CapSize', 11);
    ylabel('Acurácia (%)');
    xlabel('Qtd. de amostras por classe');
%     ylabel('Accuracy (%)');
%     xlabel('Quantity of samples by class');
    xlim([1 max_amount]);
    ylim([0 100]);
    set(gca,'FontSize', 25);
    
    set(gcf,'units','points','position',[10,10,600,500]);
    print('/home/bruno/qtd_of_train.eps', '-depsc', '-r0');
    close(fig_obj); 
end

% ReliefF weigths
enable = 0;
if(enable == 1)
    fig_obj = figure;
    plot(weights);
    
    xticks([1 46 98 171 487]);
    xticklabels({'D','E.%','V','A.E','C. PCA'});
%     xticklabels({'Dur.','Energy.%','Speed','Energy Signature','PCA Component'});

    yL = get(gca,'YLim');
    line([2 2],yL,'Color',[.0 .0 .0],'LineStyle',':','LineWidth', 2);
    line([92 92],yL,'Color',[.0 .0 .0],'LineStyle',':','LineWidth', 2);
    line([106 106],yL,'Color',[.0 .0 .0],'LineStyle',':','LineWidth', 2);
    line([238 238],yL,'Color',[.0 .0 .0],'LineStyle',':','LineWidth', 2);
    
    ylabel('Peso');
    xlabel('Características');
%     ylabel('Weight');
%     xlabel('Features');
    xlim([1 size(weights,2)]);
    ylim([min(weights) max(weights)]);
    set(gca,'FontSize', 25);
    
    set(gcf,'units','points','position',[10,10,1000,500]);
    print('/home/bruno/relieff_weights.eps', '-depsc', '-r0');
    close(fig_obj); 
end
