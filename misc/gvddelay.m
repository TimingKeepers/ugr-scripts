function [result,delay] = gvddelay(ch1,ch2,distance,map)
% GVDDELAY - Returns the transmission time asymmetry caused
% by group velocity dispersion over two different DWDM channels.
%
% Syntax: [result] = gvddelay(ch1,ch2,distance,map)
%
% Inputs:
%   ch1        - Channel number for the forward path according to ITU-T G.694.1
%   ch2        - Channel number for the reverse path according to ITU-T G.694.1
%   distance   - Distance of the fiber optic link (in km).
%   map        - When 1, a graph estimating link asymmetry between every
%                possible channel is provided.
%
% Outputs:
%   result     - The GVD-induced asymmetry, measured in picoseconds
%                for the given channels
%   delays     - The asymmetry for every other channel pair.
%
% Example:
%   delay = gvddelay(54,59,10,0)
%

% Author:  Jose Lopez-Jimenez
%          <joselj>at<ugr.es>
%          Dept. of Computer Architecture and Technology
%          Universidad de Granada
%
% Created:      2018-05-29
% Last version: 2018-05-30
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Zero dispersion wavelength, from Corning SMF-28 datasheet
lambda0=1310; % nanometers

% Slope at zero-dispersion wavelength from Corning SMF-28 datasheet
S0=0.092;  % ps/(nm2 km)

% To evaluate group velocity dispersion at arbitrary wavelengths,
% uncomment and edit these:
lambda=1260:0.01:1620; % nanometers
integratedGVD = S0/8.*lambda.^2.*(1-lambda0^2./lambda.^2).^2; % ps/km

channels=1:72;
freq=190.1e12:0.1e12:197.2e12; % Frequency of the DWDM carriers
c = 299792458; % meters per second
wavelengths=c./freq.*1e9; % Free space wavelengths in nanometers

% The position(i,j) of the following matrix will contain the gvd-induced delay
% between channels i and j
delay=zeros(72);

for i=1:72
    for j=1:72
       res1 =  distance * S0/8.*wavelengths(i).^2.*(1-lambda0^2./wavelengths(i).^2).^2;
       res2 =  distance * S0/8.*wavelengths(j).^2.*(1-lambda0^2./wavelengths(j).^2).^2;
       delay(i,j) = res1-res2;
    end
end

% Representing the delay matrix as a color map.
if(map==1)
    imagesc(delay);
    title('Delay per channel pair');
    xlabel('Channel 1');
    ylabel('Channel 2');
    axis('xy')
    colormap(jet)
    d=colorbar;
    set(get(d,'label'),'string','Relative delay (ps)'); % does not seem to work in octave anyway

    % Only in newer versions of MATLAB:
    % d.Label.String= 'Relative delay (picoseconds)';
end;

result=delay(ch1,ch2);

