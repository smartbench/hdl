% Inicializacion del entorno
%
clc;          % limpia la consola
clear;        % borra workspace
close all;    % cierra los graficos
fclose all;   % cierra archivos

% Unidades
%
seg = 1 ;
ms  = 1e-3 * seg ;
us  = 1e-3 * ms  ;
ns  = 1e-3 * us  ;
%
Hz  = 1/seg ;
KHz = 1/ms  ;
MHz = 1/us  ;
GHz = 1/ns  ;

% Inicializacion del sistema
%
Fs = 100e6; % pll
N = 512;
Ts = 1/Fs;
t = (0:N-1)*Ts;

% Parámetros de la Señal
%
A = 80;
f = 1.953125e6;
ph = 0;
offset = 100;
x = offset + A * sin(2*pi*f*t+ph);
xx = offset * t./t

% Cuantización
%
wordLength = 8;
fracLength = 0;
q = quantizer('mode', 'ufixed', 'format', [wordLength fracLength], ...
        'roundmode', 'nearest', 'overflowmode', 'saturate');
x_q = quantize(q, x); % señal cuantizada

% Plot
%
stem(t,x_q,'.');
grid on;
ylim([0,255]);
hold on;
plot(t,xx,'.');

% Escritura de archivo
%
fileID = fopen('rom.bin','w');
fwrite(fileID, x_q, 'uint8');
fclose(fileID);
fileID = fopen('rom.hex','w');
fprintf(fileID, '%x\n', x_q);
fclose(fileID);
