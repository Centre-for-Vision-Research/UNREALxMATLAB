function CameraToWorldTransform(block, i)
%MSFUNTMPL_BASIC A Template for a Level-2 MATLAB S-Function
%   The MATLAB S-function is written as a MATLAB function with the
%   same name as the S-function. Replace 'msfuntmpl_basic' with the 
%   name of your S-function.

%   Copyright 2003-2018 The MathWorks, Inc.

%%
%% The setup method is used to set up the basic attributes of the
%% S-function such as ports, parameters, etc. Do not add any other
%% calls to the main body of the function.
%%
setup(block);

%endfunction

%% Function: setup ===================================================
%% Abstract:
%%   Set up the basic characteristics of the S-function block such as:
%%   - Input ports
%%   - Output ports
%%   - Dialog parameters
%%   - Options
%%
%%   Required         : Yes
%%   C MEX counterpart: mdlInitializeSizes
%%
function setup(block)

% Register number of ports
%i = 0;
block.NumInputPorts  = 2;
block.NumOutputPorts = 2;

% Setup port properties to be inherited or dynamic
block.SetPreCompInpPortInfoToDynamic;
block.SetPreCompOutPortInfoToDynamic;

% Override input port properties
% Transform inputs(1)
block.InputPort(1).Dimensions        = 3;   % Translation
block.InputPort(1).DatatypeID  = 1;  % single
block.InputPort(1).Complexity  = 'Real';
block.InputPort(1).DirectFeedthrough = true;

% Transform inputs(2)
block.InputPort(2).Dimensions        = 3;   % Orientation
block.InputPort(2).DatatypeID  = 1;  %single
block.InputPort(2).Complexity  = 'Real';
block.InputPort(2).DirectFeedthrough = true;

% Override output port properties
block.OutputPort(1).Dimensions       = [4 2];    % A B C D points
block.OutputPort(1).DatatypeID  = 1; % double
block.OutputPort(1).Complexity  = 'Real';
block.OutputPort(1).SamplingMode = 'Sample';

block.OutputPort(2).Dimensions       = [4 2];   % unreal to world transform
block.OutputPort(2).DatatypeID  = 1; % double
block.OutputPort(2).Complexity  = 'Real';
block.OutputPort(2).SamplingMode  = 'Sample';

% block.OutputPort(3).Dimensions       = 3;  % Occupancy grid to unreal transform
% block.OutputPort(3).DatatypeID  = 0; % double
% block.OutputPort(3).Complexity  = 'Real';
% block.OutputPort(3).SamplingMode  = 'Sample';
% 
% block.OutputPort(4).Dimensions       = 3;   % Unreal to occupancy grid transform
% block.OutputPort(4).DatatypeID  = 0; % double
% block.OutputPort(4).Complexity  = 'Real';
% block.OutputPort(4).SamplingMode = 'Sample';

% block.OutputPort(5).Dimensions       = 1;
% block.OutputPort(5).DatatypeID  = 0; % double
% block.OutputPort(5).Complexity  = 'Real';
% block.OutputPort(5).SamplingMode  = 'Sample';
% 
% block.OutputPort(6).Dimensions       = 1;
% block.OutputPort(6).DatatypeID  = 0; % double
% block.OutputPort(6).Complexity  = 'Real';
% block.OutputPort(6).SamplingMode  = 'Sample';
% 
% block.OutputPort(4).Dimensions       = 1;
% block.OutputPort(4).DatatypeID  = 0; % double
% block.OutputPort(4).Complexity  = 'Real';
% Register parameters
block.NumDialogPrms     = 0;

% Register sample times
%  [0 offset]            : Continuous sample time
%  [positive_num offset] : Discrete sample time
%
%  [-1, 0]               : Inherited sample time
%  [-2, 0]               : Variable sample time
block.SampleTimes = [0.2 0];

% Specify the block simStateCompliance. The allowed values are:
%    'UnknownSimState', < The default setting; warn and assume DefaultSimState
%    'DefaultSimState', < Same sim state as a built-in block
%    'HasNoSimState',   < No sim state
%    'CustomSimState',  < Has GetSimState and SetSimState methods
%    'DisallowSimState' < Error out when saving or restoring the model sim state
block.SimStateCompliance = 'DefaultSimState';

%% -----------------------------------------------------------------
%% The MATLAB S-function uses an internal registry for all
%% block methods. You should register all relevant methods
%% (optional and required) as illustrated below. You may choose
%% any suitable name for the methods and implement these methods
%% as local functions within the same file. See comments
%% provided for each function for more information.
%% -----------------------------------------------------------------

block.RegBlockMethod('PostPropagationSetup',    @DoPostPropSetup);
block.RegBlockMethod('InitializeConditions', @InitializeConditions);
block.RegBlockMethod('Start', @Start);
block.RegBlockMethod('Outputs', @Outputs);     % Required
block.RegBlockMethod('Update', @Update);
block.RegBlockMethod('Derivatives', @Derivatives);
block.RegBlockMethod('Terminate', @Terminate); % Required
block.RegBlockMethod('SetInputPortSamplingMode', @SetInputPortSamplingMode);

%end setup

%%
%% PostPropagationSetup:
%%   Functionality    : Setup work areas and state variables. Can
%%                      also register run-time methods here
%%   Required         : No
%%   C MEX counterpart: mdlSetWorkWidths
%%
function DoPostPropSetup(block)
block.NumDworks = 1;
  
  block.Dwork(1).Name            = 'x1';
  block.Dwork(1).Dimensions      = 1;
  block.Dwork(1).DatatypeID      = 0;      % double
  block.Dwork(1).Complexity      = 'Real'; % real
  block.Dwork(1).UsedAsDiscState = true;


%%
%% InitializeConditions:
%%   Functionality    : Called at the start of simulation and if it is 
%%                      present in an enabled subsystem configured to reset 
%%                      states, it will be called when the enabled subsystem
%%                      restarts execution to reset the states.
%%   Required         : No
%%   C MEX counterpart: mdlInitializeConditions
%%
function InitializeConditions(block)

%end InitializeConditions

function SetInputPortSamplingMode(block, idx, fd)
 block.InputPort(idx).SamplingMode = fd;
  block.OutputPort(1).SamplingMode  = fd;
 block.OutputPort(2).SamplingMode = fd;
%   block.OutputPort(3).SamplingMode = fd;
%   block.OutputPort(4).SamplingMode = fd;
%   block.OutputPort(5).SamplingMode = fd;
%   block.OutputPort(6).SamplingMode = fd;

%end SetInputPortSamplingMode

%%
%% Start:
%%   Functionality    : Called once at start of model execution. If you
%%                      have states that should be initialized once, this 
%%                      is the place to do it.
%%   Required         : No
%%   C MEX counterpart: mdlStart
%%
function Start(block)
global fov;
global tForm;
load('SimEnvironment.mat','Env')
fov = Env.CameraFOV;
tForm = Env.UnrealToWorldTform;


% env = load('SimEnvironment.mat');
% 
% start = [-271 111 pi/2];      % unreal coordinates
% fin = [180 -330 0];            % unreal coordinates
% wlp = [start(1), start(2), 1] * env.Env.UnrealToWorldTform;
% wrl = [wlp(2)/wlp(3) wlp(1)/wlp(3)];  % lat and long
% figure,geoplot(wrl(1), wrl(2), 'o', 'color', 'r');
% ax = gca;
% drawnow

%end Start

%%
%% Outputs:
%%   Functionality    : Called to generate block outputs in
%%                      simulation step
%%   Required         : Yes
%%   C MEX counterpart: mdlOutputs
%%
function Outputs(block)
global fov;
global tForm;

RotZ = [cos(block.InputPort(2).Data(3)) -sin(block.InputPort(2).Data(3)) 0;sin(block.InputPort(2).Data(3)) cos(block.InputPort(2).Data(3)) 0;0 0 1];
gdPlane = [0 0 0];
h = block.InputPort(1).Data - gdPlane;
dx = h(3)*tan((fov(1)/2)*pi/180);
dy = h(3)*tan((fov(2)/2)*pi/180);
% b = [block.InputPort(1).Data(1) + dx block.InputPort(1).Data(2) + dy 0; block.InputPort(1).Data(1) + dx block.InputPort(1).Data(2) - dy 0;block.InputPort(1).Data(1) - dx block.InputPort(1).Data(2) - dy 0;block.InputPort(1).Data(1) - dx block.InputPort(1).Data(2) + dy 0]'
RectTf = (RotZ*[block.InputPort(1).Data(1) + dx block.InputPort(1).Data(2) + dy 0; block.InputPort(1).Data(1) + dx block.InputPort(1).Data(2) - dy 0;block.InputPort(1).Data(1) - dx block.InputPort(1).Data(2) - dy 0;block.InputPort(1).Data(1) - dx block.InputPort(1).Data(2) + dy 0]')';
block.OutputPort(1).Data = RectTf(:,1:2);  %ouput the unreal coordinates

RectTf(:,3) = 1;
out1 = RectTf * tForm;
WorldOut = out1(:,1:3)./out1(:,3);
block.OutputPort(2).Data = [WorldOut(:,2) WorldOut(:,1)];  %[Lat Long]     %Lat and long world output
%Out

%wlp = [ShipPosN(i,1), ShipPosN(i,2), 1] * InputPort(1);
%        wrl = [wlp(2)/wlp(3) wlp(1)/wlp(3)];  % lat and long
%        geoplot(ax, wrl(1), wrl(2), 'o', 'color', 'r');
%        drawnow


%block.OutputPort(1).Data = block.Dwork(1).Data + block.InputPort(1).Data;
% block.OutputPort(1).Data = env.Env.WorldToUnrealTform;
% block.OutputPort(2).Data = env.Env.UnrealToWorldTform;
% block.OutputPort(3).Data = env.Env.OccupancyGridToUnrealTform;
% block.OutputPort(4).Data = env.Env.UnrealToOccupancyGridTform;

%end Outputs

%%
%% Update:
%%   Functionality    : Called to update discrete states
%%                      during simulation step
%%   Required         : No
%%   C MEX counterpart: mdlUpdate
%%
function Update(block)

%block.Dwork(1).Data = block.InputPort(1).Data;

%end Update

%%
%% Derivatives:
%%   Functionality    : Called to update derivatives of
%%                      continuous states during simulation step
%%   Required         : No
%%   C MEX counterpart: mdlDerivatives
%%
function Derivatives(block)

%end Derivatives

%%
%% Terminate:
%%   Functionality    : Called at the end of simulation for cleanup
%%   Required         : Yes
%%   C MEX counterpart: mdlTerminate
%%
%function PlanPath(block, )
function Terminate(block)

%end Terminate

