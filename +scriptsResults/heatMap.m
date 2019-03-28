clf; clc; clear all; close all;

% Initialise various variables and the paths.
pathRoot = './trials/importedData/';
saveFigPath = [ pathRoot 'images/' ];
if (exist(saveFigPath, 'dir') ~= 7)
    mkdir(saveFigPath)
end
time_reference = datenum('1970', 'yyyy');
mapTileSize = 5; % given in meters
fullDaysName = 'fullDays';
transPower = {'HP'; 'LP'};
heatmapStats = struct;

% Load all the MAC addresses of the devices.
load('./macAddresses/macAddresses.mat')

% Load the API key -- used with Google maps
googleMapAPIPath = './apiKey/api_key.mat';
if (exist(googleMapAPIPath, 'file')==2)
    load(googleMapAPIPath)
else
    APIKey = [];
end

files = dir(pathRoot);
dirFlags = [files.isdir];
folders = files(dirFlags);

counter = 0;
for fld = 1 : length(folders)
    if strcmp(folders(fld).name,'.') || strcmp(folders(fld).name,'..') || strcmp(folders(fld).name,'images')
        continue
    else
        counter = counter + 1;
    end
    fileNameTmp = strsplit(folders(fld).name,{'-'});
    tmpCharArray{counter} = fileNameTmp{1};
end
uniqueDays = unique(tmpCharArray);


if ~exist([pathRoot 'heatMapStats.mat'], 'file')
    for day = 1:length(uniqueDays)
        for trPower = 1:length(transPower)
            fprintf('Load files for day %s and transceiver %s\n', uniqueDays{day},transPower{trPower})
            varTrials = src.trialsProcessing.loadMatFiles(folders,pathRoot,uniqueDays{day},transPower{trPower});

            rsus = fieldnames(varTrials.rsu);
            obus = fieldnames(varTrials.obu);
            heatmapStats.obus = obus;
            heatmapStats.rsus = rsus;
            if day == 1 && trPower == 1
                fprintf('Find the positions of all RSUs\n');
                for i = 1:length(rsus)
                    heatmapStats.rsuLat(i) = varTrials.rsu.(rsus{i}).TxCAM.CamLat(1000);
                    heatmapStats.rsuLon(i) = varTrials.rsu.(rsus{i}).TxCAM.CamLon(1000);
                end

                rsuPos = [ heatmapStats.rsuLat' heatmapStats.rsuLon' ];
                fprintf('Find all the map data positions of all RSUs\n');
                [ heatmapStats.maxMinStr, heatmapStats.distancesStr, heatmapStats.grid, ~ ] =...
                    src.trialsProcessing.maxMinDistancesCoordinates(varTrials,obus,mapTileSize,rsuPos,rsus);
            end

            fprintf('Find all the transmitted packets per tile. Tile size is: %d\n',mapTileSize);
            for i = 1:length(obus)

                fprintf('Find all the transmitted packets per tile for vehicle %s.\n',obus{i});
                withinXY = {};
                for k = 1:length(heatmapStats.grid.xyGrid)
                    withinXY{k} = varTrials.obu.(obus{i}).TxCAM.CamLat > heatmapStats.grid.xyGrid(k,1)-heatmapStats.grid.xTileSize/2 &...
                        varTrials.obu.(obus{i}).TxCAM.CamLat < heatmapStats.grid.xyGrid(k,1)+heatmapStats.grid.xTileSize/2 &...
                        varTrials.obu.(obus{i}).TxCAM.CamLon > heatmapStats.grid.xyGrid(k,2)-heatmapStats.grid.yTileSize/2 &...
                        varTrials.obu.(obus{i}).TxCAM.CamLon < heatmapStats.grid.xyGrid(k,2)+heatmapStats.grid.yTileSize/2;
                end

                fprintf('Find all the received packets for vehicle %s, per tile for all RSUs\n', obus{i});
                for k = 1:length(rsus)
                    packetsReceivedRSUSide{k} = mac.obu.(obus{i}).(transPower{trPower}) == varTrials.rsu.(rsus{k}).RxCAM.MAC;
                    fprintf('Compare the transmitted with the received packets for RSU %s and save the heatmapStats.\n',rsus{k});
                    sent = [];
                    received = [];
                    for counter = 1:length(withinXY)
                        seqNumTXPos = find(withinXY{counter}~=0);
                        seqNumTX = varTrials.obu.(obus{i}).TxCAM.SeqNum(seqNumTXPos);
                        seqNumRXPos = find(packetsReceivedRSUSide{k}~=0);
                        seqNumRX = varTrials.rsu.(rsus{k}).RxCAM.SeqNum(seqNumRXPos);
                        rcvdTmp = ismember(seqNumTX,seqNumRX);
                        sent(counter) = length(seqNumTX);
                        received(counter) = sum(rcvdTmp);
                    end
                    heatmapStats.(['d' uniqueDays{day}]).(obus{i}).(transPower{trPower}).(rsus{k}).sent = sent;
                    heatmapStats.(['d' uniqueDays{day}]).(obus{i}).(transPower{trPower}).(rsus{k}).received = received;
                    heatmapStats.days{day} = [ 'd' uniqueDays{day} ];
                end
            end
        end
    end
    save([ pathRoot 'heatMapStats.mat' ],'heatmapStats')
else
    load([pathRoot 'heatMapStats.mat'])
end

counter = 1;
dayVars = heatmapStats.days;
obus = heatmapStats.obus;
rsus = fieldnames(heatmapStats.(dayVars{1}).(obus{1}).(transPower{1}));
for i = 1:length(heatmapStats.grid.xyGrid)
    rectanglesX(counter,:) = [ heatmapStats.grid.xyGrid(i,1) - heatmapStats.grid.xTileSize/2 ...
        heatmapStats.grid.xyGrid(i,1) + heatmapStats.grid.xTileSize/2 ...
        heatmapStats.grid.xyGrid(i,1) + heatmapStats.grid.xTileSize/2 ...
        heatmapStats.grid.xyGrid(i,1) - heatmapStats.grid.xTileSize/2 ...
        heatmapStats.grid.xyGrid(i,1) - heatmapStats.grid.xTileSize/2 ];
    rectanglesY(counter,:) = [ heatmapStats.grid.xyGrid(i,2) - heatmapStats.grid.yTileSize/2 ...
        heatmapStats.grid.xyGrid(i,2) - heatmapStats.grid.yTileSize/2 ...
        heatmapStats.grid.xyGrid(i,2) + heatmapStats.grid.yTileSize/2 ...
        heatmapStats.grid.xyGrid(i,2) + heatmapStats.grid.yTileSize/2 ...
        heatmapStats.grid.xyGrid(i,2) - heatmapStats.grid.yTileSize/2 ];
    counter = counter + 1;
end


%% Per day results
for trPower = 1:length(transPower)
    for obu = 1:length(obus)
        perRSUSentAll{trPower}(obu,:) = zeros(length(heatmapStats.(dayVars{1}).(obus{obu}).(transPower{trPower}).(rsus{1}).sent),1);
        perRSUReceivedAll{trPower}(obu,:) = zeros(length(heatmapStats.(dayVars{1}).(obus{obu}).(transPower{trPower}).(rsus{1}).received),1);
        perRSUPercentageAll{trPower}(obu,:) = zeros(length(heatmapStats.(dayVars{1}).(obus{obu}).(transPower{trPower}).(rsus{1}).sent),1);
    end
end

heatMapResults = struct;
for day = 1:length(dayVars)
    for rsu = 1:length(rsus)
        for trPower = 1:length(transPower)
            for obu = 1:length(obus)
                perRSUSentAll{trPower}(obu,:) = perRSUSentAll{trPower}(obu,:) + ...
                    heatmapStats.(dayVars{day}).(obus{obu}).(transPower{trPower}).(rsus{rsu}).sent;
                perRSUReceivedAll{trPower}(obu,:) = perRSUReceivedAll{trPower}(obu,:) + ...
                    heatmapStats.(dayVars{day}).(obus{obu}).(transPower{trPower}).(rsus{rsu}).received;

            end
            perRSUPercentageAll{trPower} = perRSUReceivedAll{trPower}./perRSUSentAll{trPower};
            perRSUPercentageAll{trPower}(isnan(perRSUPercentageAll{trPower})) = 0;
            heatMapResults.(dayVars{day}).(transPower{trPower})(:,rsu) = mean(perRSUPercentageAll{trPower},1);

            for obu = 1:length(obus)
                perRSUSentAll{trPower}(obu,:) = zeros(length(heatmapStats.(dayVars{1}).(obus{obu}).(transPower{trPower}).(rsus{1}).sent),1);
                perRSUReceivedAll{trPower}(obu,:) = zeros(length(heatmapStats.(dayVars{1}).(obus{obu}).(transPower{trPower}).(rsus{1}).received),1);
                perRSUPercentageAll{trPower}(obu,:) = zeros(length(heatmapStats.(dayVars{1}).(obus{obu}).(transPower{trPower}).(rsus{1}).sent),1);
            end
        end
    end

end

minLat = min(rectanglesX(:))-0.0002;
maxLat = max(rectanglesX(:))+0.0002;

minLon = min(rectanglesY(:))-0.0002;
maxLon = max(rectanglesY(:))+0.0002;

for day = 1:length(dayVars)
	for trPower = 1:length(transPower)
        values.(dayVars{day}).(transPower{trPower}) = max(heatMapResults.(dayVars{day}).(transPower{trPower}),[],2);
        % Experiment Data Figure
        figure('units','normalized','outerposition',[0 0 1 0.62]); % HP
        for i = 1:length(heatmapStats.rsuLat)
            plot(heatmapStats.rsuLon(i),heatmapStats.rsuLat(i),'xr','MarkerSize',40, 'LineWidth',5);hold on;
        end
        patch(rectanglesY', rectanglesX',values.(dayVars{day}).(transPower{trPower}),'LineStyle','none');
        colorbar; colormap('jet'); caxis([0 1])
        ylim([minLat maxLat])
        xlim([minLon maxLon])
        src.plotGoogleMap.plot_google_map('maptype','roadmap', 'apikey', APIKey);
        title(['Day ' dayVars{day} ' - ' transPower{trPower}])
        set(findall(gcf,'-property','FontSize'),'FontSize',24)
        if ~exist(saveFigPath,'dir')
            mkdir(saveFigPath)
        end
        imageTitle = [ saveFigPath 'heatmap_Day_' dayVars{day} '_' transPower{trPower} '.fig' ];
        savefig(imageTitle);
    end
end


%% Mean absolute Difference and MSE
for day = 2:length(dayVars)
    mseHP(day-1) = immse(values.(dayVars{1}).HP, values.(dayVars{day}).HP);
    meanAbsDiffHP(day-1) = mean(abs( values.(dayVars{1}).HP - values.(dayVars{day}).HP ));
    mseLP(day-1) = immse(values.(dayVars{1}).LP, values.(dayVars{day}).LP);
    meanAbsDiffLP(day-1) = mean(abs( values.(dayVars{1}).LP - values.(dayVars{day}).LP )) ;
end
figure('units','normalized','outerposition',[0 0 1 0.62]);
plot(meanAbsDiffHP,':bs','LineWidth',3,'MarkerSize',18)
hold on
plot(meanAbsDiffLP,'-go','LineWidth',3,'MarkerSize',18)
hold on
plot(mseHP,'--rx','LineWidth',3,'MarkerSize',18)
hold on
plot(mseLP,'-.k+','LineWidth',3,'MarkerSize',18)
set(findall(gcf,'-property','FontSize'),'FontSize',24)
xTickLabel = ['Day 2' ;'Day 3'; 'Day 4'];
ylabel('Normalised error value')
set(gca, 'XTick', [1:length(xTickLabel)])
xticklabels(xTickLabel);
xtickangle(45);
ylim([0 0.38])
legend('Mean Abs HP', 'Mean Abs LP', 'MSE HP', 'MSE LP')
grid on
imageTitle = [ saveFigPath 'meanDifference.fig' ];
savefig(imageTitle);


%% Heatmap from mean absolute difference
for i = 1:length(values.(dayVars{1}).HP)
    mseD(i) = immse(values.(dayVars{1}).HP(i),values.(dayVars{3}).HP(i));
    meanDiff(i) = abs( values.(dayVars{1}).HP(i) - values.(dayVars{3}).HP(i));
end

figure('units','normalized','outerposition',[0 0 1 0.62]); % HP
for i = 1:length(heatmapStats.rsuLat)
    plot(heatmapStats.rsuLon(i),heatmapStats.rsuLat(i),'xr','MarkerSize',40, 'LineWidth',5);hold on;
end
patch(rectanglesY', rectanglesX',mseD,'LineStyle','none');
colorbar; colormap('jet'); caxis([0 1])
ylim([minLat maxLat])
xlim([minLon maxLon])
set(findall(gcf,'-property','FontSize'),'FontSize',24)
src.plotGoogleMap.plot_google_map('maptype','roadmap', 'apikey', APIKey);
    title(['All Days - ' transPower{trPower}])
imageTitle = [ saveFigPath 'heatmap_MeanAbsDifference.fig' ];
savefig(imageTitle);


%% All days results
for trPower = 1:length(transPower)
    [x,y] = size(heatMapResults.(dayVars{1}).(transPower{trPower}));
    heatMapResults.allDays.(transPower{trPower}) = zeros(x,y);
    for day = 1:length(dayVars)
        heatMapResults.allDays.(transPower{trPower}) = heatMapResults.allDays.(transPower{trPower}) + ...
            heatMapResults.(dayVars{day}).(transPower{trPower});
    end

    heatMapResults.allDays.(transPower{trPower}) = heatMapResults.allDays.(transPower{trPower})./length(dayVars);
end

% Experiment Data Figure
for trPower = 1:length(transPower)
    valuesAllDays.(transPower{trPower}) = max(heatMapResults.allDays.(transPower{trPower}),[],2);
    % Experiment Data Figure
    figure('units','normalized','outerposition',[0 0 1 0.62]); % HP
    for i = 1:length(heatmapStats.rsuLat)
        plot(heatmapStats.rsuLon(i),heatmapStats.rsuLat(i),'xr','MarkerSize',40, 'LineWidth',5);hold on;
    end
    patch(rectanglesY', rectanglesX',valuesAllDays.(transPower{trPower}),'LineStyle','none');
    colorbar; colormap('jet'); caxis([0 1])
    ylim([minLat maxLat])
    xlim([minLon maxLon])
    set(findall(gcf,'-property','FontSize'),'FontSize',24)
    src.plotGoogleMap.plot_google_map('maptype','roadmap', 'apikey', APIKey);
    title(['All Days - ' transPower{trPower}])
    imageTitle = [ saveFigPath 'heatmap_AllDays_' transPower{trPower} '.fig' ];
    savefig(imageTitle);
end
