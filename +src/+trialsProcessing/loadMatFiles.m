function varTrials = loadMatFiles(folders,pathRoot,dayName,transPower)
% loadMatFiles Load files for given day.
% The file loads all the .mat files for a given day and it either
% concatenates the with the existing variable or it it generates a variable
% in the workspace (inside the varTrials struct)

    varTrials = struct;
    for fld = 1 : length(folders)
        if contains(folders(fld).name,dayName)
            fprintf('Processing folder: %s\n',folders(fld).name)
            path = [ pathRoot folders(fld).name '/' ];
            filesMat = dir(path);
            for i=1:length(filesMat)
                % Ignore hidden files from linux (if they exist), ignore 
                % tcpdump-related .mat files, ignore files that are not 
                % from given transceiver and load the rest
                if strcmp(filesMat(i).name,'.') || strcmp(filesMat(i).name,'..') || contains(filesMat(i).name,'tcpDump') || ~contains(filesMat(i).name,transPower)
                    continue
                else
                    fprintf('Load file: %s\n', filesMat(i).name)
                end
                fileNameTmp = strsplit(filesMat(i).name,{'_','-','.'});

                % Check if it is an RSU or an OBU
                if contains(fileNameTmp{1},'veh')
                    deviceType = 'obu';
                    devNo = ['veh' fileNameTmp{2}];
                else
                    deviceType = 'rsu';
                    devNo = ['rsu' fileNameTmp{2}];
                end

                fileNamePath = [pathRoot folders(fld).name '/' filesMat(i).name];
                load(fileNamePath);
                if contains(fileNamePath,'rsu')
                    tmpName = genvarname([fileNameTmp{1} '_' fileNameTmp{2} '_' fileNameTmp{3} '_' fileNameTmp{4}]);
                else                    
                    tmpName = genvarname([fileNameTmp{1} '_' fileNameTmp{2} '_' fileNameTmp{3} '_' fileNameTmp{4} '_' fileNameTmp{5}]);
                end
                loadedValues = table2struct(eval(tmpName));
                
                % load all values from the mat files
                if contains(filesMat(i).name,'RxCAM')
                    loadedMAC = table2array(eval([tmpName '(:,1)']));
                    loadedValuesArray = table2array(eval([tmpName '(:,2:7)']));
                    try isfield(varTrials.(deviceType).(devNo),(fileNameTmp{3}));
                        varTrials = concatValuesRX(varTrials,loadedMAC,deviceType,devNo,fileNameTmp{3},loadedValuesArray);
                    catch
                        varTrials = addValuesRX(varTrials,loadedMAC,deviceType,devNo,fileNameTmp{3},loadedValuesArray);
                    end
                else
                    loadedAll = table2array(eval([tmpName]));
                    try isfield(varTrials.(deviceType).(devNo),(fileNameTmp{3}));
                        varTrials = concatValuesTX(varTrials,deviceType,devNo,fileNameTmp{3},loadedAll);
                    catch
                        varTrials = addValuesTX(varTrials,deviceType,devNo,fileNameTmp{3},loadedAll);
                    end
                end
            end
        end

    end
end

% Add new RX struct
function vTrials = addValuesRX(vTrials,loadedMAC,deviceType,devNo,fileName,loadedValuesArray)
    vTrials.(deviceType).(devNo).(fileName).MAC = loadedMAC;
    vTrials.(deviceType).(devNo).(fileName).SeqNum = loadedValuesArray(:,1);
    vTrials.(deviceType).(devNo).(fileName).GpsLon = loadedValuesArray(:,2);
    vTrials.(deviceType).(devNo).(fileName).GpsLat = loadedValuesArray(:,3);
    vTrials.(deviceType).(devNo).(fileName).CamLon = loadedValuesArray(:,4);
    vTrials.(deviceType).(devNo).(fileName).CamLat = loadedValuesArray(:,5);
    vTrials.(deviceType).(devNo).(fileName).Timestamp = loadedValuesArray(:,6);
end

% Add new TX struct
function vTrials = addValuesTX(vTrials,deviceType,devNo,fileName,loadedAll)
    vTrials.(deviceType).(devNo).(fileName).SeqNum = loadedAll(:,1);
    vTrials.(deviceType).(devNo).(fileName).GpsLon = loadedAll(:,2);
    vTrials.(deviceType).(devNo).(fileName).GpsLat = loadedAll(:,3);
    vTrials.(deviceType).(devNo).(fileName).CamLon = loadedAll(:,4);
    vTrials.(deviceType).(devNo).(fileName).CamLat = loadedAll(:,5);
    vTrials.(deviceType).(devNo).(fileName).Timestamp = loadedAll(:,6);
end

% Concatenate existing RX struct with the newly loaded one
function vTrials = concatValuesRX(vTrials,loadedMAC,deviceType,devNo,fileName,loadedValuesArray)
    vTrials.(deviceType).(devNo).(fileName).MAC =...
        [ loadedMAC ; vTrials.(deviceType).(devNo).(fileName).MAC ];
    vTrials.(deviceType).(devNo).(fileName).SeqNum =...
        [ loadedValuesArray(:,1) ; vTrials.(deviceType).(devNo).(fileName).SeqNum ];
    vTrials.(deviceType).(devNo).(fileName).GpsLon =...
        [ loadedValuesArray(:,2) ; vTrials.(deviceType).(devNo).(fileName).GpsLon ];
    vTrials.(deviceType).(devNo).(fileName).GpsLat =...
        [ loadedValuesArray(:,3) ; vTrials.(deviceType).(devNo).(fileName).GpsLat ];
    vTrials.(deviceType).(devNo).(fileName).CamLon =...
        [ loadedValuesArray(:,4) ; vTrials.(deviceType).(devNo).(fileName).CamLon ];
    vTrials.(deviceType).(devNo).(fileName).CamLat =...
        [ loadedValuesArray(:,5) ; vTrials.(deviceType).(devNo).(fileName).CamLat ];
    vTrials.(deviceType).(devNo).(fileName).Timestamp =...
        [ loadedValuesArray(:,6) ; vTrials.(deviceType).(devNo).(fileName).Timestamp ];
end

% Concatenate existing TX struct with the newly loaded one
function vTrials = concatValuesTX(vTrials,deviceType,devNo,fileName,loadedAll)
    vTrials.(deviceType).(devNo).(fileName).SeqNum =...
        [ loadedAll(:,1) ; vTrials.(deviceType).(devNo).(fileName).SeqNum ];
    vTrials.(deviceType).(devNo).(fileName).GpsLon =...
        [ loadedAll(:,2) ; vTrials.(deviceType).(devNo).(fileName).GpsLon ];
    vTrials.(deviceType).(devNo).(fileName).GpsLat =...
        [ loadedAll(:,3) ; vTrials.(deviceType).(devNo).(fileName).GpsLat ];
    vTrials.(deviceType).(devNo).(fileName).CamLon =...
        [ loadedAll(:,4) ; vTrials.(deviceType).(devNo).(fileName).CamLon ];
    vTrials.(deviceType).(devNo).(fileName).CamLat =...
        [ loadedAll(:,5) ; vTrials.(deviceType).(devNo).(fileName).CamLat ];
    vTrials.(deviceType).(devNo).(fileName).Timestamp =...
        [ loadedAll(:,6) ; vTrials.(deviceType).(devNo).(fileName).Timestamp ];
end
