

% ESTIMACION DEL TOF  UTILIZANDO EL METODO AIC (AKAIKE INFORMATION CRITERION)
clear all
close all
aux = load('D:\Google Drive\TESIS FM\Scrips Matlab\psoc_med_dis\medidas_paper\ecos_digitalizados_no_interf.mat');
eco = aux.ecos;
temperatura = aux.temperatura;

eco_refe = squeeze(eco(11,1,:)); % obs: el patron no debe tener ruido

%El AIC de cada punto de la señale se calcula de la siguiente manera:
%AIC(k) = klog(var(s(1, k))) + Nlog(var(s(k+1,N)))
%donde s(1,k) es un vector con el segmento de la señal desde el inicio
%hasta k y s(k+1,N) es el segmento de la señal desde el punto K hasta el
%final de la señal N.

N = 1024; %cantidad de puntos de la señal
k = 1; %punto de segmentacion de la señal, tambien se usa como indice del vector de AIC
for k = 1 : 1 : N
    AIC(k) = k*log(var(eco_refe(1:k))) + N*log(var(eco_refe(k+1:N)));

end 

figure
subplot(211)
plot(eco_refe)
subplot(212)
plot(AIC)

%como encontrar el punto de inflexcion de la AIC para estimar el TOF ?
%se puede hallar derivando ?
%filtro fir paso altos
n = 64;
b = fir1(n, 5000/200000);
% figure
% freqz(b,1)
AIC_f = filtfilt(b,1,AIC(1,2:1000))
%AIC_f = shift(AIC_f,-(n)/2);

% figure
% plot(AIC_f)
 AIC_d  = diff(AIC_f);

figure
plot(AIC_d)
[max_d, max_i] = max(AIC_d(1,200:800));
TOF1 = max_i + 200


