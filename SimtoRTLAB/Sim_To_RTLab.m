% Generation file from Simulink to RTLab 
% 2023 November 
% Author: Alessia Sagripanti 
%% 
clear
clc
%% Parameters of RT-LAB simulation
%%% Insert Time Step of Real Time Simulation and frequency 
prompt = {'Time step of Real Time Simulation:','Nominal Frequency of the simulated grid:'};
dlg_title = 'Parameter Simulation RT-LAB ';
num_lines= 1;
def     = {'1e-5','50'}; %Default 
answer  = inputdlg(prompt,dlg_title,num_lines,def);
Ts = str2double(cell2mat(answer(1)));
Fn= str2double(cell2mat(answer(2))); %Hz 

%%% Insert Number of Output of SM and SC  
prompt = {'Number of Ouput of SM:','Number of Ouput of SC:'};
dlg_title = 'Parameter Simulation RT-LAB ';
num_lines= 1;
def     = {'1','1'}; %Default 
answer  = inputdlg(prompt,dlg_title,num_lines,def);
SM_Output = str2double(cell2mat(answer(1)));
SC_Output= str2double(cell2mat(answer(2))); 


%% From Simulink File 
casefile = 'Simulazione_1_DM'; %TO do selector vbetween files 
% explore cerchi file 
% rimuovi DM 
fname=[num2str(casefile) '_RTLAB'];

%Check if the file already exists and delete it if it does
if exist(fname,'file') == 4
    % If it does then check whether it's open
    if bdIsLoaded(fname)
        % If it is then close it (without saving!)
        close_system(fname,0)
    end
    % delete the file
    delete([fname,'.slx']);
end
new_system(fname);

%% Block SM 
add_block('built-in/Subsystem',[ fname '/SM']);
load_system(num2str(casefile)) % Load your file Simulink with the simulation grid 
Simulink.BlockDiagram.copyContentsToSubsystem(num2str(casefile),[ fname '/SM'])
add_block('rtlab/OpComm',[ fname '/SM/OpComm']); %add OpComm 
add_block('built-in/Inport',[ fname '/SM/Inport']);
add_block('built-in/Outport',[ fname '/SM/Outport']);
add_block('built-in/Demux',[ fname '/SM/Demux']);
set_param(([fname  '/SM/Demux']),'Outputs', num2str(SC_Output));
add_block('built-in/Mux',[ fname '/SM/Mux']);
set_param(([fname  '/SM/Mux']),'Inputs', num2str(SM_Output));

% Check if powergui already present in SM (power gui has to be external in RTLAB) 
if getSimulinkBlockHandle([fname,'/SM/powergui']) ~= -1 
    % delete the powergui
    delete_block([fname,'/SM/powergui']);
end

% %Inport-OpCom-Demux line 
add_line([fname '/SM'],'Inport/1','OpComm/1');
add_line([fname '/SM'],'OpComm/1','Demux/1');
%Mux-Outport line 
add_line([fname '/SM'],'Mux/1','Outport/1');

%Rearrange the subsystem 
Simulink.BlockDiagram.arrangeSystem([ fname '/SM'])
%% Block SC 
% Create Op Comm, Input and Ouput port 
add_block('built-in/Subsystem',[ fname '/SC']);
add_block('rtlab/OpComm',[ fname '/SC/OpComm']);
add_block('built-in/Inport',[ fname '/SC/Inport']);
add_block('built-in/Outport',[ fname '/SC/Outport']);
%Demux 
add_block('built-in/Demux',[ fname '/SC/Demux']);
set_param(([fname  '/SC/Demux']),'Outputs', num2str(SM_Output));
%Mux
add_block('built-in/Mux',[ fname '/SC/Mux']);
set_param(([fname  '/SC/Mux']),'Inputs', num2str(SC_Output)); 
% %Inport-OpCom-Demux line 
add_line([fname '/SC'],'Inport/1','OpComm/1');
add_line([fname '/SC'],'OpComm/1','Demux/1');
%Mux-Outport line 
add_line([fname '/SC'],'Mux/1','Outport/1');


%Rearrange the subsystem 
Simulink.BlockDiagram.arrangeSystem([ fname '/SC'])
%% External to SM and SC

%Powergui 
add_block('powerlib/powergui',([fname '/powergui']));
set_param(([fname '/powergui']),'SimulationMode','Discrete',...
            'SampleTime','Ts',...
            'frequency', 'Fn');
%Connection SM and SC 
add_line(fname,'SM/1','SC/1')
add_line(fname,'SC/1','SM/1')

%% Setting for Real Time Simulazione 
set_param(fname, 'Solver','ode4');
set_param(fname, 'FixedStep','Ts');
set_param(fname, 'BlockReduction','off');
set_param(fname, 'OptimizeBlockIOStorage','off'); 

% Rearrange all 
Simulink.BlockDiagram.arrangeSystem(fname);
save_system(fname);
open_system(fname);