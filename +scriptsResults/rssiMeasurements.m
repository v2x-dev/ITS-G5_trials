clf; clc; clear all; close all;

% Initialise various variables and the paths.
pathRoot = './trials/importedData/';
saveFigPath = [ pathRoot 'images/' ];
if (exist(saveFigPath, 'dir') ~= 7)
    mkdir(saveFigPath)
end
rssiMeasurementsStats = struct;
minValue = 2; % the minimum time for a bin
secondsValue = 5;
distanceIntervals = 20;
mapTileSize = 5;  % given in meters
transPower = {'HP'; 'LP'};

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

if ~exist([pathRoot 'rssiMeasurementsStats.mat'], 'file')
    rssiMeasurementsStats.maxDistance = 0;
    rssiMeasurementsStats.distanceInterval = distanceIntervals;

    for day = 1:length(uniqueDays)
        dayField = [ 'd' uniqueDays{day} ];
        rssiMeasurementsStats.days{day} = dayField;
        for trPower = 1:length(transPower)
            fprintf('Load files for day %s and transceiver %s\n', uniqueDays{day},transPower{trPower})
            varTrialsTCPDump = src.trialsProcessing.loadMatRSSI(folders,pathRoot,uniqueDays{day},transPower{trPower});
            varTrialsCAMs = src.trialsProcessing.loadMatFiles(folders,pathRoot,uniqueDays{day},transPower{trPower});

            rsus = fieldnames(varTrialsCAMs.rsu);
            obus = fieldnames(varTrialsCAMs.obu);
            rssiMeasurementsStats.obus = obus;
            rssiMeasurementsStats.rsus = rsus;
            if day == 1 && trPower == 1
                fprintf('Find the positions of all RSUs\n');
                for rsu = 1:length(rsus)
                    rssiMeasurementsStats.rsuLat(rsu) = varTrialsCAMs.rsu.(rsus{rsu}).TxCAM.CamLat(1000);
                    rssiMeasurementsStats.rsuLon(rsu) = varTrialsCAMs.rsu.(rsus{rsu}).TxCAM.CamLon(1000);
                end

                rsuPos = [ rssiMeasurementsStats.rsuLat' rssiMeasurementsStats.rsuLon' ];
                fprintf('Find all the map data positions of all RSUs\n');
                [ ~, ~, rssiMeasurementsStats.grid, ~ ] =...
                    src.trialsProcessing.gridRSSI(varTrialsCAMs,obus,mapTileSize,rsuPos,rsus);
            end

            for rsu = 1:length(rsus)
                for obu = 1:length(obus)
                    % Find all the rssi values for the given position and
                    % the packets related to that

                    macAddressRSU = mac.rsu.(rsus{rsu}).(transPower{trPower});
                    packetsFromRSUIdx = varTrialsTCPDump.obu.(obus{obu}).(transPower{trPower}).srcAddress == macAddressRSU;

                    seqNumTX = varTrialsTCPDump.obu.(obus{obu}).(transPower{trPower}).seqNum(packetsFromRSUIdx);

                    rxPacketsSeqNumIdx= ismember(varTrialsCAMs.obu.(obus{obu}).RxCAM.SeqNum,seqNumTX);
                    rxPacketsMACIdx = varTrialsCAMs.obu.(obus{obu}).RxCAM.MAC == macAddressRSU;

                    rxPacketsIdx = rxPacketsSeqNumIdx .* rxPacketsMACIdx;

                    lon = varTrialsCAMs.obu.(obus{obu}).RxCAM.CamLon(logical(rxPacketsIdx));
                    lat = varTrialsCAMs.obu.(obus{obu}).RxCAM.CamLat(logical(rxPacketsIdx));

                    fprintf('Find all the received packets per tile for vehicle %s and RSU %s.\n',obus{obu},rsus{rsu});
                    withinXY = {};
                    for k = 1:length(rssiMeasurementsStats.grid.xyGrid)
                        withinXY{k} = lon > rssiMeasurementsStats.grid.xyGrid(k,2)-rssiMeasurementsStats.grid.xTileSize/2 &...
                                      lon < rssiMeasurementsStats.grid.xyGrid(k,2)+rssiMeasurementsStats.grid.xTileSize/2 &...
                                      lat > rssiMeasurementsStats.grid.xyGrid(k,1)-rssiMeasurementsStats.grid.yTileSize/2 &...
                                      lat < rssiMeasurementsStats.grid.xyGrid(k,1)+rssiMeasurementsStats.grid.yTileSize/2;
                    end

                    seqNumsFromSeqNumIdx = varTrialsCAMs.obu.(obus{obu}).RxCAM.SeqNum(rxPacketsSeqNumIdx);
                    seqNumsFromMACIdx = varTrialsCAMs.obu.(obus{obu}).RxCAM.SeqNum(rxPacketsMACIdx);

                    seqNumsToCompare = intersect(seqNumsFromSeqNumIdx,seqNumsFromMACIdx,'rows','legacy');
                    idxSeqNum = ismember(varTrialsTCPDump.obu.(obus{obu}).(transPower{trPower}).seqNum,seqNumsToCompare);
                    idxAll = idxSeqNum.*packetsFromRSUIdx;
                    rssiValues = varTrialsTCPDump.obu.(obus{obu}).(transPower{trPower}).dBSignal(logical(idxAll));

                    distanceV2I = src.trialsProcessing.haversineMeter(rssiMeasurementsStats.rsuLat(rsu),rssiMeasurementsStats.rsuLon(rsu),lat,lon);

                    rssiPerTile = {};
                    for k = 1:length(rssiMeasurementsStats.grid.xyGrid)
                        rssiPerTile{k} = rssiValues(withinXY{k});
                    end

                    rssiMeasurementsStats.(dayField).(rsus{rsu}).(transPower{trPower}).(obus{obu}).rssiValues = rssiValues;
                    rssiMeasurementsStats.(dayField).(rsus{rsu}).(transPower{trPower}).(obus{obu}).distanceV2I = distanceV2I;
                    rssiMeasurementsStats.(dayField).(rsus{rsu}).(transPower{trPower}).(obus{obu}).rssiPerTile = rssiPerTile;
                    rssiMeasurementsStats.(dayField).(rsus{rsu}).(transPower{trPower}).(obus{obu}).maxRSSI = max(rssiValues);

                    if rssiMeasurementsStats.maxDistance<max(distanceV2I)
                        rssiMeasurementsStats.maxDistance = max(distanceV2I);
                    end

                end
            end

        end
    end
    save([ pathRoot 'rssiMeasurementsStats.mat' ],'rssiMeasurementsStats')
else
    load([pathRoot 'rssiMeasurementsStats.mat'])
end

%% RSSI plots
counter = 1;
dayVars = rssiMeasurementsStats.days;
obus = rssiMeasurementsStats.obus;
rsus = fieldnames(rssiMeasurementsStats.(dayVars{1}));

for day = 1:length(dayVars)
    for trPower = 1:length(transPower)
        for rsu = 1:length(rsus)
            figure('units','normalized','outerposition',[0 0 1 0.62]); % LP
            markerSpape = [ 'o' 'x' '*' 's' ];
            if rsu==2; rsuDistance = 4; elseif rsu==4; rsuDistance = 2; else; rsuDistance=rsu; end
            distanceTiles = src.trialsProcessing.haversineMeter(rssiMeasurementsStats.grid.xyGrid(:,1),...
                            rssiMeasurementsStats.grid.xyGrid(:,2),...
                            rssiMeasurementsStats.rsuLat(rsuDistance),...
                            rssiMeasurementsStats.rsuLon(rsuDistance));
            for obu = 1:length(obus)
                counter = 1;
                withinDistance= {};
                rssiMean = [];
                xTickLabel = {};
                rssiValues = {};
                for i = 1:distanceIntervals:500
                    withinDistance = distanceTiles<i+distanceIntervals-1 & distanceTiles>i-1;
                    [xx,~] = find(withinDistance==1);
                    tmp = [];
                    for diffPoss = 1:length(xx)
                        if ~isempty(rssiMeasurementsStats.(dayVars{day}).(rsus{rsu}).(transPower{trPower}).(obus{obu}).rssiPerTile{xx(diffPoss)})
                        	tmp = [ tmp ; rssiMeasurementsStats.(dayVars{day}).(rsus{rsu}).(transPower{trPower}).(obus{obu}).rssiPerTile{xx(diffPoss)} ];
                        end
                    end

                    rssiValues{counter} = tmp;
                    rssiMean(counter) = mean(rssiValues{counter});

                    xTickLabel{counter} = [ num2str(i-1) 'm - ' num2str(i+mapTileSize-1) 'm' ];
                    counter = counter + 1;
                end

                plot(rssiMean, 'LineWidth',2, 'MarkerSize',10, 'Marker', markerSpape(obu) )
                hold on
            end

            title(['Day ' dayVars{day} ' - ' transPower{trPower} ' - ' rsus{rsu} ])
            imageTitle = [ saveFigPath 'rssiMeasurements_Day_perDistance_' dayVars{day} '_' transPower{trPower} '_' rsus{rsu} '.fig' ];

            set(gca, 'XTick', [1:length(xTickLabel)])
            xtickangle(45);
            legend('Vehicle 1', 'Vehicle 2')
            xticklabels(xTickLabel);
            ylabel('RSSI (dB)')
            xlabel('Distance in Meters (m)')
            set(findall(gcf,'-property','FontSize'),'FontSize',24)
            grid on
            savefig(imageTitle);
        end
    end
end


%% RSSI on heatmap plots
counter = 1;
dayVars = rssiMeasurementsStats.days;
obus = rssiMeasurementsStats.obus;
rsus = fieldnames(rssiMeasurementsStats.(dayVars{1}));
for i = 1:length(rssiMeasurementsStats.grid.xyGrid)
    rectanglesX(counter,:) = [ rssiMeasurementsStats.grid.xyGrid(i,1) - rssiMeasurementsStats.grid.xTileSize/2 ...
        rssiMeasurementsStats.grid.xyGrid(i,1) + rssiMeasurementsStats.grid.xTileSize/2 ...
        rssiMeasurementsStats.grid.xyGrid(i,1) + rssiMeasurementsStats.grid.xTileSize/2 ...
        rssiMeasurementsStats.grid.xyGrid(i,1) - rssiMeasurementsStats.grid.xTileSize/2 ...
        rssiMeasurementsStats.grid.xyGrid(i,1) - rssiMeasurementsStats.grid.xTileSize/2 ];
    rectanglesY(counter,:) = [ rssiMeasurementsStats.grid.xyGrid(i,2) - rssiMeasurementsStats.grid.yTileSize/2 ...
        rssiMeasurementsStats.grid.xyGrid(i,2) - rssiMeasurementsStats.grid.yTileSize/2 ...
        rssiMeasurementsStats.grid.xyGrid(i,2) + rssiMeasurementsStats.grid.yTileSize/2 ...
        rssiMeasurementsStats.grid.xyGrid(i,2) + rssiMeasurementsStats.grid.yTileSize/2 ...
        rssiMeasurementsStats.grid.xyGrid(i,2) - rssiMeasurementsStats.grid.yTileSize/2 ];
    counter = counter + 1;
end

minLat = min(rectanglesX(:))-0.0002;
maxLat = max(rectanglesX(:))+0.0002;

minLon = min(rectanglesY(:))-0.0002;
maxLon = max(rectanglesY(:))+0.0002;

for day = 1:length(dayVars)
    for trPower = 1:length(transPower)
        % find tiles to plot
        rssiResults = repmat(-1000,1,length(rectanglesX));

        for rsu = 1:length(rsus)
            rsuRSSI = repmat(-1000,1,length(rectanglesX));
            for obu = 1:length(obus)
                for i = 1:length(rsuRSSI)
                    tmp(i) = mean(rssiMeasurementsStats.(dayVars{day}).(rsus{rsu}).(transPower{trPower}).(obus{obu}).rssiPerTile{i});
                end
                tmp(isnan(tmp))=-1000;
                rsuRSSI = max([tmp; rsuRSSI], [], 1);
            end
            rssiResults = max([rssiResults; rsuRSSI], [], 1);
        end

        % find the tiles to plot
        toPlot = ~(rssiResults==-1000);

        % Experiment Data Figure
        figure('units','normalized','outerposition',[0 0 1 0.62]); % HP
        for i = 1:length(rssiMeasurementsStats.rsuLat)
            plot(rssiMeasurementsStats.rsuLon(i),rssiMeasurementsStats.rsuLat(i),'xr','MarkerSize',40, 'LineWidth',5);hold on;
        end
        patch(rectanglesY(toPlot,:)', rectanglesX(toPlot,:)',rssiResults(toPlot),'LineStyle','none');
        minRSSI = -95;

        maxRSSI = -35;
        colorbar; colormap('jet'); caxis([minRSSI maxRSSI])
        ylim([minLat maxLat])
        xlim([minLon maxLon])
        src.plotGoogleMap.plot_google_map('maptype','roadmap', 'apikey', APIKey);
        title(['Day ' dayVars{day} ' - ' transPower{trPower}])
        set(findall(gcf,'-property','FontSize'),'FontSize',24)
        if ~exist(saveFigPath,'dir')
            mkdir(saveFigPath)
        end
        imageTitle = [ saveFigPath 'rssiMeasurements_Day_heatmap_' dayVars{day} '_' transPower{trPower} '.fig' ];
        savefig(imageTitle);
    end
end
