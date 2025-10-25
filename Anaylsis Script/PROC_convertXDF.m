% % CONVERT XDF FILES & MAP SOUND ONSET TRIGGERS 
% ----------------------------------------------
% The code loads the EEG XDF file(s) and save it as .set EEGLAB files with 
% the right channel location files.
% 
% Author:   Abin Jacob 
%           Carl von Ossietzky Universität Oldenburg
%           abin.jacob@uni-oldenburg.de
% Date  : 25/10/2025


clear; clc; close all;

% -------------------------------------------------------------------------
% ---------------------------- CONVERSION SETUP ---------------------------

% root path to the project
rootpath     = '/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project';

% path to the data folder 
foldername  = 'SUB01_24102025';

% file to convert : 
% add a specific filename or 'ALL' to convert all files in folder
file2convert = 'ALL';

% -------------------------------------------------------------------------



% set current directory
cd(fullfile(rootpath, 'Analysis Scripts'));
display('Directory Changed')

% set path to files
filepath = fullfile(rootpath,foldername);

% create list of files to convert
if strcmp(file2convert, 'ALL')
    filelist = dir(fullfile(filepath, '*.xdf'));
else
    filelist = dir(fullfile(filepath, file2convert));
end 

display(['Files to convert: ', num2str(length(filelist))])
display('Converting XDF files to .SET')

% opeing EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% loop over files to convert
for file = 1:length(filelist)
    
    % current working file 
    file2load = fullfile(filepath, filelist(file).name);
    % define setname
    namesplit = strsplit(filelist(file).name, '-');
    setname = strrep(namesplit{4}, '_run', '');
    display(['Converting ', setname])

    % load actual EEG file in EEGLAB
    EEG = pop_loadxdf(file2load,'streamname','Explore_DAAH_ExG');
    % set channel locs
    EEG = pop_chanedit(EEG, {'lookup','/Users/abinjacob/Documents/NeuroCFN/eeglab2023.1/plugins/dipfit/standard_BEM/elec/standard_1005.elc'},'load',{'/Users/abinjacob/Documents/NeuroCFN/eeglab2023.1/sample_data/eeglab_chan32.locs','filetype','autodetect'});

    % save the dataset to filepath 
    EEG.setname = setname;
    EEG.comments = '';
    EEG = pop_saveset(EEG, [EEG.setname, '.set'], filepath);

end 

display('Conversion Complete')

