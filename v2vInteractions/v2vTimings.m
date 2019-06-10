clf; clc; clear all; close all;

% Load the MAC address for all RSUs and OBUs
% Initialise various variables and the paths.
pathRoot = './trialsTest/T3/importedData/';
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
                idx = find(varTrials.obu.(obus{i}).RxCAM.MAC==macAddress);
                v2vTimestamps.(['d' uniqueDays{day}]).(obus{i}).(transPower{trPower}).idx = idx;
            end

        end
    end
    % save the struct to the given folder
    save([ pathRoot 'v2vTimestamps.mat' ],'v2vTimestamps')
else
    load([pathRoot 'v2vTimestamps.mat'])
end
