%Realizar la medición del TOF con y sin viento

clear all
close all
clc 

A0 = 2.4218;        %amplitud de la senal
fc = 1000e3;     %frecuencia de resonancia del sensor
m = 1.9157;        %indice de modulacion
T = 3e-6;       %ancho del pulso
fs = 20e6;      %frecuencia de muestreo
N = 2048;       %cantidad de puntos
tau1 = 8e-6;     %offset en el tiempo
Ts = 1/fs;  

%filtro analogico cero - polo frecuencia de corte superior 10000

fss = 10*fc;
a = 2*60e3*pi; 
num = [1 0];
den = [1 a];
[numd, dend] = bilinear(num,den,fss);
ecop = gen_eco_1(A0,fc,fs,m,T,tau1,N);     %genera el pulso de referencia
final = round(max(size(ecop)));
t = [0:Ts:(final-1)*Ts];

%Se obtienen los picos y las localizaciones de la señal reconstruida y
%rectificada

[pks,locs] = findpeaks(abs(ecop));
env_yp = pks;
[env_yp, t_p] = resample(env_yp,locs,1,10,1);
t_p = t(t_p);

env_yp = shift(env_yp,ceil(tau1*fs));
% :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
%ventana del patron
ini = tau1*fs;
fin = ini + 120;
maxs = [ini:1:fin];

%Se define el patron
patron = env_yp(1,maxs);
% :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
%Se deriva el patrón y la envolvente
patron_d = filter(numd,dend,patron);
d_env_yp = filter(numd,dend,env_yp);

xcorr_yp = xcorr(patron_d,d_env_yp);
[Vp1, t1] = max(abs(xcorr_yp));

% :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
d = 3e-6;
tau2 = tau1 + d;                           %se desplaza en el tiempo 3us
ecos = gen_eco_l(A0,fc,fs,m,T,tau2,N);    %se genera el otro pulso
%eco2= gen_eco_l(A0,fc,fs,m,T,tau2+3e-6,N);     %genera el pulso de referencia
%ecos = eco1-eco2;
[pks,locs] = findpeaks(abs(ecos));
env_ys = pks;
[env_ys, t_s] = resample(env_ys,locs,1,10,1);
env_ys = shift(env_ys,ceil(tau2*fs));

d_env_ys = filter(numd,dend,env_ys);
xcorr_ys = xcorr(patron_d,d_env_ys);
[Vp t2] = max(abs(xcorr_ys));

dif = (t2-t1)/fs
% :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
%%
SNR = 0;
for i=1:15
    ecor = awgn(ecos,SNR);
    SNR = SNR + 5;
    [pks,locs] = findpeaks(abs(ecor));
    env_yr = pks;
	[env_yr, t_r] = resample(env_yr,locs,1,10,1);
    d_env_yr = shift(filter(numd,dend,env_yr),ceil(tau2*fs));
    xcorr_yr = xcorr(patron_d,d_env_yr);
    [Vp2 t2] = max(abs(xcorr_yr));
    TOF(i) = (t2-t1)/fs;
    %TOF(i) = (t2);
end

[mean(TOF) std(TOF)]*1e6
x = [0:5:70];
offset = dif.*ones(15);
figure(1)
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
%ylim([0 10e-6])
figure(2)
plot(x,TOF-dif,'--gs',...
    'LineWidth',2,...
    'MarkerSize',10,...
    'MarkerEdgeColor','b',...
    'MarkerFaceColor',[0.5,0.5,0.5])

title('Error del TOF')
ylabel('Tiempo')
xlabel('SNR')
ylim([-1.5e-6 1.5e-6])