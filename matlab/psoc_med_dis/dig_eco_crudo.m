%% medidor de distancia utilizando solamente el eco crudo para la correlacion

%para probar el algoritmo de de medicion en matlab pero con los datos
%digitalizados por el psoc, se utiliza el vector del eco
clear all 
%close all

fc = 40e3;     %frecuencia de resonancia del sensor
fs = 400e3;      %frecuencia de muestreo
N = 1024;
%%  
%Longitud del vector de datos
longitud = 1024;
%Frecuencia de muestreo
fs=0.4e6;
Ts=1/fs;


%% Tomaremos como referencia el eco que esta en la mitad del trayecto medido.
% los ecos se empezaron a digitalizar a una distancia de 20cm entre los
% transductores y finalizo a una distancia de 40cm con intervalos de 1cm
% por lo que nuestra referencia sera el eco tomado en el medio, el eco en
% la posicion del indice 11 del vector de ecos.

aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\ecos_digitalizados_no_interf.mat');
eco = aux.ecos;
temperatura = aux.temperatura;

eco_refe = squeeze(eco(11,1,:));

% figure
% plot(eco_refe)
% title('Eco de referencia')

%se normaliza la derivada
[max_d, max_i] = max(eco_refe);
eco_refe = (1/max_d).*eco_refe;

%% Elegimos el patron

figure
plot(eco_refe)
title('Eco de referencia')

disp("Enter para elegir el patron")
pause
%se selecciona cual sera el patron, esto se hace seleccionando una ventana
%temporanl en la curva de la envolventa derivada
[ind val] = ginput(2);

%Se define el patron desde la derivada
patron = eco_refe(floor(ind(1,1)):floor(ind(2,1)));
%patron = filter(patron_lp,1,patron_0);
figure
plot(patron);
title('patron')

%% hallamos el indice maximo de la correlacion de referencia.
correlacion =  xcorr(eco_refe,patron);
[V1 TOF1] = max(correlacion);

%% iniciamos las mediciones a partir de la referencia tomada

flag = 1;
count_med = 1;
count_dist = 1;

while(count_dist < 22)
    while(count_med <11)
    %se toma la siguiente medida
    eco_med = squeeze(eco(count_dist,count_med,:));

    %se normaliza el eco
    [max_d, max_i] = max(eco_med);
    eco_med = (1/max_d).*eco_med;

    %% CORRELACION DE LA SENHAL medida (EL 2DO ECO digitalizado)
    correlacion  =  xcorr(eco_med ,patron);
    [V2 TOF2] = max( correlacion );

    %% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes

    TOF1_v(count_dist,count_med) = TOF1
    TOF2_v(count_dist,count_med) = TOF2
    Distancia(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2-TOF1)*1/(fs)]

    count_med = count_med + 1;
    
   
    end
    
    count_dist = count_dist + 1;
    count_med = 1;
    
end

%solo para la presentacion
figure
plot(correlacion)

%% graficamos el error de las mediciones
valor_real = [-100:10:100];

XMIN = -10;
XMAX = 10;
YMIN = -2;
YMAX = 2;
% Solo interpolacion:
%aux = load('D:\Google Drive\TESIS FM\Psoc\Datos_mediciones\int_tia.mat');

i= 1;
while (i < 22)
   promedio_dist(i) = mean(Distancia(i,:)); 
   sigma_dist(i) = std(Distancia(i,:));
   error(i) = valor_real(i) - promedio_dist(i);
    i = i+1;
end

indice = [-10:1:10];

figure
subplot(311)
plot(indice,promedio_dist,'*')
title('DIG ECO CRUDO, Promedio Distancias')
subplot(312)
plot(indice,sigma_dist,'*')
title('DIG ECO CRUDO, STD Distancias')
subplot(313)
plot(indice,error,'*')
title('Error')
%axis([XMIN XMAX YMIN YMAX])

