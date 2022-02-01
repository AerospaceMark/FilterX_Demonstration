% Welcome to FilterX_Demonstration!
% To begin, you'll have to add the path to the entire code. This is most
% easily done by
%
% >>addpath(genpath('Path to folder containing this file.'))
%
% Once all the code is added to the MATLAB path, this script should work
% without any other adjustments needed.
%
% Tip: If you ever get stuck in a long animation, hold 'control-c' in the
% MATLAB Command Window until the animation stops and the '>>' symbols
% return in the Command Window.
%
% Enjoy!

clearvars; close all;

% Critical Parameters
NumCoefficients = 20; % For filter
PlantDelay = 4; % milliseconds (delta)
ControllerDelay = 3; % milliseconds (tau)
ControlParameter = 0.01; % mu
RecordingTime = 0.5; % seconds
Pcoeff = 0.99; % Transfer function coefficient from source to receiver
Fcoeff = 0.00; % Transfer function coefficient for feedback
Hcoeff = 0.99; % Transfer function coefficient for filter
AddedNoiseToError = 0; % How much noise to add to the error signal

% Noise Options
NoiseType = 'noise'; % 'tone', 'noise'
ToneFrequency = 220; % Only useful if using a 'tone' in NoiseType

% Online Passive Identification (Be patient, this can take some time to get
% going and you see results in the animation.)
PassiveID_H = false; % Whether to passively identify the filter transfer function
PassiveID_P = false; % Whether to passively identify the source-receiver transfer function
Alpha = 0.01; % Passive ID coefficient (large = fast, but maybe unstable)

% Plotting Options
Animate = true; % Whether to animate the entire recording (slows down the simulation)
ProduceFinalPlot = true; % Whether to produce a summary plot
ProduceAttenuationPlot = false; % Whether to produce final overall attenuation plot
ProducePassiveIDPlot = true; % Whether to plot spectra for PassiveID results


%-----Don't touch anything below this line-----%
[attenuation, times, SNR_extraNoise] = filterX('NumCoefficients',NumCoefficients,...
                                                'ControllerDelay',ControllerDelay,...
                                                'PlantDelay',PlantDelay,...
                                                'ControlParameter',ControlParameter,...
                                                'Animate',Animate,...
                                                'ProduceFinalPlot',ProduceFinalPlot,...
                                                'NoiseType',NoiseType,...
                                                'ToneFrequency',ToneFrequency,...
                                                'RecordingTime',RecordingTime,...
                                                'Pcoeff',Pcoeff,...
                                                'Fcoeff',Fcoeff,...
                                                'Hcoeff',Hcoeff,...
                                                'ProduceAttenuationPlot',ProduceAttenuationPlot,...
                                                'AddedNoiseToError',AddedNoiseToError,...
                                                'PassiveID_H',PassiveID_H,...
                                                'PassiveID_P',PassiveID_P,...
                                                'Alpha',Alpha,...
                                                'ProducePassiveIDPlot',ProducePassiveIDPlot);
