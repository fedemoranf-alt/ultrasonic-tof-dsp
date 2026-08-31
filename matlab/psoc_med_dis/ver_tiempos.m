

%ver tiempo de los ecos digitalizados 
clear all
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\ecos_digitalizados.mat');
eco = aux.ecos;
temperatura = aux.temperatura;


eco_refe = squeeze(eco(11,3,:)); 
cant_puntos = max(size(eco_refe));
tiempo = [1:1:cant_puntos];
fs = 400e3;      %frecuencia de muestreo
ts = 1/fs;
tiempo = ts.*tiempo;
figure
plot(tiempo,eco_refe)


