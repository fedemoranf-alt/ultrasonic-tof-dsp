%% Script para comparar el comportamiento ante los distintos niveles de SNR con ruido blanco
% gaussiano de los algoritmos de correlacion con:
% -> El eco crudo
% -> La envolvente
% -> La derivada con interpolacion
% -> La derivada con interpolacion y promediado del patron

% se incluyen los 4 algoritmos en este script para ya generar los 4
% graficos de comparacion de error y STD de una sola vez 

clear all 
close all

%% Definimos como un parametro global el valor de la SNR que afectara a todos los datos y 
% a todos los algoritmos
SNR1 = 5; SNR2 = 15; SNR3 = 25; SNR4 = 35;
%hay que modificarlo antes de cada algoritmo por culpa del "clear all"
%mejor usar CRT+F y ahi reemplazar todos de una sola vez 

%% Algoritmo de correlacion con el eco crudo

%para probar el algoritmo de de medicion en matlab pero con los datos
%digitalizados_no_interf por el psoc, se utiliza el vector del eco

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

eco_refe = squeeze(eco(11,1,:)); % obs: el patron no debe tener ruido


%se normaliza el eco
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
    
    %SNR1
    eco_med_1 = squeeze(eco(count_dist,count_med,:));
    eco_med_1 = awgn(eco_med_1,SNR1,'measured');
    %se normaliza el eco
    [max_d, max_i] = max(eco_med_1);
    eco_med_1 = (1/max_d).*eco_med_1;
    
    %SNR2
    eco_med_2 = squeeze(eco(count_dist,count_med,:));
    eco_med_2 = awgn(eco_med_2,SNR2,'measured');
    %se normaliza el eco
    [max_d, max_i] = max(eco_med_2);
    eco_med_2 = (1/max_d).*eco_med_2;
    
    %SNR3
    eco_med_3 = squeeze(eco(count_dist,count_med,:));
    eco_med_3 = awgn(eco_med_3,SNR3,'measured');
    %se normaliza el eco
    [max_d, max_i] = max(eco_med_3);
    eco_med_3 = (1/max_d).*eco_med_3;
    
    %SNR4
    eco_med_4 = squeeze(eco(count_dist,count_med,:));
    eco_med_4 = awgn(eco_med_4,SNR4,'measured');
    %se normaliza el eco
    [max_d, max_i] = max(eco_med_4);
    eco_med_4 = (1/max_d).*eco_med_4;
    
    %% CORRELACION DE LA SENHAL medida (EL 2DO ECO digitalizado)
    %SNR1
    correlacion  =  xcorr(eco_med_1,patron);
    [V2_SNR1 TOF2_SNR1] = max( correlacion );
    
    %SNR2
    correlacion  =  xcorr(eco_med_2,patron);
    [V2_SNR2 TOF2_SNR2] = max( correlacion );

    %SNR3
    correlacion  =  xcorr(eco_med_3,patron);
    [V2_SNR3 TOF2_SNR3] = max( correlacion );
    
    %SNR4
    correlacion  =  xcorr(eco_med_4,patron);
    [V2_SNR4 TOF2_SNR4] = max( correlacion );


    %% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes
    %SNR1
    %TOF1_v(count_dist,count_med) = TOF1
    %TOF2_SNR1(count_dist,count_med) = TOF2_SNR1
    
    Distancia_SNR1(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR1-TOF1)*1/(fs)];
    %SNR2
    Distancia_SNR2(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR2-TOF1)*1/(fs)];
    %SNR3
    Distancia_SNR3(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR3-TOF1)*1/(fs)];
    %SNR1
    Distancia_SNR4(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR4-TOF1)*1/(fs)];

    count_med = count_med + 1;
    
    end
    
    count_dist = count_dist + 1;
    count_med = 1;
    
end

% al finalizar guardamos los valores calculados para graficarlos al final,
% para asi poder hacer clear all y close all para no afectar al
% procesamiento del siguiente algoritmo
save('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_crudo_no_interf.mat','Distancia_SNR1','Distancia_SNR2','Distancia_SNR3','Distancia_SNR4')
close all
clear all

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Definimos como un parametro global el valor de la SNR que afectara a todos los datos y 
% a todos los algoritmos
SNR1 = 5; SNR2 = 15; SNR3 = 25; SNR4 = 35;

%% ALGORITMO DE CORRELACION CON LA ENVOLVENTE

fc = 40e3;     %frecuencia de resonancia del sensor
fs = 400e3;      %frecuencia de muestreo
N = 1024;

%% filtro demodulador
fir_dem = fir1(65,0.1,blackman(66));
fir_dem2 = fir1(65,0.025,blackman(66));

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
%eco_refe = awgn(eco_refe,SNR);

%% se halla la envolvente utilizando la transformada de hilbert
env_r = abs(hilbert(eco_refe));
env_refe = filter(fir_dem,1,env_r);

figure
plot(eco_refe)
title('Eco y su envolvente, ENV.')
hold on
plot(env_refe)

%se normaliza la envolvente
[max_d, max_i] = max(env_refe );
env_refe = (1/max_d).*env_refe;

%% Elegimos el patron

figure
plot(env_refe)
title('Envolvente de referencia. ENV')

disp("Enter para elegir el patron")
pause
%se selecciona cual sera el patron, esto se hace seleccionando una ventana
%temporanl en la curva de la envolventa derivada
[ind val] = ginput(2);

%Se define el patron desde la derivada
patron = env_refe(floor(ind(1,1)):floor(ind(2,1)));

figure
plot(patron);
title('patron')

%% hallamos el indice maximo de la correlacion de referencia.
correlacion =  xcorr(env_refe ,patron);
[V1 TOF1] = max(correlacion);

%% iniciamos las mediciones a partir de la referencia tomada

flag = 1;
count_med = 1;
count_dist = 1;

while(count_dist < 22)
    while(count_med <11)
    %se toma la siguiente medida
    %SNR1
    eco_med_1 = squeeze(eco(count_dist,count_med,:));
    eco_med_1 = awgn(eco_med_1,SNR1,'measured');
    %SNR2
    eco_med_2 = squeeze(eco(count_dist,count_med,:));
    eco_med_2 = awgn(eco_med_2,SNR2,'measured');
    %SNR3
    eco_med_3 = squeeze(eco(count_dist,count_med,:));
    eco_med_3 = awgn(eco_med_3,SNR3,'measured');
    %SNR1
    eco_med_4 = squeeze(eco(count_dist,count_med,:));
    eco_med_4 = awgn(eco_med_4,SNR4,'measured');
    
    %% se obtiene la envolvente del eco medido
    %SNR1
    env_m_1 = abs(hilbert(eco_med_1));
    env_med_1 = filter(fir_dem,1,env_m_1);
    %SNR2
    env_m_2 = abs(hilbert(eco_med_2));
    env_med_2 = filter(fir_dem,1,env_m_2);
    %SNR3
    env_m_3 = abs(hilbert(eco_med_3));
    env_med_3 = filter(fir_dem,1,env_m_3);
    %SNR4
    env_m_4 = abs(hilbert(eco_med_4));
    env_med_4 = filter(fir_dem,1,env_m_4);
    
    %% se normaliza la envolvente
    %SNR1
    [max_d_1, max_i] = max(env_med_1);
    env_med_1 = (1/max_d_1).*env_med_1;
    %SNR2
    [max_d_2, max_i] = max(env_med_2);
    env_med_2 = (1/max_d_2).*env_med_2;
    %SNR3
    [max_d_3, max_i] = max(env_med_3);
    env_med_3 = (1/max_d_3).*env_med_3;
    %SNR4
    [max_d_4, max_i] = max(env_med_4);
    env_med_4 = (1/max_d_4).*env_med_4;

    %% CORRELACION DE LA SENHAL medida (EL 2DO ECO digitalizado)
    %SNR1
    correlacion_1  =  xcorr(env_med_1 ,patron);
    [V2_SNR1 TOF2_SNR1] = max( correlacion_1 );
    %SNR2
    correlacion_2  =  xcorr(env_med_2 ,patron);
    [V2_SNR2 TOF2_SNR2] = max( correlacion_2 );
    %SNR3
    correlacion_3  =  xcorr(env_med_3 ,patron);
    [V2_SNR3 TOF2_SNR3] = max( correlacion_3 );
    %SNR4
    correlacion_4  =  xcorr(env_med_4 ,patron);
    [V2_SNR4 TOF2_SNR4] = max( correlacion_4 );


    %% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes
    %SNR1
    Distancia_SNR1(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR1-TOF1)*1/(fs)];
    %SNR2
    Distancia_SNR2(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR2-TOF1)*1/(fs)];
    %SNR3
    Distancia_SNR3(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR3-TOF1)*1/(fs)];
    %SNR4
    Distancia_SNR4(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR4-TOF1)*1/(fs)];

    count_med = count_med + 1;
    
   
    end
    
    count_dist = count_dist + 1;
    count_med = 1;
    
end

% al finalizar guardamos los valores calculados para graficarlos al final,
% para asi poder hacer clear all y close all para no afectar al
% procesamiento del siguiente algoritmo
save('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\envolvente_no_interf.mat','Distancia_SNR1','Distancia_SNR2','Distancia_SNR3','Distancia_SNR4')
close all
clear all

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Definimos como un parametro global el valor de la SNR que afectara a todos los datos y 
% a todos los algoritmos
SNR1 = 5; SNR2 = 15; SNR3 = 25; SNR4 = 35;

%% Algoritmo con la derivada interpolada

fc = 40e3;     %frecuencia de resonancia del sensor
fs = 400e3;      %frecuencia de muestreo
N = 1024;
%% deriva de amstrong 
%filtro analogico cero - polo frecuencia de corte superior 60000
fss = fc;     %Doble de la frecuencia de la portadora
a = 2*20e3*pi;  %Ancho de banda del transductor
num = 100.*[1 0];
den = [1 a]; % se usa el polo para limitar el ancho de banda de la derivada
%Se digitaliza el filtro para hallar la derivada
[numd, dend] = bilinear(num,den,fss);
derivadorS = tf(num,den);
derivadorZ = tf(numd,dend,1); % para tener la ecuacion en diferencia que va en el PSoC

%% filtro demodulador
fir_dem = fir1(65,0.1,blackman(66));
fir_dem2 = fir1(65,0.025,blackman(66));

%% filtro low pass reconstructor
%pasamos la envolvente por un paso bajos con frecuencia de corte a 3k para
%interpolar la senhal, para esto primero disenhamos el filtro paso bajos
%neecesario:
M = 3;
fss_lp = M*fs;
fc_lp = 20e3;

lp_interpolador = fir1(60,fc_lp/(fss_lp/2)); %para que pase hasta 10k

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
%eco_refe = awgn(eco_refe,SNR);

%% se halla la envolvente utilizando la transformada de hilbert
env_r = abs(hilbert(eco_refe));
env_refe = filter(fir_dem,1,env_r);

figure
plot(eco_refe)
title('Eco y su envolvente, INT')
hold on
plot(env_refe)

%% se interpola la envolvente para obterner mas resolucion
%primero agregamos los puntos intermedios en cada muestra
j = 1;
for i=1 : N
    env_y_0(j) = env_refe(i);
    env_y_0(j+1) = env_refe(i);
    env_y_0(j+2) = env_refe(i);
    j = j+3;
end

%pasamos la senhal por el filtro low pass reconstructor:
env_refe_int = filter(lp_interpolador,1,env_y_0);
env_refe_int = M.*env_refe_int;

%% derivamos al envolvente 
env_refe_int_d = filter(numd,dend,env_refe_int);%se deriva la envolvelnte interpolada

%se normaliza la derivada
[max_d, max_i] = max(env_refe_int_d );
env_refe_int_d = (1/max_d).*env_refe_int_d;

%% Elegimos el patron

figure
plot(env_refe_int_d)
title('Derivada de la envolvente referencia. INT')

disp("Enter para elegir el patron")
pause
%se selecciona cual sera el patron, esto se hace seleccionando una ventana
%temporanl en la curva de la envolventa derivada
[ind val] = ginput(2);

%Se define el patron desde la derivada
patron = env_refe_int_d(1,floor(ind(1,1)):floor(ind(2,1)));

figure
plot(patron);
title('patron de la derivada')

%% hallamos el indice maximo de la correlacion de referencia.
correlacion =  xcorr(env_refe_int_d ,patron);
[V1 TOF1] = max(correlacion);

%% iniciamos las mediciones a partir de la referencia tomada

flag = 1;
count_med = 1;
count_dist = 1;

while(count_dist < 22)
    while(count_med <11)
   %se toma la siguiente medida
    %SNR1
    eco_med_1 = squeeze(eco(count_dist,count_med,:));
    eco_med_1 = awgn(eco_med_1,SNR1,'measured');
    %SNR2
    eco_med_2 = squeeze(eco(count_dist,count_med,:));
    eco_med_2 = awgn(eco_med_2,SNR2,'measured');
    %SNR3
    eco_med_3 = squeeze(eco(count_dist,count_med,:));
    eco_med_3 = awgn(eco_med_3,SNR3,'measured');
    %SNR4
    eco_med_4 = squeeze(eco(count_dist,count_med,:));
    eco_med_4 = awgn(eco_med_4,SNR4,'measured');
    
    %% se obtiene la envolvente del eco medido
    %SNR1
    env_m_1 = abs(hilbert(eco_med_1));
    env_med_1 = filter(fir_dem,1,env_m_1);
    %SNR2
    env_m_2 = abs(hilbert(eco_med_2));
    env_med_2 = filter(fir_dem,1,env_m_2);
    %SNR3
    env_m_3 = abs(hilbert(eco_med_3));
    env_med_3 = filter(fir_dem,1,env_m_3);
    %SNR4
    env_m_4 = abs(hilbert(eco_med_4));
    env_med_4 = filter(fir_dem,1,env_m_4);

    %% se interpola la envolvente del segundo eco
    %SNR1
    %primero agregamos los puntos intermedios en cada muestra
    j = 1;
    for i=1 : N
        env_y1_SNR1(j) = env_med_1(i);
        env_y1_SNR1(j+1) = env_med_1(i);
        env_y1_SNR1(j+2) = env_med_1(i);
        j = j+3;
    end
    env_med_int_SNR1 = filter(lp_interpolador,1,env_y1_SNR1);
    env_med_int_SNR1 = M.*env_med_int_SNR1;
    
    %SNR2
    %primero agregamos los puntos intermedios en cada muestra
    j = 1;
    for i=1 : N
        env_y1_SNR2(j) = env_med_2(i);
        env_y1_SNR2(j+1) = env_med_2(i);
        env_y1_SNR2(j+2) = env_med_2(i);
        j = j+3;
    end
    env_med_int_SNR2 = filter(lp_interpolador,1,env_y1_SNR2);
    env_med_int_SNR2 = M.*env_med_int_SNR2;

    %SNR3
    %primero agregamos los puntos intermedios en cada muestra
    j = 1;
    for i=1 : N
        env_y1_SNR3(j) = env_med_3(i);
        env_y1_SNR3(j+1) = env_med_3(i);
        env_y1_SNR3(j+2) = env_med_3(i);
        j = j+3;
    end
    env_med_int_SNR3 = filter(lp_interpolador,1,env_y1_SNR3);
    env_med_int_SNR3 = M.*env_med_int_SNR3;
    
    %SNR4
    %primero agregamos los puntos intermedios en cada muestra
    j = 1;
    for i=1 : N
        env_y1_SNR4(j) = env_med_4(i);
        env_y1_SNR4(j+1) = env_med_4(i);
        env_y1_SNR4(j+2) = env_med_4(i);
        j = j+3;
    end
    env_med_int_SNR4 = filter(lp_interpolador,1,env_y1_SNR4);
    env_med_int_SNR4 = M.*env_med_int_SNR4;
    
    %% se deriva la envolvente interpolada del segundo eco
    %SNR1
    env_med_int_d_SNR1 = filter(numd,dend,env_med_int_SNR1);
    %SNR2
    env_med_int_d_SNR2 = filter(numd,dend,env_med_int_SNR2);
    %SNR3
    env_med_int_d_SNR3 = filter(numd,dend,env_med_int_SNR3);
    %SNR4
    env_med_int_d_SNR4 = filter(numd,dend,env_med_int_SNR4);
    
    %% se normaliza la derivada
    %SNR1
    [max_d_1, max_i] = max(env_med_int_d_SNR1);
    env_med_int_d_SNR1 = (1/max_d_1).*env_med_int_d_SNR1;
    %SNR2
    [max_d_2, max_i] = max(env_med_int_d_SNR2);
    env_med_int_d_SNR2 = (1/max_d_2).*env_med_int_d_SNR2;
    %SNR3
    [max_d_3, max_i] = max(env_med_int_d_SNR3);
    env_med_int_d_SNR3 = (1/max_d_3).*env_med_int_d_SNR3;
    %SNR4
    [max_d_4, max_i] = max(env_med_int_d_SNR4);
    env_med_int_d_SNR4 = (1/max_d_4).*env_med_int_d_SNR4;

    %% CORRELACION DE LA SENHAL medida (EL 2DO ECO digitalizado)
    %SNR1
    correlacion_1  =  xcorr(env_med_int_d_SNR1 ,patron);
    [V2_SNR1 TOF2_SNR1] = max( correlacion_1 );
    %SNR2
    correlacion_2  =  xcorr(env_med_int_d_SNR2 ,patron);
    [V2_SNR2 TOF2_SNR2] = max( correlacion_2 );
    %SNR3
    correlacion_3  =  xcorr(env_med_int_d_SNR3 ,patron);
    [V2_SNR3 TOF2_SNR3] = max( correlacion_3 );
    %SNR4
    correlacion_4  =  xcorr(env_med_int_d_SNR4 ,patron);
    [V2_SNR4 TOF2_SNR4] = max( correlacion_4 );
    
    %% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes
    %SNR1
    Distancia_SNR1(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR1-TOF1)*1/(3*fs)];
    %SNR2
    Distancia_SNR2(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR2-TOF1)*1/(3*fs)];
    %SNR3
    Distancia_SNR3(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR3-TOF1)*1/(3*fs)];
    %SNR4
    Distancia_SNR4(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR4-TOF1)*1/(3*fs)];
    
    count_med = count_med + 1;
    
    end
    count_dist = count_dist + 1;
    count_med = 1;
end
% al finalizar guardamos los valores calculados para graficarlos al final,
% para asi poder hacer clear all y close all para no afectar al
% procesamiento del siguiente algoritmo
save('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\int_no_interf.mat','Distancia_SNR1','Distancia_SNR2','Distancia_SNR3','Distancia_SNR4')
close all
clear all

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Definimos como un parametro global el valor de la SNR que afectara a todos los datos y 
% a todos los algoritmos
SNR1 = 5; SNR2 = 15; SNR3 = 25; SNR4 = 35;

%% DERIVADA INTERPOLADA CON PROMEDIADO

fc = 40e3;     %frecuencia de resonancia del sensor
fs = 400e3;      %frecuencia de muestreo
N = 1024;
%% deriva de amstrong 
%filtro analogico cero - polo frecuencia de corte superior 60000
fss = fc;     %Doble de la frecuencia de la portadora
a = 2*20e3*pi;  %Ancho de banda del transductor
num = 100.*[1 0];
den = [1 a]; % se usa el polo para limitar el ancho de banda de la derivada
%Se digitaliza el filtro para hallar la derivada
[numd, dend] = bilinear(num,den,fss);
derivadorS = tf(num,den);
derivadorZ = tf(numd,dend,1); % para tener la ecuacion en diferencia que va en el PSoC

%% filtro demodulador

fir_dem = fir1(65,0.1,blackman(66));
fir_dem2 = fir1(65,0.025,blackman(66));
figure
freqz(fir_dem)


%% filtro low pass reconstructor
%pasamos la envolvente por un paso bajos con frecuencia de corte a 3k para
%interpolar la senhal, para esto primero disenhamos el filtro paso bajos
%neecesario:
M = 3;
fss_lp = M*fs;
fc_lp = 20e3;
lp_interpolador = fir1(60,fc_lp/(fss_lp/2)); %para que pase hasta 10k

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

%para tomar el patron hacemos el promediado espacial de los 10 ecos en el
%punto de referencia el cual es a la mitad de la distancia, corresponde al
%indice 11 en el array eco
env_refe_int_d = zeros(1,longitud*M);

prom_count = 1;
while (prom_count < 11) %promediaremos 10 medidas
    
    eco_refe = squeeze(eco(11,prom_count,:));
    %eco_refe = awgn(eco_refe,SNR);
    
    %% se halla la envolvente utilizando la transformada de hilbert
    env_r = abs(hilbert(eco_refe));
    env_refe = filter(fir_dem,1,env_r);
    

    %% se interpola la envolvente para obterner mas resolucion
    %primero agregamos los puntos intermedios en cada muestra
    j = 1;
    for i=1 : N
        env_y_0(j) = env_refe(i);
        env_y_0(j+1) = env_refe(i);
        env_y_0(j+2) = env_refe(i);
        j = j+3;
    end

    %pasamos la senhal por el filtro low pass reconstructor:
    env_refe_int = filter(lp_interpolador,1,env_y_0);
    env_refe_int = M.*env_refe_int;


    %% derivamos al envolvente 
    env_refe_int_d_aux = filter(numd,dend,env_refe_int);%se deriva la envolvelnte interpolada
   
    %normalizacion de la derivada
    [max_d max_i] = max(env_refe_int_d_aux );
    env_refe_int_d_aux = (1/max_d).*env_refe_int_d_aux;
    
    %% sumamos las derivadas de la envolvente
    for i = 1 : longitud*M
        env_refe_int_d(i) = env_refe_int_d(i) + env_refe_int_d_aux(i);
    end
    prom_count = prom_count +1;

end
env_refe_int_d = (1/10).*env_refe_int_d;

%% Elegimos el patron

figure
plot(env_refe_int_d)
title('Derivada de la envolvente referencia. INT PROM')

disp("Enter para elegir el patron")
pause
%se selecciona cual sera el patron, esto se hace seleccionando una ventana
%temporanl en la curva de la envolventa derivada
[ind val] = ginput(2);

%Se define el patron desde la derivada
patron = env_refe_int_d(1,floor(ind(1,1)):floor(ind(2,1)));
figure
plot(patron);
title('patron de la derivada')

%% hallamos el indice maximo de la correlacion de referencia.
correlacion =  xcorr(env_refe_int_d ,patron);
[V1 TOF1] = max(correlacion);

%% iniciamos las mediciones a partir de la referencia tomada

flag = 1;
count_med = 1;
count_dist = 1;

while(count_dist < 22)
    while(count_med <11)
   %se toma la siguiente medida
    %SNR1
    eco_med_1 = squeeze(eco(count_dist,count_med,:));
    eco_med_1 = awgn(eco_med_1,SNR1,'measured');
    %SNR2
    eco_med_2 = squeeze(eco(count_dist,count_med,:));
    eco_med_2 = awgn(eco_med_2,SNR2,'measured');
    %SNR3
    eco_med_3 = squeeze(eco(count_dist,count_med,:));
    eco_med_3 = awgn(eco_med_3,SNR3,'measured');
    %SNR4
    eco_med_4 = squeeze(eco(count_dist,count_med,:));
    eco_med_4 = awgn(eco_med_4,SNR4,'measured');
    
    %% se obtiene la envolvente del eco medido
    %SNR1
    env_m_1 = abs(hilbert(eco_med_1));
    env_med_1 = filter(fir_dem,1,env_m_1);
    %SNR2
    env_m_2 = abs(hilbert(eco_med_2));
    env_med_2 = filter(fir_dem,1,env_m_2);
    %SNR3
    env_m_3 = abs(hilbert(eco_med_3));
    env_med_3 = filter(fir_dem,1,env_m_3);
    %SNR4
    env_m_4 = abs(hilbert(eco_med_4));
    env_med_4 = filter(fir_dem,1,env_m_4);

    %% se interpola la envolvente del segundo eco
    %SNR1
    %primero agregamos los puntos intermedios en cada muestra
    j = 1;
    for i=1 : N
        env_y1_SNR1(j) = env_med_1(i);
        env_y1_SNR1(j+1) = env_med_1(i);
        env_y1_SNR1(j+2) = env_med_1(i);
        j = j+3;
    end
    env_med_int_SNR1 = filter(lp_interpolador,1,env_y1_SNR1);
    env_med_int_SNR1 = M.*env_med_int_SNR1;
    
    %SNR2
    %primero agregamos los puntos intermedios en cada muestra
    j = 1;
    for i=1 : N
        env_y1_SNR2(j) = env_med_2(i);
        env_y1_SNR2(j+1) = env_med_2(i);
        env_y1_SNR2(j+2) = env_med_2(i);
        j = j+3;
    end
    env_med_int_SNR2 = filter(lp_interpolador,1,env_y1_SNR2);
    env_med_int_SNR2 = M.*env_med_int_SNR2;

    %SNR3
    %primero agregamos los puntos intermedios en cada muestra
    j = 1;
    for i=1 : N
        env_y1_SNR3(j) = env_med_3(i);
        env_y1_SNR3(j+1) = env_med_3(i);
        env_y1_SNR3(j+2) = env_med_3(i);
        j = j+3;
    end
    env_med_int_SNR3 = filter(lp_interpolador,1,env_y1_SNR3);
    env_med_int_SNR3 = M.*env_med_int_SNR3;
    
    %SNR4
    %primero agregamos los puntos intermedios en cada muestra
    j = 1;
    for i=1 : N
        env_y1_SNR4(j) = env_med_4(i);
        env_y1_SNR4(j+1) = env_med_4(i);
        env_y1_SNR4(j+2) = env_med_4(i);
        j = j+3;
    end
    env_med_int_SNR4 = filter(lp_interpolador,1,env_y1_SNR4);
    env_med_int_SNR4 = M.*env_med_int_SNR4;
    
    %% se deriva la envolvente interpolada del segundo eco
    %SNR1
    env_med_int_d_SNR1 = filter(numd,dend,env_med_int_SNR1);
    %SNR2
    env_med_int_d_SNR2 = filter(numd,dend,env_med_int_SNR2);
    %SNR3
    env_med_int_d_SNR3 = filter(numd,dend,env_med_int_SNR3);
    %SNR4
    env_med_int_d_SNR4 = filter(numd,dend,env_med_int_SNR4);
    
    %% se normaliza la derivada
    %SNR1
    [max_d_1, max_i] = max(env_med_int_d_SNR1);
    env_med_int_d_SNR1 = (1/max_d_1).*env_med_int_d_SNR1;
    %SNR2
    [max_d_2, max_i] = max(env_med_int_d_SNR2);
    env_med_int_d_SNR2 = (1/max_d_2).*env_med_int_d_SNR2;
    %SNR3
    [max_d_3, max_i] = max(env_med_int_d_SNR3);
    env_med_int_d_SNR3 = (1/max_d_3).*env_med_int_d_SNR3;
    %SNR4
    [max_d_4, max_i] = max(env_med_int_d_SNR4);
    env_med_int_d_SNR4 = (1/max_d_4).*env_med_int_d_SNR4;

    %% CORRELACION DE LA SENHAL medida (EL 2DO ECO digitalizado)
    %SNR1
    correlacion_1  =  xcorr(env_med_int_d_SNR1 ,patron);
    [V2_SNR1 TOF2_SNR1] = max( correlacion_1 );
    %SNR2
    correlacion_2  =  xcorr(env_med_int_d_SNR2 ,patron);
    [V2_SNR2 TOF2_SNR2] = max( correlacion_2 );
    %SNR3
    correlacion_3  =  xcorr(env_med_int_d_SNR3 ,patron);
    [V2_SNR3 TOF2_SNR3] = max( correlacion_3 );
    %SNR4
    correlacion_4  =  xcorr(env_med_int_d_SNR4 ,patron);
    [V2_SNR4 TOF2_SNR4] = max( correlacion_4 );
    
    %% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes
    %SNR1
    Distancia_SNR1(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR1-TOF1)*1/(3*fs)];
    %SNR2
    Distancia_SNR2(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR2-TOF1)*1/(3*fs)];
    %SNR3
    Distancia_SNR3(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR3-TOF1)*1/(3*fs)];
    %SNR4
    Distancia_SNR4(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR4-TOF1)*1/(3*fs)];
    
    count_med = count_med + 1;
    
    end
    count_dist = count_dist + 1;
    count_med = 1;
end
% al finalizar guardamos los valores calculados para graficarlos al final,
% para asi poder hacer clear all y close all para no afectar al
% procesamiento del siguiente algoritmo
save('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\int_prom_no_interf.mat','Distancia_SNR1','Distancia_SNR2','Distancia_SNR3','Distancia_SNR4')
close all
clear all



%% Graficamos los resultados:
clear all
close all
%% Eco crudo
SNR1 = 5; SNR2 = 15; SNR3 = 25; SNR4 = 35;
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\eco_crudo_no_interf.mat');

valor_real = [-100:10:100];
XMIN = -10;
XMAX = 10;
YMIN = -5;
YMAX =5;

i= 1;
while (i < 22)
   %SNR1
   promedio_dist_SNR1(i) = mean(aux.Distancia_SNR1(i,:)); 
   sigma_dist_SNR1(i) = std(aux.Distancia_SNR1(i,:));
   error_SNR1(i) = valor_real(i) - promedio_dist_SNR1(i);
   %SNR2
   promedio_dist_SNR2(i) = mean(aux.Distancia_SNR2(i,:)); 
   sigma_dist_SNR2(i) = std(aux.Distancia_SNR2(i,:));
   error_SNR2(i) = valor_real(i) - promedio_dist_SNR2(i);
   %SNR3
   promedio_dist_SNR3(i) = mean(aux.Distancia_SNR3(i,:)); 
   sigma_dist_SNR3(i) = std(aux.Distancia_SNR3(i,:));
   error_SNR3(i) = valor_real(i) - promedio_dist_SNR3(i);
   %SNR4
   promedio_dist_SNR4(i) = mean(aux.Distancia_SNR4(i,:)); 
   sigma_dist_SNR4(i) = std(aux.Distancia_SNR4(i,:));
   error_SNR4(i) = valor_real(i) - promedio_dist_SNR4(i); 
   
    i = i+1;
end

indice = [-10:1:10];

% figure
% subplot(311)
% plot(indice,promedio_dist_SNR1,'o')
% hold on
% plot(indice,promedio_dist_SNR2,'+')
% hold on
% plot(indice,promedio_dist_SNR3,'--')
% hold on
% plot(indice,promedio_dist_SNR4,'*')
% title('Eco Crudo, Promedio Distancias')
% 
% subplot(312)
% plot(indice,sigma_dist_SNR1,'o')
% hold on
% plot(indice,sigma_dist_SNR2,'+')
% hold on
% plot(indice,sigma_dist_SNR3,'--')
% hold on
% plot(indice,sigma_dist_SNR4,'*')
% title('Eco Crudo, STD Distancias')
%  
% subplot(313)
% plot(indice,error_SNR1,'o')
% hold on
% plot(indice,error_SNR2,'+')
% hold on
% plot(indice,error_SNR3,'--')
% hold on
% plot(indice,error_SNR4,'*')
% title('Error')
% %axis([XMIN XMAX YMIN YMAX])
% legend('SNR1','SNR2','SNR3','SNR4')

figure
subplot(411)
errorbar(valor_real,error_SNR1, sigma_dist_SNR1)
title(['Eco Crudo, Sin Interferencia, SNR=',num2str(SNR1)])

subplot(412)
errorbar(valor_real,error_SNR2, sigma_dist_SNR2)
title(['Eco Crudo, Sin Interferencia, SNR=',num2str(SNR2)])

subplot(413)
errorbar(valor_real,error_SNR3, sigma_dist_SNR3)
title(['Eco Crudo, Sin Interferencia, SNR=',num2str(SNR3)])

subplot(414)
errorbar(valor_real,error_SNR4, sigma_dist_SNR4)
title(['Eco Crudo, Sin Interferencia, SNR=',num2str(SNR4)])

clear all
%% ENVOLVETE
SNR1 = 5; SNR2 = 15; SNR3 = 25; SNR4 = 35;
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\envolvente_no_interf.mat');

valor_real = [-100:10:100];
XMIN = -10;
XMAX = 10;
YMIN = -5;
YMAX =5;

i= 1;
while (i < 22)
   %SNR1
   promedio_dist_SNR1(i) = mean(aux.Distancia_SNR1(i,:)); 
   sigma_dist_SNR1(i) = std(aux.Distancia_SNR1(i,:));
   error_SNR1(i) = valor_real(i) - promedio_dist_SNR1(i);
   %SNR2
   promedio_dist_SNR2(i) = mean(aux.Distancia_SNR2(i,:)); 
   sigma_dist_SNR2(i) = std(aux.Distancia_SNR2(i,:));
   error_SNR2(i) = valor_real(i) - promedio_dist_SNR2(i);
   %SNR3
   promedio_dist_SNR3(i) = mean(aux.Distancia_SNR3(i,:)); 
   sigma_dist_SNR3(i) = std(aux.Distancia_SNR3(i,:));
   error_SNR3(i) = valor_real(i) - promedio_dist_SNR3(i);
   %SNR4
   promedio_dist_SNR4(i) = mean(aux.Distancia_SNR4(i,:)); 
   sigma_dist_SNR4(i) = std(aux.Distancia_SNR4(i,:));
   error_SNR4(i) = valor_real(i) - promedio_dist_SNR4(i); 
   
    i = i+1;
end

indice = [-10:1:10];

% figure
% subplot(311)
% plot(indice,promedio_dist_SNR1,'o')
% hold on
% plot(indice,promedio_dist_SNR2,'+')
% hold on
% plot(indice,promedio_dist_SNR3,'--')
% hold on
% plot(indice,promedio_dist_SNR4,'*')
% title('Envolvente, Promedio Distancias')
% 
% subplot(312)
% plot(indice,sigma_dist_SNR1,'o')
% hold on
% plot(indice,sigma_dist_SNR2,'+')
% hold on
% plot(indice,sigma_dist_SNR3,'--')
% hold on
% plot(indice,sigma_dist_SNR4,'*')
% title('Envolvente, STD Distancias')
%  
% subplot(313)
% plot(indice,error_SNR1,'o')
% hold on
% plot(indice,error_SNR2,'+')
% hold on
% plot(indice,error_SNR3,'--')
% hold on
% plot(indice,error_SNR4,'*')
% title('Error')
% %axis([XMIN XMAX YMIN YMAX])
% legend('SNR1','SNR2','SNR3','SNR4')

figure
subplot(411)
errorbar(valor_real,error_SNR1, sigma_dist_SNR1)
title(['Envolventa, Sin Interferencia, SNR=',num2str(SNR1)])

subplot(412)
errorbar(valor_real,error_SNR2, sigma_dist_SNR2)
title(['Envolventa, Sin Interferencia, SNR=',num2str(SNR2)])

subplot(413)
errorbar(valor_real,error_SNR3, sigma_dist_SNR3)
title(['Envolventa, Sin Interferencia, SNR=',num2str(SNR3)])

subplot(414)
errorbar(valor_real,error_SNR4, sigma_dist_SNR4)
title(['Envolventa, Sin Interferencia, SNR=',num2str(SNR4)])

clear all
%% DERIVADA INTERPOLADA
SNR1 = 5; SNR2 = 15; SNR3 = 25; SNR4 = 35;
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\int_no_interf.mat');

valor_real = [-100:10:100];
XMIN = -10;
XMAX = 10;
YMIN = -5;
YMAX =5;

i= 1;
while (i < 22)
   %SNR1
   promedio_dist_SNR1(i) = mean(aux.Distancia_SNR1(i,:)); 
   sigma_dist_SNR1(i) = std(aux.Distancia_SNR1(i,:));
   error_SNR1(i) = valor_real(i) - promedio_dist_SNR1(i);
   %SNR2
   promedio_dist_SNR2(i) = mean(aux.Distancia_SNR2(i,:)); 
   sigma_dist_SNR2(i) = std(aux.Distancia_SNR2(i,:));
   error_SNR2(i) = valor_real(i) - promedio_dist_SNR2(i);
   %SNR3
   promedio_dist_SNR3(i) = mean(aux.Distancia_SNR3(i,:)); 
   sigma_dist_SNR3(i) = std(aux.Distancia_SNR3(i,:));
   error_SNR3(i) = valor_real(i) - promedio_dist_SNR3(i);
   %SNR4
   promedio_dist_SNR4(i) = mean(aux.Distancia_SNR4(i,:)); 
   sigma_dist_SNR4(i) = std(aux.Distancia_SNR4(i,:));
   error_SNR4(i) = valor_real(i) - promedio_dist_SNR4(i); 
   
    i = i+1;
end

indice = [-10:1:10];

% figure
% subplot(311)
% plot(indice,promedio_dist_SNR1,'o')
% hold on
% plot(indice,promedio_dist_SNR2,'+')
% hold on
% plot(indice,promedio_dist_SNR3,'--')
% hold on
% plot(indice,promedio_dist_SNR4,'*')
% title('Interpolación, Promedio Distancias')
% 
% subplot(312)
% plot(indice,sigma_dist_SNR1,'o')
% hold on
% plot(indice,sigma_dist_SNR2,'+')
% hold on
% plot(indice,sigma_dist_SNR3,'--')
% hold on
% plot(indice,sigma_dist_SNR4,'*')
% title('Interpolación, STD Distancias')
%  
% subplot(313)
% plot(indice,error_SNR1,'o')
% hold on
% plot(indice,error_SNR2,'+')
% hold on
% plot(indice,error_SNR3,'--')
% hold on
% plot(indice,error_SNR4,'*')
% title('Error')
% %axis([XMIN XMAX YMIN YMAX])
% legend('SNR1','SNR2','SNR3','SNR4')

figure
subplot(411)
errorbar(valor_real,error_SNR1, sigma_dist_SNR1)
title(['Interpolación, Sin interferencia, SNR=',num2str(SNR1)])

subplot(412)
errorbar(valor_real,error_SNR2, sigma_dist_SNR2)
title(['Interpolación, Sin interferencia, SNR=',num2str(SNR2)])

subplot(413)
errorbar(valor_real,error_SNR3, sigma_dist_SNR3)
title(['Interpolación, Sin interferencia, SNR=',num2str(SNR3)])

subplot(414)
errorbar(valor_real,error_SNR4, sigma_dist_SNR4)
title(['Interpolación, Sin interferencia, SNR=',num2str(SNR4)])

clear all
%% DERIVADA CON INTERPOLACION Y PROMEDIADO
SNR1 = 5; SNR2 = 15; SNR3 = 25; SNR4 = 35;
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\int_prom_no_interf.mat');

valor_real = [-100:10:100];
XMIN = -10;
XMAX = 10;
YMIN = -5;
YMAX =5;

i= 1;
while (i < 22)
   %SNR1
   promedio_dist_SNR1(i) = mean(aux.Distancia_SNR1(i,:)); 
   sigma_dist_SNR1(i) = std(aux.Distancia_SNR1(i,:));
   error_SNR1(i) = valor_real(i) - promedio_dist_SNR1(i);
   %SNR2
   promedio_dist_SNR2(i) = mean(aux.Distancia_SNR2(i,:)); 
   sigma_dist_SNR2(i) = std(aux.Distancia_SNR2(i,:));
   error_SNR2(i) = valor_real(i) - promedio_dist_SNR2(i);
   %SNR3
   promedio_dist_SNR3(i) = mean(aux.Distancia_SNR3(i,:)); 
   sigma_dist_SNR3(i) = std(aux.Distancia_SNR3(i,:));
   error_SNR3(i) = valor_real(i) - promedio_dist_SNR3(i);
   %SNR4
   promedio_dist_SNR4(i) = mean(aux.Distancia_SNR4(i,:)); 
   sigma_dist_SNR4(i) = std(aux.Distancia_SNR4(i,:));
   error_SNR4(i) = valor_real(i) - promedio_dist_SNR4(i); 
   
    i = i+1;
end

indice = [-10:1:10];

% figure
% subplot(311)
% plot(indice,promedio_dist_SNR1,'o')
% hold on
% plot(indice,promedio_dist_SNR2,'+')
% hold on
% plot(indice,promedio_dist_SNR3,'--')
% hold on
% plot(indice,promedio_dist_SNR4,'*')
% title('Interpolación Promedio, Promedio Distancias')
% 
% subplot(312)
% plot(indice,sigma_dist_SNR1,'o')
% hold on
% plot(indice,sigma_dist_SNR2,'+')
% hold on
% plot(indice,sigma_dist_SNR3,'--')
% hold on
% plot(indice,sigma_dist_SNR4,'*')
% title('Interpolación Promedio, STD Distancias')
%  
% subplot(313)
% plot(indice,error_SNR1,'o')
% hold on
% plot(indice,error_SNR2,'+')
% hold on
% plot(indice,error_SNR3,'--')
% hold on
% plot(indice,error_SNR4,'*')
% title('Error')
% %axis([XMIN XMAX YMIN YMAX])
% legend('SNR1','SNR2','SNR3','SNR4')

figure
subplot(411)
errorbar(valor_real,error_SNR1, sigma_dist_SNR1)
title(['Interpolación Promedio, Sin interferencia, SNR=',num2str(SNR1)])

subplot(412)
errorbar(valor_real,error_SNR2, sigma_dist_SNR2)
title(['Interpolación Promedio, Sin interferencia, SNR=',num2str(SNR2)])

subplot(413)
errorbar(valor_real,error_SNR3, sigma_dist_SNR3)
title(['Interpolación Promedio, Sin interferencia, SNR=',num2str(SNR3)])

subplot(414)
errorbar(valor_real,error_SNR4, sigma_dist_SNR4)
title(['Interpolación Promedio, Sin interferencia, SNR=',num2str(SNR4)])


%% para mirar como esta la snr
% figure
% plot(eco_med_1)
% 
% figure
% plot(eco_med_4)
