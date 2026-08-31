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

%filtro fir para suavizar la senhal del AIC
n = 64;
b_AIC = fir1(n, 5000/200000);

%% Tomaremos como referencia el eco que esta en la mitad del trayecto medido.
% los ecos se empezaron a digitalizar a una distancia de 20cm entre los
% transductores y finalizo a una distancia de 40cm con intervalos de 1cm
% por lo que nuestra referencia sera el eco tomado en el medio, el eco en
% la posicion del indice 11 del vector de ecos.

%aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\ecos_digitalizados_en_cero.mat'); %para predatos
aux = load('G:\Mi unidad\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\ecos_digitalizados_en_cero.mat'); % para asus

eco = aux.ecos;
temperatura = aux.temperatura;

eco_refe = squeeze(eco(1,1,:)); % obs: el patron no debe tener ruido


%se normaliza el eco
[max_d, max_i] = max(eco_refe);
eco_refe = (1/max_d).*eco_refe;

%% Elegimos la referencia

%El AIC de cada punto de la señale se calcula de la siguiente manera:
%AIC(k) = klog(var(s(1, k))) + Nlog(var(s(k+1,N)))
%donde s(1,k) es un vector con el segmento de la señal desde el inicio
%hasta k y s(k+1,N) es el segmento de la señal desde el punto K hasta el
%final de la señal N.

k = 1; %punto de segmentacion de la señal, tambien se usa como indice del vector de AIC
for k = 1 : 1 : N
    AIC(k) = k*log(var(eco_refe(1:k))) + (N-k-1)*log(var(eco_refe(k+1:N)));

end 

figure
subplot(211)
plot(eco_refe)
xlabel("Samples")
ylabel("Amplitude")
title("Echo Signal")
subplot(212)
plot(AIC)
title("AIC Curve")
ylabel("AIC")
xlabel("k iteration")




%% hallamos el indice del punto de inflexcion del AIC para estimar el TOF
% filtramos el AIC
AIC_f = filtfilt(b_AIC,1,AIC(1,2:1000));
%luego se deriva el AIC 
AIC_d  = diff(AIC_f);
[max_d, max_i] = max(AIC_d(1,200:800));
TOF1 = max_i + 200

%% 

figure
subplot(311)
plot(eco_refe)
xlabel("Samples")
ylabel("Amplitude")
title("Echo Signal")
subplot(312)
plot(AIC)
title("AIC Curve")
ylabel("Amplitude")
xlabel("k iteration")
subplot(313)
plot(AIC_d)
title("Derivative of AIC Curve")
ylabel("AIC")
xlabel("k iteration")
%% iniciamos las mediciones a partir de la referencia tomada

flag = 1;
count_med = 1;
count_dist = 1;


    while(count_med <100)
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
    k = 1; %punto de segmentacion de la señal, tambien se usa como indice del vector de AIC
    for k = 1 : 1 : N
        AIC(k) = k*log(var(eco_med_1(1:k))) + N*log(var(eco_med_1(k+1:N)));
    end 
    % filtramos el AIC
    AIC_f = filtfilt(b_AIC,1,AIC(1,2:1000));
    %luego se deriva el AIC 
    AIC_d  = diff(AIC_f);
    %buscamos el maximo
    [max_d, max_i] = max(AIC_d(1,200:800));
    TOF2_SNR1 = max_i + 200;

    %SNR2
    k = 1; %punto de segmentacion de la señal, tambien se usa como indice del vector de AIC
    for k = 1 : 1 : N
        AIC(k) = k*log(var(eco_med_2(1:k))) + N*log(var(eco_med_2(k+1:N)));
    end 
    % filtramos el AIC
    AIC_f = filtfilt(b_AIC,1,AIC(1,2:1000));
    %luego se deriva el AIC 
    AIC_d  = diff(AIC_f);
    %buscamos el maximo
    [max_d, max_i] = max(AIC_d(1,200:800));
    TOF2_SNR2 = max_i + 200;

    %SNR3
    k = 1; %punto de segmentacion de la señal, tambien se usa como indice del vector de AIC
    for k = 1 : 1 : N
        AIC(k) = k*log(var(eco_med_3(1:k))) + N*log(var(eco_med_3(k+1:N)));
    end 
    % filtramos el AIC
    AIC_f = filtfilt(b_AIC,1,AIC(1,2:1000));
    %luego se deriva el AIC 
    AIC_d  = diff(AIC_f);
    %buscamos el maximo
    [max_d, max_i] = max(AIC_d(1,200:800));
    TOF2_SNR3 = max_i + 200;

    
    %SNR4
    k = 1; %punto de segmentacion de la señal, tambien se usa como indice del vector de AIC
    for k = 1 : 1 : N
        AIC(k) = k*log(var(eco_med_4(1:k))) + (N-k-1)*log(var(eco_med_4(k+1:N)));
    end 
    % filtramos el AIC
    AIC_f = filtfilt(b_AIC,1,AIC(1,2:1000));
    %luego se deriva el AIC 
    AIC_d  = diff(AIC_f);
    %buscamos el maximo
    [max_d, max_i] = max(AIC_d(1,200:800));
    TOF2_SNR4 = max_i + 200;


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


% al finalizar guardamos los valores calculados para graficarlos al final,
% para asi poder hacer clear all y close all para no afectar al
% procesamiento del siguiente algoritmo
save('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\comp_SNR\AIC_en_cero.mat','Distancia_SNR1','Distancia_SNR2','Distancia_SNR3','Distancia_SNR4')


%% Se grafican los resultados

figure
plot(Distancia_SNR4)