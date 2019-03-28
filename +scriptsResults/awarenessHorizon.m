clf; clc; clear all; close all;

% Initialise various variables and the paths.
pathRoot = './trials/importedData/';
saveFigPath = [ pathRoot 'images/' ];
if (exist(saveFigPath, 'dir') ~= 7)
    mkdir(saveFigPath)
end
time_reference = datenum('1970', 'yyyy');
barWidth = 20; % given in meters
fullDaysName = 'fullDays';
transPower = {'HP'; 'LP'};
awarenessHorizonStats = struct;

% Load all the MAC addresses of the devices.
load('./macAddresses/macAddresses.mat')

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

%% Check whether a preprocessed .mat exists
% if not process the data to generate the awareness horizon
if ~exist([pathRoot 'awarenessHorizonStats.mat'], 'file')
    for day = 1:length(uniqueDays)
        for trPower = 1:length(transPower)
            fprintf('Load files for day %s and transceiver %s\n', uniqueDays{day},transPower{trPower})
            varTrials = src.trialsProcessing.loadMatFiles(folders,pathRoot,uniqueDays{day},transPower{trPower});
            
            rsus = fieldnames(varTrials.rsu);
            obus = fieldnames(varTrials.obu);
            awarenessHorizonStats.obus = obus;
            awarenessHorizonStats.rsus = rsus;
            if day == 1 && trPower == 1
                fprintf('Find the positions of all RSUs\n');
                for i = 1:length(rsus)
                    awarenessHorizonStats.rsuLat(i) = varTrials.rsu.(rsus{i}).TxCAM.CamLat(1000);
                    awarenessHorizonStats.rsuLon(i) = varTrials.rsu.(rsus{i}).TxCAM.CamLon(1000);
                end
                
                rsuPos = [ awarenessHorizonStats.rsuLat' awarenessHorizonStats.rsuLon' ];
                fprintf('Find all the map data positions of all RSUs\n');
                [ awarenessHorizonStats.maxMinStr, awarenessHorizonStats.distancesStr,...
                    awarenessHorizonStats.grid, awarenessHorizonStats.tileCentreDistance ] =...
                    src.trialsProcessing.maxMinDistancesCoordinates(varTrials,obus,barWidth,rsuPos,rsus);
            end
            
            
            
            fprintf('Find all the transmitted packets per tile. Tile size is: %d\n',barWidth);
            for i = 1:length(obus)
                
                fprintf('Find all the transmitted packets per tile for vehicle %s.\n',obus{i});
                withinXY = {};
                for k = 1:length(awarenessHorizonStats.grid.xyGrid)
                    withinXY{k} = varTrials.obu.(obus{i}).TxCAM.GpsLat > awarenessHorizonStats.grid.xyGrid(k,1)-awarenessHorizonStats.grid.xTileSize/2 &...
                        varTrials.obu.(obus{i}).TxCAM.GpsLat < awarenessHorizonStats.grid.xyGrid(k,1)+awarenessHorizonStats.grid.xTileSize/2 &...
                        varTrials.obu.(obus{i}).TxCAM.GpsLon > awarenessHorizonStats.grid.xyGrid(k,2)-awarenessHorizonStats.grid.yTileSize/2 &...
                        varTrials.obu.(obus{i}).TxCAM.GpsLon < awarenessHorizonStats.grid.xyGrid(k,2)+awarenessHorizonStats.grid.yTileSize/2;
                end
                
                
                fprintf('Find all the received packets for vehicle %s, per tile for all RSUs\n', obus{i});
                tmpStruct = struct;
                for k = 1:length(rsus)
                    awarenessHorizonStats.rsuPos.lat(k) = varTrials.rsu.(rsus{k}).TxCAM.CamLon(1000);
                    awarenessHorizonStats.rsuPos.lon(k) = varTrials.rsu.(rsus{k}).TxCAM.CamLon(1000);

                    tmpStruct.(obus{i})(:,k) =...
                         src.trialsProcessing.haversineMeter(varTrials.obu.(obus{i}).TxCAM.CamLat,...
                                                             varTrials.obu.(obus{i}).TxCAM.CamLon,...
                                                             awarenessHorizonStats.rsuPos.lat(k),...
                                                             awarenessHorizonStats.rsuPos.lon(k));
                    
                    packetsReceivedRSUSide{k} = mac.obu.(obus{i}).(transPower{trPower}) == varTrials.rsu.(rsus{k}).RxCAM.MAC;
                    fprintf('Compare the transmitted with the received packets for RSU %s and save the awarenessHorizonStats.\n',rsus{k});
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
                        distances{counter} = tmpStruct.(obus{i})(rcvdTmp,k);
                    end
                    
                    % save all the data in a struct
                    awarenessHorizonStats.(['d' uniqueDays{day}]).(obus{i}).(transPower{trPower}).(rsus{k}).sent = sent;
                    awarenessHorizonStats.(['d' uniqueDays{day}]).(obus{i}).(transPower{trPower}).(rsus{k}).received = received;
                    awarenessHorizonStats.(['d' uniqueDays{day}]).(obus{i}).(transPower{trPower}).(rsus{k}).distances = distances;
                    awarenessHorizonStats.days{day} = [ 'd' uniqueDays{day} ];
                end
            end
        end
    end
    % save the struct to the given folder
    save([ pathRoot 'awarenessHorizonStats.mat' ],'awarenessHorizonStats')
else
    load([pathRoot 'awarenessHorizonStats.mat'])
end

%% If a preprocessed .mat exists plot the results
counter = 1;
dayVars = awarenessHorizonStats.days;
obus = awarenessHorizonStats.obus;
rsus = fieldnames(awarenessHorizonStats.(dayVars{1}).(obus{1}).(transPower{1}));

for day = 1:length(dayVars)
    for obu = 1:length(obus)
        for trPower = 1:length(transPower)
            figure('units','normalized','outerposition',[0 0 1 1]);
            for rsu = 1:length(rsus)
                subplot(4,1,rsu)
                distances = [];
                sentPackets = [];
                receivedPackets = [];
                for i = 1:length(awarenessHorizonStats.tileCentreDistance.(rsus{rsu}).distance)
                    distances(i) = awarenessHorizonStats.tileCentreDistance.(rsus{rsu}).distance(i);
                    sentPackets(i) = awarenessHorizonStats.(dayVars{day}).(obus{obu}).(transPower{trPower}).(rsus{rsu}).sent(i);
                    receivedPackets(i) = awarenessHorizonStats.(dayVars{day}).(obus{obu}).(transPower{trPower}).(rsus{rsu}).received(i);
                end
                
                counter = 1;
                pdrPerc = [];
                xTickLabel = [];
                for i = 1:barWidth:500
                    withinDistance = distances<i+barWidth-1 & distances>i-1;
                    sentTmp = sum(sentPackets(withinDistance));
                    recvTmp = sum(receivedPackets(withinDistance));
                    pdrPerc(counter) = recvTmp/sentTmp;
                    xTickLabel{counter} = [ num2str(i-1) 'm - ' num2str(i+barWidth-1) 'm' ];
                    counter = counter + 1;
                    
                end
                
                bar(pdrPerc,'BarWidth',1)
                ylim([0 1])
                set(gca, 'YGrid', 'on', 'XGrid', 'off')
                if rsu==4
                    set(gca, 'XTick', [1:length(xTickLabel)])
                    xtickangle(45);
                    xticklabels(xTickLabel);
                    xlabel('Distance (m)')
                else
                    set(gca,'xticklabel',[])
                end
                ylabel('PDR')
                if rsu==1
                    titleStr = ['Awareness Horizon - ' dayVars{day} ' - ' transPower{trPower} ' - ' obus{obu} ' --> All RSUs (' rsus{1} ', ' rsus{2} ', ' rsus{3} ', ' rsus{4},')'];
                    title(titleStr)
                end
                set(findall(gcf,'-property','FontSize'),'FontSize',16)
            end
            imageTitle = [ saveFigPath 'awarenessHorizon_Day_' dayVars{day} '_' transPower{trPower} '_' obus{obu} '.fig' ];
            savefig(imageTitle);
        end
    end
end

