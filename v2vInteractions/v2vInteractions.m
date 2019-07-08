clf; clc; clear all; close all;

% Load the MAC address for all RSUs and OBUs
% Initialise various variables and the paths.
pathRoot = './trials/importedData/';
transPower = {'HP'; 'LP'};

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
if ~exist([pathRoot 'v2vTimestamps.mat'], 'file')
    for day = 1:length(uniqueDays)
        for trPower = 1:length(transPower)
            fprintf('Load files for day %s and transceiver %s\n', uniqueDays{day},transPower{trPower})
            varTrials = src.trialsProcessing.loadMatFiles(folders,pathRoot,uniqueDays{day},transPower{trPower},'obu');
            obus = fieldnames(varTrials.obu);

            for i = 1:length(obus)
                % Take all other vehicles' MAC addresses apart from the
                % current vehicle's one.
                k = 1:length(obus) ~= i;
                macAddress = mac.obu.(obus{k}).(transPower{trPower});
                idxRx = find(varTrials.obu.(obus{i}).RxCAM.MAC==macAddress);
                seqNumRx = varTrials.obu.(obus{i}).RxCAM.SeqNum(idxRx);

                tmpRx = seqNumRx(2:end) - seqNumRx(1:end-1);
                deviceResetRx = find(tmpRx<0);

                seqNumTx = varTrials.obu.(obus{k}).TxCAM.SeqNum;
                tmpTx = seqNumTx(2:end) - seqNumTx(1:end-1);
                deviceResetTx = find(tmpTx<0);

                % Morning
                morningPacketsTX{i} = ismember(seqNumTx(1:deviceResetTx),seqNumRx(1:deviceResetRx));
                morningPacketsRX{i} = ismember(seqNumRx(1:deviceResetRx),seqNumTx(1:deviceResetTx));

                % Afternoon
                afternoonPacketsTX{i} = ismember(seqNumTx(deviceResetTx+1:end),seqNumRx(deviceResetRx+1:end));
                afternoonPacketsRX{i} = ismember(seqNumRx(deviceResetRx+1:end),seqNumTx(deviceResetTx+1:end));

                idxTx = ismember(varTrials.obu.(obus{k}).TxCAM.SeqNum,seqNumRx);
                v2vInteractions.(['d' uniqueDays{day}]).timings.(obus{i}).(transPower{trPower}).idxRx = idxRx;
            end

            tbl = table;
            for i = 1:length(obus)
                k = 1:length(obus) ~= i;
                TX = repmat('TX',[ sum(morningPacketsTX{i}) + sum(afternoonPacketsTX{i}) 1 ]);
                MACTx = repmat(mac.obu.(obus{k}).(transPower{trPower}),[ sum(morningPacketsTX{i}) + sum(afternoonPacketsTX{i}) 1 ]);
                timestamps = varTrials.obu.(obus{k}).TxCAM.Timestamp([morningPacketsTX{i} ; afternoonPacketsTX{i}]);
                SeqNum = varTrials.obu.(obus{k}).TxCAM.SeqNum([morningPacketsTX{i} ; afternoonPacketsTX{i}]);
                GpsLonTx = varTrials.obu.(obus{k}).TxCAM.GpsLon([morningPacketsTX{i} ; afternoonPacketsTX{i}]);
                GpsLatTx = varTrials.obu.(obus{k}).TxCAM.GpsLat([morningPacketsTX{i} ; afternoonPacketsTX{i}]);
                CamLonTx = varTrials.obu.(obus{k}).TxCAM.CamLon([morningPacketsTX{i} ; afternoonPacketsTX{i}]);
                CamLatTx = varTrials.obu.(obus{k}).TxCAM.CamLat([morningPacketsTX{i} ; afternoonPacketsTX{i}]);
                RX = repmat('RX',[ sum(morningPacketsRX{i}) + sum(afternoonPacketsRX{i}) 1 ]);
                MACRx = repmat(mac.obu.(obus{i}).(transPower{trPower}),[ sum(morningPacketsRX{i}) + sum(afternoonPacketsRX{i}) 1 ]);
                GpsLonRx = varTrials.obu.(obus{i}).RxCAM.GpsLon([morningPacketsRX{i} ; afternoonPacketsRX{i}]);
                GpsLatRx = varTrials.obu.(obus{i}).RxCAM.GpsLat([morningPacketsRX{i} ; afternoonPacketsRX{i}]);
                CamLonRx = varTrials.obu.(obus{i}).RxCAM.CamLon([morningPacketsRX{i} ; afternoonPacketsRX{i}]);
                CamLatRx = varTrials.obu.(obus{i}).RxCAM.CamLat([morningPacketsRX{i} ; afternoonPacketsRX{i}]);

                if length(MACTx) > length(MACRx)
                    tmp = table(timestamps(1:length(MACRx)), TX(1:length(MACRx),:), MACTx(1:length(MACRx),:), GpsLonTx(1:length(MACRx)), GpsLatTx(1:length(MACRx)), CamLonTx(1:length(MACRx)), CamLatTx(1:length(MACRx)),...
                            RX, MACRx, GpsLonRx, GpsLatRx, CamLonRx, CamLatRx);

                    tmp.Properties.VariableNames{'Var1'} = 'timestamps';
                    tmp.Properties.VariableNames{'Var2'} = 'TX';
                    tmp.Properties.VariableNames{'Var3'} = 'MACTx';
                    tmp.Properties.VariableNames{'Var4'} = 'GpsLonTx';
                    tmp.Properties.VariableNames{'Var5'} = 'GpsLatTx';
                    tmp.Properties.VariableNames{'Var6'} = 'CamLonTx';
                    tmp.Properties.VariableNames{'Var7'} = 'CamLatTx';
                    tbl = [ tbl ; tmp ];
                else
                    tmp = table(timestamps, TX, MACTx, GpsLonTx, GpsLatTx, CamLonTx, CamLatTx,...
                            RX(1:length(MACTx),:), MACRx(1:length(MACTx),:), GpsLonRx(1:length(MACTx)), GpsLatRx(1:length(MACTx)), CamLonRx(1:length(MACTx)), CamLatRx(1:length(MACTx)));

                    tmp.Properties.VariableNames{'Var8'} = 'RX';
                    tmp.Properties.VariableNames{'Var9'} = 'MACRx';
                    tmp.Properties.VariableNames{'Var10'} = 'GpsLonRx';
                    tmp.Properties.VariableNames{'Var11'} = 'GpsLatRx';
                    tmp.Properties.VariableNames{'Var12'} = 'CamLonRx';
                    tmp.Properties.VariableNames{'Var13'} = 'CamLatRx';
                    tbl = [ tbl ; tmp ];
                end
            end
            v2vInteractions.(['d' uniqueDays{day}]).interactions.(transPower{trPower}).tbl = sortrows(tbl,'timestamps');

        end
    end
    % save the struct to the given folder
    save([ pathRoot 'v2vInteractions.mat' ],'v2vInteractions')
else
    load([pathRoot 'v2vInteractions.mat'])
end
