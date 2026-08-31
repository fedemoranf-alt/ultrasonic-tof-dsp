%% Algoritmo con la derivada interpolada

close all
clear all

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

aux = load('G:\Mi unidad\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\ecos_digitalizados2.mat');
%aux = load('G:\Mi unidad\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\ecos_digitalizados_no_interf.mat');% ecos sin interferencia

eco = aux.ecos;
temperatura = aux.temperatura;

eco_refe = squeeze(eco(11,1,:));

%% se halla la envolvente utilizando la transformada de hilbert
env_r = abs(hilbert(eco_refe));
env_refe = filter(fir_dem,1,env_r);

figure
plot(eco_refe)
title('Eco y su envolvente, INT')
hold on
plot(env_refe)

%% derivamos al envolvente 
env_refe_d = filter(numd,dend,env_refe);%se deriva la envolvelnte interpolada

%se normaliza la derivada
[max_d, max_i] = max(env_refe_d );
env_refe_d = (1/max_d).*env_refe_d;

%% Elegimos el patron

indice_tiempo = [1:1:1024];
indice_tiempo = Ts.*indice_tiempo;

figure
subplot(311)
plot(indice_tiempo,eco_refe)
title('Echo')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(312)
plot(indice_tiempo,env_refe)
title('Envelope')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(313)
plot(indice_tiempo,env_refe_d)
title('Derivative')
xlabel('Time (ms)')
ylabel('Amplitude')

figure
plot(env_refe_d)
title('Derivada de la envolvente referencia. INT')

disp("Enter para elegir el patron")
pause
%se selecciona cual sera el patron, esto se hace seleccionando una ventana
%temporanl en la curva de la envolventa derivada
[ind val] = ginput(2);

%Se define el patron desde la derivada
patron = env_refe_d(floor(ind(1,1)):floor(ind(2,1)),1);

figure
plot(patron);
title('patron de la derivada')

patron_0 = zeros(floor(ind(1,1)),1);
patron_02 = zeros(1024-1-floor(ind(2,1)),1);
patron_f = [patron_0' patron' patron_02']

figure
subplot(411)
plot(indice_tiempo,eco_refe)
title('Echo')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(412)
plot(indice_tiempo,env_refe)
title('Envelope')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(413)
plot(indice_tiempo,env_refe_d)
title('Derivative')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(414)
plot(indice_tiempo,patron_f)
title('Derivative')
xlabel('Time (ms)')
ylabel('Amplitude')

%% figure
figure
subplot(411)
plot(indice_tiempo,eco_refe)
title('Echo Signal')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(412)
plot(indice_tiempo,env_refe)
title('Signal envelope')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(413)
plot(indice_tiempo,env_refe_d)
title('Envelope derivative')
xlabel('Time (ms)')
ylabel('Amplitude')
subplot(414)
plot(indice_tiempo,patron_f)
title('Correlation template')
xlabel('Time (ms)')
ylabel('Amplitude')
%% hallamos el indice maximo de la correlacion de referencia.
correlacion =  xcorr(env_refe_d ,patron);
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

    %% se obtiene la envolvente del eco medido
    %SNR1
    env_m_1 = abs(hilbert(eco_med_1));
    env_med_1 = filter(fir_dem,1,env_m_1);
   
    %% se deriva la envolvente interpolada del segundo eco
    %SNR1
    env_med_d = filter(numd,dend,env_med_1);

    %% se normaliza la derivada
    %SNR1
    [max_d_1, max_i] = max(env_med_d);
    env_med_d = (1/max_d_1).*env_med_d;

    %% CORRELACION DE LA SENHAL medida (EL 2DO ECO digitalizado)
    %SNR1
    correlacion_1  =  xcorr(env_med_d ,patron);
    [V2_SNR1 TOF2_SNR1] = max( correlacion_1 );

    %% se calcula el tiempo de vuelo y la distancia entre los ecos con las correlaciones realizadas por partes
    %SNR1
    Distancia_SNR1(count_dist,count_med) =(331000 + 610*temperatura(count_dist,count_med))*[(TOF2_SNR1-TOF1)*1/(3*fs)];

    count_med = count_med + 1;
    
    end
    count_dist = count_dist + 1;
    count_med = 1;
end

%% GRAFICAMOS LOS RESULTADOS

valor_real = [-100:10:100];
XMIN = -10;
XMAX = 10;
YMIN = -5;
YMAX =5;

i= 1;
while (i < 22)
   %SNR1
   promedio_dist_SNR1(i) = mean(Distancia_SNR1(i,:)); 
   sigma_dist_SNR1(i) = std(Distancia_SNR1(i,:));
   error_SNR1(i) = valor_real(i) - promedio_dist_SNR1(i);
   
    i = i+1;
end

indice = [-10:1:10];

figure
subplot(311)
plot(indice,promedio_dist_SNR1,'o')
title('Interpolación Promedio, Promedio Distancias')

subplot(312)
plot(indice,sigma_dist_SNR1,'o')
title('Interpolación Promedio, STD Distancias')
 
subplot(313)
plot(indice,error_SNR1,'o')
title('Error')


figure
errorbar(valor_real,error_SNR1, sigma_dist_SNR1)
title(['Interpolación Promedio, Sin interferencia, SNR=',num2str(SNR1)])
