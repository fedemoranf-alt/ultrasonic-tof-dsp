
close all
clear all

% se carga el vector de datos para las pruebas, el eco

%save('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\eco_refe.mat','eco_refe')

aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\eco_refe.mat');
eco_refe = aux.eco_refe;
eco_med = aux.eco_refe;
longitud = max(size(eco_refe));
% figure
% plot(eco_refe)

%% parametros para los filtros 
fc = 40e3;     %frecuencia de resonancia del sensor
fs = 400e3;      %frecuencia de muestreo
N = 1024;
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

%% fir derivada
b_diff = [-1, 6, -27, 104,0,  -104, 27, -6, 1];
% [B,W] = freqz(b);
% figure
% plot(W./pi , abs(B))
% filtro = tf(b,1,1);
% figure
% pzmap(filtro)
% figure
% freqz(b)

%% filtro demodulador

fir_dem = [ 0.0043,    0.0052,    0.0073,    0.0109,    0.0157,    0.0217,    0.0285,    0.0359,    0.0435,    0.0508,    0.0574,    0.0631,    0.0673,...
            0.0700,    0.0709,    0.0700,    0.0673,    0.0631,    0.0574,    0.0508,    0.0435,    0.0359,    0.0285,    0.0217,    0.0157,    0.0109,...
            0.0073,    0.0052,    0.0043  ];

%% filtro paso bajos para suavizar el patron
%patron_lp = fir1(30,100e3/600e3);

%% filtro low pass reconstructor
%pasamos la envolvente por un paso bajos con frecuencia de corte a 3k para
%interpolar la senhal, para esto primero disenhamos el filtro paso bajos
%neecesario:
M = 3;
fss_lp = M*fs;
fc_lp = 20e3;

lp_interpolador = fir1(60,fc_lp/(fss_lp/2)); %para que pase hasta 10k


%% se halla la envolvente utilizando la transformada de hilbert
env_r = abs(hilbert(eco_refe));
env_refe = filter(fir_dem,1,env_r);

figure
plot(eco_refe)
title('Eco y su envolvente, Referencia')
hold on
plot(env_refe)

%% Hallaremos una recta entre el 90% y el 10% de valor maximo de la envolvente utilizando el ajuste de minimos cuadrados y luego la intersectaremos con el punto de valor Vmax/2 de la envolvente para obtener el TOF

%se halla el valor maximo de la envolvente:
[env_refe_max_v env_refe_max_i ] = max(env_refe);
env_refe_max_90_v = 0.9*env_refe_max_v; % el valor del 90% del max de la envolvente
%se busca que punto de la envolvente posee el valor del 90% de la misma:
% se resta el valor de env_max_90 con cada punto de la envolvente y busca el que posee el menor error para identificar donde se encuentra el valor de 90% de la envolvente  
error = 1;
for i= 1 : env_refe_max_i
   aux = abs(env_refe_max_90_v - env_refe(i));
   if (aux < error) 
        error = aux;
        env_refe_max_90_i = i; 
   end
end

% se realiza el mismo procedimiento para hallar la ubicacion del valor del
% 10% del maximo de la envolvente
env_refe_max_10_v = 0.1*env_refe_max_v;
error = 1;
for i = 1 : env_refe_max_i
   aux = (abs(env_refe_max_10_v - env_refe(i)) + 0.001*abs(i - env_refe_max_i));
   if (aux < error)
      error = aux;
      env_refe_max_10_i = i;
   end
end

%% armamos el vector de datos que vamos a ajustar, este va desde env_max_10_i hasta env_max_90_i
voltajes_pa = env_refe(1,env_refe_max_10_i : env_refe_max_90_i);
indices_pa = [env_refe_max_10_i : 1: env_refe_max_90_i];
figure
plot(indices_pa,voltajes_pa)
title("Seccion de la envolvente a ajustar, Referencia")

%% procedemos a ajustar los datos a un polinomio de 1er orden, una recta.
% y = a*x + b
coef_refe = polyfit(indices_pa,voltajes_pa,1);

recta_ajustada_refe = polyval(coef_refe,indices_pa);

figure
plot(indices_pa,recta_ajustada_refe)
title("Recta ajustada, Referencia")

%% ahora debemos de hallar la interseccion de la recta con el valor de Vmax/2 de la envolvente, este punto sera el TOF de referencia

%para mejorar aca se debe de interpolar la recta antes de hallar la interseccion para mejor resolucion 
%% Interpolacion de la recta ajustada
indices_int = [env_refe_max_10_i : 0.1: env_refe_max_90_i];
recta_ajustada_refe_int = interp1(indices_pa,recta_ajustada_refe,indices_int);
figure
plot(indices_int,recta_ajustada_refe_int)
title("recta ajustada interpolada, Referencia")
%%
longitud_recta_int = max(size(recta_ajustada_refe_int));
error = 1;
for i= 1 : longitud_recta_int
   aux = abs((env_refe_max_v/2)- recta_ajustada_refe_int(i));
   if (aux < error) 
        error = aux;
        interseccion_recta_refe = indices_int(i); 
   end
end

recta_Vmax2_refe = ones(longitud);
recta_Vmax2_refe = (env_refe_max_v/2).*recta_Vmax2_refe; % solo para graficar

figure
plot(env_refe)
hold on
plot(indices_int,recta_ajustada_refe_int)
hold on
plot(recta_Vmax2_refe)
hold on
plot(interseccion_recta_refe,env_refe_max_v/2,'*')
title("Interseccion Referencia")

TOF1 = interseccion_recta_refe;

%% aca se deben de tomar los datos de la nueva medida
%% 

%% se halla la envolvente utilizando la transformada de hilbert
env_r = abs(hilbert(eco_med));
env_med = filter(fir_dem,1,env_r);

figure
plot(eco_med)
title('Eco y su envolvente, Medida')
hold on
plot(env_med)

%% Hallaremos una recta entre el 90% y el 10% de valor maximo de la envolvente utilizando el ajuste de minimos cuadrados y luego la intersectaremos con el punto de valor Vmax/2 de la envolvente para obtener el TOF

%se halla el valor maximo de la envolvente:
[env_med_max_v env_med_max_i ] = max(env_med);
env_med_max_90_v = 0.9*env_med_max_v; % el valor del 90% del max de la envolvente
%se busca que punto de la envolvente posee el valor del 90% de la misma:
% se resta el valor de env_max_90 con cada punto de la envolvente y busca el que posee el menor error para identificar donde se encuentra el valor de 90% de la envolvente  
error = 1;
for i= 1 : env_med_max_i
   aux = abs(env_med_max_90_v - env_med(i));
   if (aux < error) 
        error = aux;
        env_med_max_90_i = i; 
   end
end

% se realiza el mismo procedimiento para hallar la ubicacion del valor del
% 10% del maximo de la envolvente
env_med_max_10_v = 0.1*env_med_max_v;
error = 1;
for i = 1 : env_med_max_i
   aux = (abs(env_med_max_10_v - env_med(i)) + 0.001*abs(i - env_med_max_i));
   if (aux < error)
      error = aux;
      env_med_max_10_i = i;
   end
end

%% armamos el vector de datos que vamos a ajustar, este va desde env_max_10_i hasta env_max_90_i
voltajes_pa_med = env_med(1,env_med_max_10_i : env_med_max_90_i);
indices_pa_med = [env_med_max_10_i : 1: env_med_max_90_i];
figure
plot(indices_pa_med,voltajes_pa_med)
title("Seccion de la envolvente a ajustar, Medida")

%% procedemos a ajustar los datos a un polinomio de 1er orden, una recta.
% y = a*x + b
coef_med = polyfit(indices_pa_med,voltajes_pa_med,1);

recta_ajustada_med = polyval(coef_med,indices_pa_med);

figure
plot(indices_pa_med,recta_ajustada_med)
title("Recta ajustada, Medida")

%% ahora debemos de hallar la interseccion de la recta con el valor de Vmax/2 de la envolvente, este punto sera el TOF de medrencia

%para mejorar aca se debe de interpolar la recta antes de hallar la interseccion para mejor resolucion 
%% Interpolacion de la recta ajustada
indices_int = [env_med_max_10_i : 0.1: env_med_max_90_i];
recta_ajustada_med_int = interp1(indices_pa_med,recta_ajustada_med,indices_int);
figure
plot(indices_int,recta_ajustada_med_int)
title("recta ajustada interpolada, Medida")
%%
longitud_recta_int = max(size(recta_ajustada_med_int));
error = 1;
for i= 1 : longitud_recta_int
   aux = abs((env_med_max_v/2)- recta_ajustada_med_int(i));
   if (aux < error) 
        error = aux;
        interseccion_recta_med = indices_int(i); 
   end
end

recta_Vmax2_med = ones(longitud);
recta_Vmax2_med = (env_med_max_v/2).*recta_Vmax2_med; % solo para graficar

figure
plot(env_med)
hold on
plot(indices_int,recta_ajustada_med_int)
hold on
plot(recta_Vmax2_med)
hold on
plot(interseccion_recta_med,env_med_max_v/2,'*')
title("Interseccion medrencia")

TOF2 = interseccion_recta_med;

%% hallamos la distancia entre los ecos a partir de la diferencia entre los TOF

[TOF1 TOF2]





