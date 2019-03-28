clc; clf; clear; close all;

origPath = [ '' ];
tcpdumpPath = [''];

importedDataPath = [ 'importedData' ];

% Grep all the log files to create separate files for the transmitted and
% the received packets - per device.
src.trialsProcessing.receiveTransmitGrep(origPath,folders,tcpdumpPath)

% Import all files and save them into a .mat format
src.trialsProcessing.importSave(origPath,folders,importedDataPath)
