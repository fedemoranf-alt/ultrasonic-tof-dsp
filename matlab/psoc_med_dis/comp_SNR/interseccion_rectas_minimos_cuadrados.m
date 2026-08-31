%% medidor de distancia, 
%para probar el algoritmo de de medicion en matlab pero con los datos
%digitalizados por el psoc, se utiliza el vector del eco
clear all 
%close all

fc = 40e3;     %frecuencia de resonancia del sensor
fs = 400e3;      %frecuencia de muestreo
N = 1024;
M = 0.01; %intervalo entre puntos para la interpolacion de la recta ajustada
%% deriva de amstrong 
%filtro analogico cero - polo frecuencia de corte superior 60000
fss = fc;     %Doble de la frecuencia de la portadora
a = 2*20e3*pi;  %Ancho de banda del transductor
num = [1 0];
den = [1 a]; % se usa el polo para limitar el ancho de banda de la derivada
%Se digitaliza el filtro para hallar la derivada
[numd, dend] = bilinear(num,den,fss);
derivadorS = tf(num,den);
derivadorZ = tf(numd,dend,1); % para tener la ecuacion en diferencia que va en el PSoC


%% filtro demodulador

% fir_dem = [ 0.0043,    0.0052,    0.0073,    0.0109,    0.0157,    0.0217,    0.0285,    0.0359,    0.0435,    0.0508,    0.0574,    0.0631,    0.0673,...
%             0.0700,    0.0709,    0.0700,    0.0673,    0.0631,    0.0574,    0.0508,    0.0435,    0.0359,    0.0285,    0.0217,    0.0157,    0.0109,...
%             0.0073,    0.0052,    0.0043  ];

fir_dem = fir1(65,0.1,blackman(66));


%%  pedimos al psoc el primer eco que usaremos como referencia, se abre el puerto serial:
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

eco_refe = squeeze(eco(11,1,:)); % obs: el patron no debe tener ruido

%% se halla la envolvente utilizando la transformada de hilbert
env_r = abs(hilbert(eco_refe));
env_refe = filter(fir_dem,1,env_r);

% figure
% plot(eco_refe)
% title('Eco y su envolvente, Referencia')
% hold on
% plot(env_refe)

%% Hallaremos una recta entre el 90% y el 10% de valor maximo de la envolvente utilizando el ajuste de minimos cuadrados y luego la intersectaremos con el punto de valor Vmax/2 de la envolvente para obtener el TOF

%se halla el valor maximo de la envolvente:
[env_refe_max_v env_refe_max_i ] = max(env_refe);
env_refe_max_90_v = 0.9*env_refe_max_v; % el valor del 90% del max de la envolvente
%se busca que punto de la envolvente posee el valor del 90% de la misma:
% se resta el valor de env_max_90 con cada punto de la envolvente y busca el que posee el menor error para identificar donde se encuentra el valor de 90% de la envolvente  
error_0 = 1;
for i= 1 : env_refe_max_i
   aux = abs(env_refe_max_90_v - env_refe(i));
   if (aux < error_0) 
        error_0 = aux;
        env_refe_max_90_i = i; 
   end
end

% se realiza el mismo procedimiento para hallar la ubicacion del valor del
% 10% del maximo de la envolvente
env_refe_max_10_v = 0.1*env_refe_max_v;
error_0 = 1;
for i = 1 : env_refe_max_i
   aux = (abs(env_refe_max_10_v - env_refe(i)) + 0.001*abs(i - env_refe_max_i));
   if (aux < error_0)
      error_0 = aux;
      env_refe_max_10_i = i;
   end
end

%% armamos el vector de datos que vamos a ajustar, este va desde env_max_10_i hasta env_max_90_i
voltajes_pa = env_refe(env_refe_max_10_i : env_refe_max_90_i);
indices_pa = [env_refe_max_10_i : 1 : env_refe_max_90_i];
% figure
% plot(indices_pa,voltajes_pa)
% title("Seccion de la envolvente a ajustar, Referencia")

%% procedemos a ajustar los datos a un polinomio de 1er orden, una recta.
% y = a*x + b
coef_refe = polyfit(indices_pa,voltajes_pa',1);
cruce_0_refe = -(coef_refe(2)/coef_refe(1));   % si y=0, -> x = -b/a
indices_pa = [floor(cruce_0_refe) : 1: env_refe_max_90_i];
recta_ajustada_refe = polyval(coef_refe,indices_pa);

% figure
% plot(indices_pa,recta_ajustada_refe)
% title("Recta ajustada, Referencia")

%% ahora debemos de hallar la interseccion de la recta con el valor de Vmax/2 de la envolvente, este punto sera el TOF de referencia

%para mejorar aca se debe de interpolar la recta antes de hallar la interseccion para mejor resolucion 
%% Interpolacion de la recta ajustada
indices_int = [cruce_0_refe : 0.01 : env_refe_max_90_i]; 
recta_ajustada_refe_int = interp1(indices_pa,recta_ajustada_refe,indices_int);
% figure
% plot(indices_int,recta_ajustada_refe_int)
% title("recta ajustada interpolada, Referencia")
%%
longitud_recta_int = max(size(recta_ajustada_refe_int));
error_0 = 1;
for i= 1 : longitud_recta_int
   aux = abs((env_refe_max_v/2)- recta_ajustada_refe_int(i));
   if (aux < error_0) 
        error_0 = aux;
        interseccion_recta_refe = indices_int(i); 
   end
end

recta_Vmax2_refe = ones(longitud);
recta_Vmax2_refe = (env_refe_max_v/2).*recta_Vmax2_refe; % solo para graficar

figure
%subplot(211)
plot(eco_refe)
title('Eco y su envolvente, Referencia')
hold on
plot(env_refe)
hold on
plot(indices_pa,recta_ajustada_refe,'r')
%subplot(212)
figure
plot(env_refe)
hold on
plot(indices_int,recta_ajustada_refe_int)
hold on
plot(recta_Vmax2_refe)
hold on
plot(interseccion_recta_refe,env_refe_max_v/2,'*')
hold on
plot(cruce_0_refe,0,'*')
%title("Interseccion Referencia")

TOF1 = interseccion_recta_refe;
TOF1_0 = cruce_0_refe;

%% iniciamos las mediciones a partir de la referencia tomada
disp("Presione una tecla para continuar e iniciar las mediones de distancia")
pause

flag = 1;
count_med = 1;
count_dist = 1;

while(count_dist < 22)
    while(count_med <11)
        eco_med = squeeze(eco(count_dist,count_med,:));
        
        %% se halla la envolvente utilizando la transformada de hilbert
        env_r = abs(hilbert(eco_med));
        env_med = filter(fir_dem,1,env_r);

%         figure
%         plot(eco_med)
%         title('Eco y su envolvente, Medida')
%         hold on
%         plot(env_med)

        %% Hallaremos una recta entre el 90% y el 10% de valor maximo de la envolvente utilizando el ajuste de minimos cuadrados y luego la intersectaremos con el punto de valor Vmax/2 de la envolvente para obtener el TOF

        %se halla el valor maximo de la envolvente:
        [env_med_max_v env_med_max_i ] = max(env_med);
        env_med_max_90_v = 0.9*env_med_max_v; % el valor del 90% del max de la envolvente
        %se busca que punto de la envolvente posee el valor del 90% de la misma:
        % se resta el valor de env_max_90 con cada punto de la envolvente y busca el que posee el menor error para identificar donde se encuentra el valor de 90% de la envolvente  
        error_0 = 1;
        for i= 1 : env_med_max_i
           aux = abs(env_med_max_90_v - env_med(i));
           if (aux < error_0) 
                error_0 = aux;
                env_med_max_90_i = i; 
           end
        end

        % se realiza el mismo procedimiento para hallar la ubicacion del valor del
        % 10% del maximo de la envolvente
        env_med_max_10_v = 0.1*env_med_max_v;
        error_0 = 1;
        for i = 1 : env_med_max_i
           aux = (abs(env_med_max_10_v - env_med(i)) + 0.001*abs(i - env_med_max_i));
           if (aux < error_0)
              error_0 = aux;
              env_med_max_10_i = i;
           end
        end

        %% armamos el vector de datos que vamos a ajustar, este va desde env_max_10_i hasta env_max_90_i
        voltajes_pa_med = env_med(env_med_max_10_i : env_med_max_90_i,1);
        indices_pa_med = [env_med_max_10_i : 1: env_med_max_90_i];
%         figure
%         plot(indices_pa_med,voltajes_pa_med)
%         title("Seccion de la envolvente a ajustar, Medida")

        %% procedemos a ajustar los datos a un polinomio de 1er orden, una recta.
        % y = a*x + b
        coef_med = polyfit(indices_pa_med,voltajes_pa_med',1);
        cruce_0_med = -(coef_med(2)/coef_med(1));   % si y=0, -> x = -b/a
        indices_pa_med = [floor(cruce_0_med) : 1: env_med_max_90_i];
        recta_ajustada_med = polyval(coef_med,indices_pa_med);

%         figure
%         plot(indices_pa_med,recta_ajustada_med)
%         title("Recta ajustada, Medida")

        %% ahora debemos de hallar la interseccion de la recta con el valor de Vmax/2 de la envolvente, este punto sera el TOF de medrencia

        %para mejorar aca se debe de interpolar la recta antes de hallar la interseccion para mejor resolucion 
        %% Interpolacion de la recta ajustada
        indices_int = [cruce_0_med : 0.01 : env_med_max_90_i]; 
        recta_ajustada_med_int = interp1(indices_pa_med,recta_ajustada_med,indices_int);
%         figure
%         plot(indices_int,recta_ajustada_med_int)
%         title("recta ajustada interpolada, Medida")
        %%
        longitud_recta_int = max(size(recta_ajustada_med_int));
        error_0 = 1;
        for i= 1 : longitud_recta_int
           aux = abs((env_med_max_v/2)- recta_ajustada_med_int(i));
           if (aux < error_0) 
                error_0 = aux;
                interseccion_recta_med = indices_int(i); 
           end
        end

        recta_Vmax2_med = ones(longitud);
        recta_Vmax2_med = (env_med_max_v/2).*recta_Vmax2_med; % solo para graficar

        TOF2 = interseccion_recta_med;
        TOF2_0 = cruce_0_med;



        %% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes
        Distancia(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2-TOF1)*1/(fs)];
        Distancia_0(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_0-TOF1_0)*1/(fs)];
    
        count_med = count_med + 1;
    
    end
    
    count_dist = count_dist + 1;
    count_med = 1;
    
end

%% Se guardan los datos de las mediciones en un archivo.m
%save('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\cruce_0_method.mat','Distancia','Distancia_0')

close all
clear all

%% Graficamos los resultados
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\cruce_0_method.mat');

valor_real = [-100:10:100];
XMIN = -10;
XMAX = 10;
YMIN = -5;
YMAX =5;

%Grafico de interseccion de la recta con Vmax/2
i= 1;
while (i < 22)

   promedio_dist(i) = mean(aux.Distancia(i,:)); 
   sigma_dist(i) = std(aux.Distancia(i,:));
   error(i) = valor_real(i) - promedio_dist(i);

    i = i+1;
end

indice = [-10:1:10];

figure
errorbar(valor_real,error, sigma_dist)
title('Interseccion de la recta con Vmax/2')

%Grafico de interseccion de la recta con 0
i= 1;
while (i < 22)

   promedio_dist_0(i) = mean(aux.Distancia_0(i,:)); 
   sigma_dist_0(i) = std(aux.Distancia_0(i,:));
   error_0(i) = valor_real(i) - promedio_dist_0(i);

    i = i+1;
end

indice = [-10:1:10];

figure
errorbar(valor_real,error_0, sigma_dist_0)
title('Interseccion de la recta con 0')
