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
NumCoefficients = 50; % For filter
SampleRate = 1000; % signal sampling frequency
PlantDelay = 0.004; % seconds (delta)
ControllerDelay = 0.003; % seconds (tau)
ControlParameter = 0.01; % mu
RecordingTime = 0.1; % seconds
Pcoeff = 0.99; % Transfer function coefficient from source to receiver
Fcoeff = 0.0; % Transfer function coefficient for feedback
Hcoeff = 0.99; % Transfer function coefficient for filter
AddedNoiseToError = 0; % How much noise to add to the error signal

% Noise Options
NoiseType = 'tone'; % 'tone', 'noise'
ToneFrequency = 220; % Only useful if using a 'tone' in NoiseType

% Online Passive Identification (Be patient, this can take some time to get
% going and you see results in the animation.)
PassiveID_H = false; % Whether to passively identify the filter transfer function
PassiveID_P = false; % Whether to passively identify the source-receiver transfer function
Alpha = 0.01; % Passive ID coefficient (large = fast, but maybe unstable)

% Plotting Options
Animate = true; % Whether to animate the entire recording (slows down the simulation)
WaveformTimeShown = 0.1; % How much time to show at each moment in waveform animation
ProduceFinalPlot = true; % Whether to produce a summary plot
ProduceAttenuationPlot = false; % Whether to produce final overall attenuation plot
ProducePassiveIDPlot = false; % Whether to plot spectra for PassiveID results


%-----Don't touch anything below this line-----%
[attenuation, times, SNR_extraNoise] = filterX('NumCoefficients',NumCoefficients,...
                                                'SampleRate',SampleRate,...
                                                'ControllerDelay',ControllerDelay,...
                                                'PlantDelay',PlantDelay,...
                                                'ControlParameter',ControlParameter,...
                                                'Animate',Animate,...
                                                'WaveformTimeShown',WaveformTimeShown,...
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
