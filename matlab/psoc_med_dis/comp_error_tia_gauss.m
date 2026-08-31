
%% comparacion de distancia UTILIZANDO EL ESQUEMA DE AMPLIFICADOR DIFERENCIAL CON 2 TIA
%se medio en intervalos de distancia de 1cm, desde 0cm hasta 19cm, se
%realizaron 10 medidas para cada punto de distancia 

% Hay 7 variaciones del algoritmo original:

% normal                                                    SI
% filtrado de la derivada con fir_dem2                      SI
% promediado de la derivada                                 SI
% interpolado                                               SI
% interpolado con filtrado de la derivada con fir_dem2      SI
% interpolado con promediado de la derivada                 	
% interpolado con promediado de la derivada y dem2          
% por recta con ajustes de minimos cuadrados 				

close all
clear all

%% Graficar los resultados 

valor_real = [-100:10:100];

XMIN = -10;
XMAX = 10;
YMIN = -2;
YMAX = 2;
% NORMAL:
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\normal_tia_gauss.mat');

i= 1;
while (i < 22)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     diff_pasos(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(diff_pasos(i,:));
     sigma_pasos(i) = std(diff_pasos(i,:));
     error(i) = valor_real(i) - promedio_dist(i);
    i = i+1;
end

indice = [-10:1:10];

figure
subplot(311)
plot(indice,promedio_dist,'*')
title('Normal TIA, Promedio Distancias')
subplot(312)
plot(indice,sigma_dist,'*')
title('Normal TIA, STD Distancias')
subplot(313)
plot(indice,error,'*')
title('Error')
axis([XMIN XMAX YMIN YMAX])


% NORMAL CON FILTRO DEM2:
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\normal_dem2_tia_gauss.mat');

i= 1;
while (i < 22)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     diff_pasos(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(diff_pasos(i,:));
     sigma_pasos(i) = std(diff_pasos(i,:));
     error(i) = valor_real(i) - promedio_dist(i);
    i = i+1;
end

indice = [-10:1:10];

figure
subplot(311)
plot(indice,promedio_dist,'*')
title('Dem2 TIA, Promedio Distancias')
subplot(312)
plot(indice,sigma_dist,'*')
title('Dem2 TIA, STD Distancias')
subplot(313)
plot(indice,error,'*')
title('Error')
axis([XMIN XMAX YMIN YMAX])

% NORMAL CON PROMEDIO DE LA DERIVADA:
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\normal_prom_tia_gauss.mat');

i= 1;
while (i < 22)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     diff_pasos(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(diff_pasos(i,:));
     sigma_pasos(i) = std(diff_pasos(i,:));
     error(i) = valor_real(i) - promedio_dist(i);
    i = i+1;
end

indice = [-10:1:10];

figure
subplot(311)
plot(indice,promedio_dist,'*')
title('Prom TIA, Promedio Distancias')
subplot(312)
plot(indice,sigma_dist,'*')
title('Prom TIA, STD Distancias')
subplot(313)
plot(indice,error,'*')
title('Error')
axis([XMIN XMAX YMIN YMAX])

% INTERPOLACION
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\int_tia_gauss.mat');

i= 1;
while (i < 22)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     diff_pasos(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(diff_pasos(i,:));
     sigma_pasos(i) = std(diff_pasos(i,:));
     error(i) = valor_real(i) - promedio_dist(i);
    i = i+1;
end

indice = [-10:1:10];

figure
subplot(311)
plot(indice,promedio_dist,'*')
title('Int TIA, Promedio Distancias')
subplot(312)
plot(indice,sigma_dist,'*')
title('Int TIA, STD Distancias')
subplot(313)
plot(indice,error,'*')
title('Error')
axis([XMIN XMAX YMIN YMAX])

% INTERPOLACION CON FILTRO SUAVIZADOR DEM2
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\int_dem2_tia_gauss.mat');

i= 1;
while (i < 22)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     diff_pasos(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(diff_pasos(i,:));
     sigma_pasos(i) = std(diff_pasos(i,:));
     error(i) = valor_real(i) - promedio_dist(i);
    i = i+1;
end

indice = [-10:1:10];

figure
subplot(311)
plot(indice,promedio_dist,'*')
title('Int Dem2 Tia, Promedio Distancias')
subplot(312)
plot(indice,sigma_dist,'*')
title('Int Dem2 Tia, STD Distancias')
subplot(313)
plot(indice,error,'*')
title('Error')
axis([XMIN XMAX YMIN YMAX])

% INTERPOLACION CON PROMEDIO DE LA DERIVADA
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\int_prom_tia_gauss.mat');

i= 1;

while (i < 22)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     diff_pasos(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(diff_pasos(i,:));
     sigma_pasos(i) = std(diff_pasos(i,:));
     error(i) = valor_real(i) - promedio_dist(i);
    i = i+1;
end

indice = [-10:1:10];

figure
subplot(311)
plot(indice,promedio_dist,'*')
title('Int Prom Tia, Promedio Distancias')
subplot(312)
plot(indice,sigma_dist,'*')
title('Int Prom Tia, STD Distancias')
subplot(313)
plot(indice,error,'*')
title('Error')
axis([XMIN XMAX YMIN YMAX])

% INTERPOLACION CON PROMEDIO Y FILTRO DEM2 DE LA DERIVADA
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\int_prom_dem2_tia_gauss.mat');

i= 1;
while (i < 22)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     diff_pasos(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(diff_pasos(i,:));
     sigma_pasos(i) = std(diff_pasos(i,:));
     error(i) = valor_real(i) - promedio_dist(i);
    i = i+1;
end

indice = [-10:1:10];

figure
subplot(311)
plot(indice,promedio_dist,'*')
title('Int Prom Dem2 Tia, Promedio Distancias')
subplot(312)
plot(indice,sigma_dist,'*')
title('Int Prom Dem2 Tia, STD Distancias')
subplot(313)
plot(indice,error,'*')
title('Error')
axis([XMIN XMAX YMIN YMAX])

