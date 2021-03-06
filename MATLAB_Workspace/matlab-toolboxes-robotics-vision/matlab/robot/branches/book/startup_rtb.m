%STARTUP_RVC Initialize MATLAB paths for Robotics Toolbox
%
% Adds demos, examples to the MATLAB path, and adds also to 
% Java class path.
disp('- Robotics Toolbox for Matlab (release 9)')
tbpath = fileparts(which('Link'));
addpath( fullfile(tbpath, 'demos') );
addpath( fullfile(tbpath, 'examples') );
javaaddpath( fullfile(tbpath, 'DH.jar') );
