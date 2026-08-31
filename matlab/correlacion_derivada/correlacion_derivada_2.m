%Realizar la medición del TOF con y sin viento

clear all
close all
clc 

%senal canal sin viento
SNR = 60;
A0 = 10;        %amplitud de la senal
fc = 975e3;     %frecuencia de resonancia del sensor
fs = 40*fc;      %frecuencia de muestreo
m = 1.5;        %indice de modulacion
T = 5e-6;       %ancho del pulso
tau = 50e-6;    %offset en el tiempo
N = 2*2048;       %cantidad de puntos

%filtro analogico cero - polo frecuencia de corte superior 10000

fss = 10*fc;
a = 2*60e3*pi; 
num = [1 0];
den = [1 a];
[numd, dend] = bilinear(num,den,fss);

ecop = gen_eco(A0, fc,fs,m,T,tau,N);     %genera el pulso de referencia
%ecop = awgn(ecop,600);
Ts = 1/fs;
final = (round(max(size(ecop))) - 1);
t = [0:Ts:final*Ts];

%Se obtienen los picos y las localizaciones de la señal reconstruida y
%rectificada

[pks,locs] = findpeaks(abs(ecop));
env_yp = pks;
[env_yp t_p] = resample(env_yp,locs,1,10,1);

%ventana del patron

ini = 1;
%fin = ini + 152;
fin = ini + 500;
maxs = [ini:1:fin];

%Se define el patron

patron = env_yp(1,maxs);
%vent = flattopwin(max(size(patron)));
vent = hamming(max(size(patron)));

%Se deriva el patrón

patron_d = filter(numd,dend,patron);
%patron_d = patron_d.*vent';
d_env_yp = filter(numd,dend,env_yp);
%d_env_yp = d_env_yp.*vent';
xcorr_yp = xcorr(patron_d,d_env_yp);
[Vp TOF1] = max(xcorr_yp);

%%
d = 3e-6;
tau = tau - d;                       %se desplaza en el tiempo 3us
ecos = gen_eco(A0, fc,fs,m,T,tau,N);    %se genera el otro pulso

SNR = 0;
for i=1 : 81
    ecor = awgn(ecos,SNR);
    SNR = SNR + 1;
    [pks,locs] = findpeaks(abs(ecor));
    env_yr = pks;
	[env_yr t_r] = resample(env_yr,locs,1,10,1);
    d_env_yr = filter(numd,dend,env_yr);
%     plot(d_env_yr);
%     pause();
    xcorr_yr = xcorr(patron_d,d_env_yr);
    [Vp TOF2] = max(xcorr_yr);
    TOF(i) = (TOF2-TOF1)*1/fs;
end

x = [0:1:80];
offset = d*ones(81);
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