%Realizar la medición del TOF utilizando la derivada de la envolvente

clear all
close all


%Señal canal sin viento
A0 = 10;        %amplitud de la senal
fc = 1000e3;     %frecuencia de resonancia del sensor
fs = 20e6;      %frecuencia de muestreo
m = 1.5;        %indice de modulacion
T = 5e-6;       %ancho del pulso
tau = 40e-6;     %Ventana temporal
N = 2048;       %cantidad de puntos

eco = gen_eco(A0, fc,fs,m,T,tau,N);     %genera el pulso de referencia

%filtro analogico cero - polo frecuencia de corte superior 60000
fss = 2*fc;     %Doble de la frecuencia de la portadora
a = 2*60e3*pi;  %Ancho de banda del transductor
num = [1 0];
den = [1 a]; % se usa el polo para limitar el ancho de banda de la derivada
%Se digitaliza el filtro para hallar la derivada
[numd, dend] = bilinear(num,den,fss);

Ts = 1/fs;
final = (round(max(size(eco))) - 1);
t = [0:Ts:final*Ts];

%Se obtienen los picos y las localizaciones de la señal reconstruida y
%rectificada

[pks,locs] = findpeaks(abs(eco));
env_yp = pks;
t_p = t(locs);    

ups = 18;
dns = 1;
fu = fss*ups;
Tsu = 1/fu;
env_yp_r = resample(env_yp,ups,dns);
final = (round(max(size(env_yp_r))) - 1);
tu = [0:Tsu:Tsu*final];
%ventana del patron

ini = 1;
fin = ini + 100;
maxs = [ini:1:fin];

%Se define el patron

patron = pks(1,maxs);

%Se deriva el patrón

patron_d = filter(numd,dend,patron);
 


%senal canal con viento a favor

tau = tau - 3e-6;                       %se desplaza en el tiempo 3us
eco1 = gen_eco(A0, fc,fs,m,T,tau,N);    %se genera el otro pulso

eco1 = awgn(eco1,40);                  %agregamos el ruido blanco
                                        %gausiano al 2ndo pulso

%Se obtienen los picos y las localizaciones de la señal reconstruida y
%rectificada

[pks,locs] = findpeaks(abs(eco1));
env_y = pks;
t_s = t(locs);  

%se derivan las envolventes
d_env_yp = filter(numd,dend,env_yp);
d_env_y = filter(numd,dend,env_y);
%  d_env_yp = diff(env_yp);
%  d_env_y = diff(env_y);
%Se calculan los TOFs haciendo la correlación con la derivada del patrón y
%hallando el máximo

xcorr_yp = xcorr(patron_d,d_env_yp);
xcorr_y = xcorr(patron_d,d_env_y);

[Vp TOF1] = max(xcorr_yp);

[V TOF2] = max(xcorr_y);

%[TOF1 TOF2]
[(TOF2-TOF1)*1/fss]

%%

figure(1)
subplot(211)
plot(t_p,env_yp,t_s,env_y)
title('Envolvente')
subplot(212)
plot(t_p,d_env_yp,t_s,d_env_y)
title('Derivada')

figure(2)
plot(xcorr_yp);
hold on
plot(xcorr_y,'r');
title('Correlacion')

figure(3)
stem(patron_d)
title('Derivada del Patron')

figure(4)
plot(t,eco)
hold on
plot(t,eco1,'r')
title('Pulsos generados')

figure(5)
plot(patron)
title('Patron')

%% comparar senales
SNR = -20;
%TOF = 1:12;
for i=1 : 81
    out1 = awgn(eco1,SNR);
    SNR=SNR+1;
    [pks,locs] = findpeaks(abs(out1));
    env_y = pks;
    d_env_y = filter(numd,dend,env_y);
    xcorr_y = xcorr(patron_d,d_env_y);
    %xcorr_y = correlMat(patron_d,7,d_env_y,196);
    [V TOF2] = max(xcorr_y);
    TOF(i) = abs((TOF2-TOF1)*1/fss);
end

x = [-20:1:60];
offset = 3e-6*ones(81);
figure(6)
plot(x,offset,'r','linewidth',1)
hold on
plot(x,TOF,'--gs',...
    'LineWidth',2,...
    'MarkerSize',10,...
    'MarkerEdgeColor','b',...
    'MarkerFaceColor',[0.5,0.5,0.5])

title('Desviacion del TOF')
ylabel('Tiempo')
xlabel('SNR')
%xlim([5 60])
%ylim([0.000001 0.000005])

