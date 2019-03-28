function varTrials = loadMatRSSI(folders,pathRoot,dayName,transPower)
%LOADMATFILES Load files for given day.

    varTrials = struct;
    for fld = 1 : length(folders)
        if contains(folders(fld).name,dayName)
            fprintf('Processing folder: %s\n',folders(fld).name)
            path = [ pathRoot folders(fld).name '/' ];
            filesMat = dir(path);
            for i=1:length(filesMat)
                if strcmp(filesMat(i).name,'.') || strcmp(filesMat(i).name,'..') || ~contains(filesMat(i).name,'tcpDump') || ~contains(filesMat(i).name,transPower)
                    continue
                else
                    fprintf('Load file: %s\n', filesMat(i).name)
                end
                fileNameTmp = strsplit(filesMat(i).name,{'_','-','.'});

                if contains(fileNameTmp{1},'veh')
                    deviceType = 'obu';
                    devNo = ['veh' fileNameTmp{2}];
                else
                    deviceType = 'rsu';
                    devNo = ['rsu' fileNameTmp{2}];
                end
                
                fileNamePath = [pathRoot folders(fld).name '/' filesMat(i).name];
                load([pathRoot folders(fld).name '/' filesMat(i).name]);
                tmpName = genvarname([fileNameTmp{1} '_' fileNameTmp{2} '_' fileNameTmp{3} '_' fileNameTmp{4}]);
                if contains(fileNamePath,'rsu')
                    tmpName = genvarname([fileNameTmp{1} '_' fileNameTmp{2} '_' fileNameTmp{3} '_' fileNameTmp{4}]);
                else                    
                    tmpName = genvarname([fileNameTmp{1} '_' fileNameTmp{2} '_' fileNameTmp{3} '_' fileNameTmp{4} '_' fileNameTmp{5}]);
                end
                
                loadedTimeStamp = table2array(eval([tmpName '(:,1)']));
                loadedDBm = table2array(eval([tmpName '(:,2)']));
                loadedSrcAddress = table2array(eval([tmpName '(:,3)']));
                loadedSeqNum = table2array(eval([tmpName '(:,4)']));
                loadedCoordinates = table2array(eval([tmpName '(:,5:6)']));
                 
                try isfield(varTrials.(deviceType),(devNo),(fileNameTmp{4}));
                    varTrials = concatValuesRX(varTrials,deviceType,devNo,...
                                fileNameTmp{4},loadedTimeStamp,loadedDBm,...
                                loadedSrcAddress,loadedSeqNum,loadedCoordinates);
                catch
                    varTrials = addValuesRX(varTrials,deviceType,devNo,...
                                fileNameTmp{4},loadedTimeStamp,loadedDBm,...
                                loadedSrcAddress,loadedSeqNum,loadedCoordinates);
                end
                
            end
        end

    end
end

function vTrials = addValuesRX(vTrials,deviceType,devNo,antennaType,loadedTimeStamp,...
                               loadedDBm,loadedSrcAddress,loadedSeqNum,loadedCoordinates)
    vTrials.(deviceType).(devNo).(antennaType).timeStamp = loadedTimeStamp;
    vTrials.(deviceType).(devNo).(antennaType).dBSignal = loadedDBm;
    vTrials.(deviceType).(devNo).(antennaType).srcAddress = loadedSrcAddress;
    vTrials.(deviceType).(devNo).(antennaType).seqNum = loadedSeqNum;
    vTrials.(deviceType).(devNo).(antennaType).lat = loadedCoordinates(:,1);
    vTrials.(deviceType).(devNo).(antennaType).lon = loadedCoordinates(:,2);
end

function vTrials = concatValuesRX(vTrials,deviceType,devNo,antennaType,loadedTimeStamp,...
                                  loadedDBm,loadedSrcAddress,loadedSeqNum,loadedCoordinates)
    vTrials.(deviceType).(devNo).(antennaType).timeStamp = [ loadedTimeStamp; vTrials.(deviceType).(devNo).(antennaType).timeStamp ];
    vTrials.(deviceType).(devNo).(antennaType).dBSignal = [ loadedDBm; vTrials.(deviceType).(devNo).(antennaType).dBSignal ]; 
    vTrials.(deviceType).(devNo).(antennaType).srcAddress = [ loadedSrcAddress; vTrials.(deviceType).(devNo).(antennaType).srcAddress ];
    vTrials.(deviceType).(devNo).(antennaType).seqNum = [ loadedSeqNum; vTrials.(deviceType).(devNo).(antennaType).seqNum ];
    vTrials.(deviceType).(devNo).(antennaType).lat = [ loadedCoordinates(:,1); vTrials.(deviceType).(devNo).(antennaType).lat ];
    vTrials.(deviceType).(devNo).(antennaType).lon = [ loadedCoordinates(:,2); vTrials.(deviceType).(devNo).(antennaType).lon ];
end
