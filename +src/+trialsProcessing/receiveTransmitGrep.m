% Grep all the txt files, split them in TX and RX and create separate files
% each transceiver. All the newly generated files are stored into the
% directory with the existing files
function receiveTransmitGrep(origPath,folders,tcpdumpPath)

    tcpDumpCommand = 'tcpdump -r';
    if ~isempty(tcpdumpPath)
        tcpDumpCommand = [ tcpdumpPath '/' tcpDumpCommand ];
    end
    
    fprintf('############## Phase 1: Generate all the .log files that will be processed later. ##############\n\n');
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

    for folderVar = 1:length(folders)
        % Skip the .zip files - not to be processed.
        path = strcat(origPath,folders{folderVar});
        if contains(path,'.zip')
            continue
        end

        % Find the path for each trial day and all the subfolders
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

        % Print the original path and the subfolders
        fprintf('The path for the day of trials processed is: %s\n', path);
        fprintf('The folders to be processed are the following:\n');
        for sbFl = 1:length(subFolders)
            fprintf('Subfolder #%d = %s\n', sbFl, subFolders(sbFl).name);
        end
        fprintf('\n')
        % For all the devices (both RSUs and OBUs), get the transmitted and the
        % received packets and save them in different files.

        fprintf('############## Start processsing the trial data ##############\n');
        for sbFl = 1:length(subFolders)
            fprintf('\n### Processing all files in subfolder #%d = %s ###\n\n', sbFl, subFolders(sbFl).name);

            % Process the files in the OBU side
            if contains(subFolders(sbFl).name,'obu') || contains(subFolders(sbFl).name,'OBU')
                expPath = [ path '/' subFolders(sbFl).name ];
                trialFiles = dir(expPath);
                dirFlags = [trialFiles.isdir];
                trialFiles = trialFiles(~dirFlags);
                for file = 1:length(trialFiles)
                    
                    % If the files are already preprocessed, ignore the log
                    % files generated before
                    if contains(trialFiles(file).name,'.log')
                        continue
                    end
                    
                    % Find if this is an HP or an LP transceiver
                    if contains(trialFiles(file).name,'HP')
                        txPowerInd = 'HP';
                    else
                        txPowerInd = 'LP';
                    end
                    fprintf('The file to be processed is: %s   ---   ', trialFiles(file).name);
                    newFileName = strsplit(subFolders(sbFl).name,'-');
                    if contains(trialFiles(file).name,'tcp')
                        fprintf('This is a TCPDump file\n');
                        command = [ tcpDumpCommand ' ' expPath '/' trialFiles(file).name ' -tt | grep "dB" > ' expPath '/vehNo_' newFileName{2} '_tcpDump_' txPowerInd '.log' ];
                        system(command);
                    else
                        fprintf('This is a text file\n');
                        command = [ 'grep -a "TX-REQ-CAM" ' expPath '/' trialFiles(file).name ' > ' expPath '/vehNo_' newFileName{2} '_TxCAM_' txPowerInd '.log' ];
                        system(command);
                        command = [ 'grep -a "RX-REQ-CAM" ' expPath '/' trialFiles(file).name ' > ' expPath '/vehNo_' newFileName{2} '_RxCAM_' txPowerInd '.log' ];
                        system(command);
                    end
                end
            % Process the files in the RSU side    
            else
                expPath = [ path '/' subFolders(sbFl).name ];
                trialFiles = dir(expPath);
                dirFlags = [trialFiles.isdir];
                trialFiles = trialFiles(~dirFlags);
                for file = 1:length(trialFiles)
                    % If the files are already preprocessed, ignore the log
                    % files generated before
                    if contains(trialFiles(file).name,'.log')
                        continue
                    end

                    % Find if this is an HP or an LP transceiver
                    if contains(trialFiles(file).name,'HP')
                        txPowerInd = 'HP';
                    else
                        txPowerInd = 'LP';
                    end

                    % Find the name of the RSU to be processed
                    if contains(trialFiles(file).name,'HW')
                        rsuName = 'HW';
                    elseif contains(trialFiles(file).name,'MVB')
                        rsuName = 'MVB';
                    elseif contains(trialFiles(file).name,'SU')
                        rsuName = 'SU';
                    elseif contains(trialFiles(file).name,'DH')
                        rsuName = 'DH';
                    end

                    fprintf('The file to be processed is: %s   ---   ', trialFiles(file).name);
                    if contains(trialFiles(file).name,'TCP')
                        fprintf('This is a TCPDump file\n');
                        command = [ tcpDumpCommand ' ' expPath '/' trialFiles(file).name ' -tt | grep "dB" > ' expPath '/' rsuName '_tcpDump_' txPowerInd '.log' ];
                        system(command);
                    else
                        fprintf('This is a text file\n');
                        command = [ 'grep -a "TX-REQ-CAM" ' expPath '/' trialFiles(file).name ' > ' expPath '/' rsuName '_TxCAM_' txPowerInd '.log' ];
                        system(command);
                        command = [ 'grep -a "RX-REQ-CAM" ' expPath '/' trialFiles(file).name ' > ' expPath '/' rsuName '_RxCAM_' txPowerInd '.log' ];
                        system(command);
                    end
                end
            end
        end
    end
    fprintf('\n############## Phase 1 Complete: Processing of all files was successfully completed. ##############\n\n\n');
end

