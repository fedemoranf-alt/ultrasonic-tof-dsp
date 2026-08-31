%% medidor de distancia con interpolacion de la envolvente utilizando los ecos digitalizados


%para probar el algoritmo de de medicion en matlab pero con los datos
%digitalizados por el psoc, se utiliza el vector del eco
clear all 
%close all

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

%% fir derivada
b_diff = [-1, 6, -27, 104,0,  -104, 27, -6, 1];

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

aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\ecos_digitalizados2.mat');
eco = aux.ecos;
temperatura = aux.temperatura;

eco_refe = squeeze(eco(11,1,:));

%% se halla la envolvente utilizando la transformada de hilbert
env_r = abs(hilbert(eco_refe));
env_refe = filter(fir_dem,1,env_r);

figure
plot(eco_refe)
title('Eco y su envolvente')
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

figure
subplot(211)
plot(env_refe)
title(' envolvente sin interpolar.')
subplot(212)
plot(env_refe_int)
title(' envolvente interpolada.')

%% derivamos al envolvente 
env_refe_int_d = filter(numd,dend,env_refe_int);%se deriva la envolvelnte interpolada

%suavizado de la derivada
%env_refe_int_d = filter(fir_dem2,1,env_refe_int_d);

%se normaliza la derivada
[max_d, max_i] = max(env_refe_int_d );
env_refe_int_d = (1/max_d).*env_refe_int_d;

%% Elegimos el patron

figure
plot(env_refe_int_d)
title('Derivada de la envolvente referencia.')
%hold on
%plot(env_refe_int_d_2, 'r')

%solo para la presentacion
figure
plot(env_refe_int_d)
hold on
plot(env_refe_int)

disp("Enter para elegir el patron")
pause
%se selecciona cual sera el patron, esto se hace seleccionando una ventana
%temporanl en la curva de la envolventa derivada
[ind val] = ginput(2);

%Se define el patron desde la derivada
patron = env_refe_int_d(1,floor(ind(1,1)):floor(ind(2,1)));
%patron = filter(patron_lp,1,patron_0);
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
    eco_med = squeeze(eco(count_dist,count_med,:));

    %% se obtiene la envolvente del segundo eco generado
    env_m = abs(hilbert(eco_med));
    env_med = filter(fir_dem,1,env_m);

    %% se interpola la envolvente del segundo eco
    %primero agregamos los puntos intermedios en cada muestra
    j = 1;
    for i=1 : N
        env_y1_0(j) = env_med(i);
        env_y1_0(j+1) = env_med(i);
        env_y1_0(j+2) = env_med(i);
        j = j+3;
    end

    env_med_int = filter(lp_interpolador,1,env_y1_0);
    env_med_int = M.*env_med_int;

    %% se deriva la envolvente interpolada del segundo eco
    env_med_int_d = filter(numd,dend,env_med_int);

    %se normaliza la derivada
    [max_d, max_i] = max(env_med_int_d );
    env_med_int_d = (1/max_d).*env_med_int_d;


    %% CORRELACION DE LA SENHAL medida (EL 2DO ECO digitalizado)
    correlacion  =  xcorr(env_med_int_d ,patron);
    [V2 TOF2] = max( correlacion );

    %% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes

    TOF1_v(count_dist,count_med) = TOF1
    TOF2_v(count_dist,count_med) = TOF2
    Distancia(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2-TOF1)*1/(3*fs)]

    count_med = count_med + 1;
    
   
    end
    
    count_dist = count_dist + 1;
    count_med = 1;
    
end

%solo para la presentacion
figure
plot(correlacion)
 %se normaliza la derivada
[max_d, max_i] = max(env_refe_int );
env_refe_int = (1/max_d).*env_refe_int;
%solo para la presentacion
figure
plot(env_refe_int_d)
hold on
plot(env_refe_int)

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
title('DIG INT, Promedio Distancias')
subplot(312)
plot(indice,sigma_dist,'*')
title('DIG INT, STD Distancias')
subplot(313)
plot(indice,error,'*')
title('Error')
axis([XMIN XMAX YMIN YMAX])

