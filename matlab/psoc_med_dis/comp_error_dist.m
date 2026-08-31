
%% comparacion de distancia
%se medio en intervalos de distancia de 1cm, desde 0cm hasta 19cm, se
%realizaron 10 medidas para cada punto de distancia 

% Hay 7 variaciones del algoritmo original:

% normal                                                    
% filtrado de la derivada con fir_dem2                      
% promediado de la derivada                                 
% interpolado                                               
% interpolado con filtrado de la derivada con fir_dem2      
% interpolado con promediado de la derivada                 	
% interpolado con promediado de la derivada y dem2          
% por recta con ajustes de minimos cuadrados 				


%% Graficar los resultados 

% NORMAL:
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\normal_dist.mat');


i= 1;
while (i < 21)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     error(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(error(i,:));
     sigma_pasos(i) = std(error(i,:));

    i = i+1;
end

indice = [-10:1:10];

figure
subplot(211)
plot(indice,promedio_dist,'*')
title('Normal, Promedio Distancias')
subplot(212)
plot(indice,sigma_dist,'*')
title('Normal, STD Distancias')


% NORMAL CON FILTRO DEM2:
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\normal_dem2_dist.mat');

i= 1;
while (i < 21)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     error(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(error(i,:));
     sigma_pasos(i) = std(error(i,:));

    i = i+1;
end

indice = [-10:1:10];

figure
subplot(211)
plot(indice,promedio_dist,'*')
title('Dem2, Promedio Distancias')
subplot(212)
plot(indice,sigma_dist,'*')
title('Dem2, STD Distancias')

% NORMAL CON PROMEDIO DE LA DERIVADA:
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\normal_prom_dist.mat');

i= 1;
while (i < 22)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     error(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(error(i,:));
     sigma_pasos(i) = std(error(i,:));

    i = i+1;
end

indice = [-10:1:10];

figure
subplot(211)
plot(indice,promedio_dist,'*')
title('Prom, Promedio Distancias')
subplot(212)
plot(indice,sigma_dist,'*')
title('Prom, STD Distancias')


% INTERPOLACION
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\int_dist.mat');

i= 1;
while (i < 22)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     error(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(error(i,:));
     sigma_pasos(i) = std(error(i,:));

    i = i+1;
end

indice = [-10:1:10];

figure
subplot(211)
plot(indice,promedio_dist,'*')
title('Int, Promedio Distancias')
subplot(212)
plot(indice,sigma_dist,'*')
title('Int, STD Distancias')

% INTERPOLACION CON FILTRO SUAVIZADOR DEM2
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\int_dem2_dist.mat');

i= 1;
while (i < 22)
   promedio_dist(i) = mean(aux.Distancia(i,:)); 
    sigma_dist(i) = std(aux.Distancia(i,:));
     error(i,:) = aux.TOF2_v(i,:) - aux.TOF1_v(i,:);
     promedio_pasos(i) = mean(error(i,:));
     sigma_pasos(i) = std(error(i,:));

    i = i+1;
end

indice = [-10:1:10];

figure
subplot(211)
plot(indice,promedio_dist,'*')
title('Int Dem2, Promedio Distancias')
subplot(212)
plot(indice,sigma_dist,'*')
title('Int Dem2, STD Distancias')
