% Import all files and save them into a .mat format
% The files are saved inside the importedPath folder
function importSave(origPath,folders,importedDataPath)
    
    % Check if importedData folder exists - if not, create it
    if ~exist([ origPath importedDataPath ],'dir')
        mkdir([ origPath importedDataPath ]);
    end
    
    fprintf('############## Phase 2: Generate all the .mat files - to be used for processing the results. ##############\n\n');
    % Find all the folder names that need to be processed.
    if isempty(folders)
        tmp = dir(origPath);
        rowsToRemove = [];
        for sbFl = 1:length(tmp)
            if strcmp(tmp(sbFl).name,'.') || strcmp(tmp(sbFl).name,'..') || strcmp(tmp(sbFl).name,'importedData')
                rowsToRemove = [ rowsToRemove sbFl ];
            end
        end
        tmp(rowsToRemove) = [];
        folders = {tmp(:).name};
        fprintf('All hidden folders excluded from processing.\n');
    end
    
    fprintf('\n############## Process all the trial data. Generate all the .mat files ##############\n\n');
    for folderVar = 1:length(folders)
        % Skip the .zip files - not to be processed. 
        path = strcat(origPath,folders{folderVar}); 
        % Skip the .zip files - not to be processed. 
        if contains(path,'.zip')
            continue
        end
        
        % Find the path for each trial day and all the subfolders 
        path = strcat(origPath,folders{folderVar}); 
        path = strcat(path, '/');
        files = dir(path);
        dirFlags = [files.isdir];
        subFolders = files(dirFlags);

        % Remove the hidden files from linux (if they exist)
        rowsToRemove = [];
        for sbFl = 1:length(subFolders)
            if strcmp(subFolders(sbFl).name,'.') || strcmp(subFolders(sbFl).name,'..')
                rowsToRemove = [ rowsToRemove sbFl ];
            end
        end
        subFolders(rowsToRemove) = [];
        
        folderName = [ origPath importedDataPath '/' folders{folderVar} ];
        if ~exist(folderName,'dir')
            mkdir(folderName);
        end
        
        for sbFl = 1:length(subFolders)
            expPath = strcat(path, subFolders(sbFl).name);
            fprintf('\nProcessing files in folder: %s -- Under path: %s\n', subFolders(sbFl).name, path);
            trialFiles = dir(expPath);
            dirFlags = [trialFiles.isdir];
            trialFiles = trialFiles(~dirFlags);
            
            for fileToProcess = 1:length(trialFiles)
                importFile = [];
                if contains(trialFiles(fileToProcess).name,'.log')
                    fprintf('Processing file: %s\n', trialFiles(fileToProcess).name);
                    fileName = [ path subFolders(sbFl).name '/' trialFiles(fileToProcess).name ];
                    if contains(trialFiles(fileToProcess).name,'tcpDump')
                        if contains(trialFiles(fileToProcess).name,'HP')
                            importFile = src.trialsProcessing.importfileTCPDumpHP(fileName);
                        else
                            importFile = src.trialsProcessing.importfileTCPDumpLP(fileName);
                        end
                    else
                        if contains(fileName,'Rx')
                            importFile = src.trialsProcessing.importfileRX(fileName);
                            if ~isempty(importFile)
                                % Remove the entries that the GPS fix was lost
                                toRemove = table2array(importFile(:,5))>360;
                                importFile(toRemove,:)=[];
                            end
                        else
                            importFile = src.trialsProcessing.importfileTX(fileName);
                        end
                    end
                end
                
                % Save file if everything is imported correctly
                if ~isempty(importFile)
                    splitString = strsplit(trialFiles(fileToProcess).name,'.');
                    % Modify the variable name based on the given session
                    % and the device processed (RSU or OBU)
                    if contains(fileName, 'vehNo')
                        if contains(subFolders(sbFl).name,'Afternoon')
                            saveFileName = [ splitString{1} '_af' ];
                        else
                            saveFileName = [ splitString{1} '_mr' ];
                        end
                    else
                        saveFileName = [ 'rsu_' splitString{1} ];
                    end
                    fileToSave = genvarname(saveFileName);
                    evalc([fileToSave '= importFile']);
                    importedPath = strsplit(origPath,'/');
                    pathToUse = ['/', importedPath{2}, '/', importedPath{3}, '/', importedPath{4}, '/' ];
                    save(fullfile([folderName '/'],saveFileName),saveFileName);
                    fprintf('The %s file was saved successfully\n', saveFileName);
                    clear(fileToSave)
                end
            end
            fprintf('\nAll files is the subfolder %s were processed successfully\n', subFolders(sbFl).name);
        end
    end
  
end

